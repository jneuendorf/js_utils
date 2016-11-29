# A class that executes functions in order.
# It waits for each function to finish before going to the next.
# The cool thing is that the function can be both: synchronous or asynchronous.
# Each asynchronous function MUST return an object that implements a `done()` method in order to be waited on.
# This is due to jQuery's done().
# This `done()` method takes one callback function as parameter (not like jQuery which can take multiple and arrays)!
# If parameters are to be passed to the callback, take care of it yourself (closuring).
#
# @example Sample structure
#   seq = new Sequence([
#       {
#           func: () ->
#               return true
#           scope: someObject
#           params: [1,2,3]
#       }
#       {
#           func: () ->
#               return new JSUtils.Sequence(...)
#           scope: someObject
#           params: (prevRes, presFunc, prevParams, idx) ->
#               return [...]
#       }
#       [
#           () -> return true,
#           someObject,
#           [1,2,3]
#       ]
#   ])
class JSUtils.Sequence

    @PARAM_MODES =
        CONTEXT: "CONTEXT"
        IMPLICIT: "IMPLICIT"
        EXPLICIT: "EXPLICIT"

    # This method does the same as `window.setTimeout()` but makes it useable by {JSUtils.Sequence}.
    # Basically `window.setTimeout()` is used in order to delay a whole Sequence.
    # @param func [Function] The function to execute.
    # @param delay [Integer] Delay in ms.
    # @param scope [Object] Optional. The context for the `func` parameter (-> `this` within `func`).
    # @param params [Array] Optional. Arguments for the `func` parameter.
    # @return [JSUtils.Sequence] A sequence (so `done()` can be called on it).
    @setTimeout: (func, delay, scope, params) ->
        seq = new @([
            func: func
            scope: scope
            params: params
        ], false)
        window.setTimeout(
            () ->
                seq.start()
            delay
        )
        # return empty sequence in order to attach a done() callback to it which will be triggered when seq.start() finishes
        return seq


    ################################################################################################
    # CONSTRUCTOR

    # @param data [Array of Object]
    #   Each element of `data` is either an object like `{.func, .scope, .params}` or an array with the same values (see the example).
    #   Each element looks like:
    #   `func` (or the 1st array element) is the function being executed.
    #   `scope` (or the 2nd element) is an object that serves as `this` in 'func'.
    #   `params` (or the 3rd element) is an array of parameters being passed to 'func'.
    # @param start [Boolean] Optional. Whether to start the sequence immediately.
    # @param stopOnError [Boolean] Optional. Whether an error within a sequence item will cause the sequence to stop executing any more items.
    # @return [JSUtils.Sequence] A new instance of `JSUtils.Sequence`
    constructor: (data, start = true, stopOnError = true) ->
        @_setData(data)
        @idx = 0
        @stopOnError = stopOnError
        @_doneCallbacks = []
        @_startCallback = null
        @_endCallback = null
        @_errorCallback = null
        @_isDone = false
        @_isStopped = false

        # indicates what param mode was chosen in the previous function:
        # - defined params attribute        -> EXPLICIT
        # - context in return value         -> CONTEXT
        # OR
        # - nothing (= take prev result))   -> IMPLICIT
        # NOTE: default is explicit because first function in sequence has no predecessor
        @_parameterMode = @constructor.PARAM_MODES.EXPLICIT

        if start is true
            @start()

    # This methods adds more data to the already existing.
    # This is useful when using `start=false` in the constructor.
    # If the sequence was already done or stopped before it will be resumed unless the `resume` parameter is false
    # @param data [Array] The data to add.
    # @return [JSUtils.Sequence] This instance.
    # @todo This requires `resume()` to be implemented correctly.
    addData: (data, resume = true) ->
        @_setData(@data.concat(data))
        @_isDone = false
        if resume
            @resume()
        return @

    # This method starts the Sequence in case it has been created with `false` as constructor parameter.
    # @param newData [Array] Optional. If an array is given it will replace the possibly previously set data.
    # @return [JSUtils.Sequence] This instance.
    start: (newData) ->
        if newData?
            @_setData(newData)
        @_startCallback?()
        @_invokeNextFunction()
        return @

    # This method stops the sequence from executing any more functions.
    # @param execCallbacks [Boolean] Optional. Whether to execute previously added callbacks.
    # @return [JSUtils.Sequence] This instance.
    stop: (execCallbacks = true) ->
        @_isStopped = true
        if execCallbacks
            @_endCallback?()
            @_execDoneCallbacks()
        return @

    # This method stops the sequence from executing any more functions.
    # Differently than `stop()` callbacks won't be executed.
    # @return [JSUtils.Sequence] This instance.
    interrupt: () ->
        return @stop(false)

    # This method resumes the sequence.
    # @return [JSUtils.Sequence] This instance.
    # @todo this probably won't work...
    resume: () ->
        @_isStopped = false
        # TODO: pass correct params here (prev res....)
        @_invokeNextFunction()
        return @

    # Set the callback that is executed before the sequence starts.
    # @param callback [Function] The callback.
    # @param context [Object] Optional. The context for the callback.
    # @param args... [mixed] Optional. The arguments for the callback.
    # @return [JSUtils.Sequence] This instance.
    onStart: (callback, context, args...) ->
        if typeof callback is "function"
            @_startCallback = () ->
                return callback.apply(context, args)
        return @

    # Set the callback that is executed after the sequence is done (but before the done callbacks are triggered).
    # @param callback [Function] The callback.
    # @param context [Object] Optional. The context for the callback.
    # @param args... [mixed] Optional. The arguments for the callback.
    # @return [JSUtils.Sequence] This instance.
    onEnd: (callback, context, args...) ->
        if typeof callback is "function"
            @_endCallback = () ->
                return callback.apply(context, args)
        return @

    # Callback that gets called in case an error occurs while a sequence item is being executed.
    # @param callback [Function] The callback.
    # @param context [Object] Optional. The context for the callback.
    # @param args... [mixed] Optional. The arguments for the callback.
    # @return [JSUtils.Sequence] This instance.
    onError: (callback, context, args...) ->
        if typeof callback is "function"
            @_errorCallback = (error, data, index) ->
                return callback.apply(context, [error, data, index].concat(args))
        return @

    # This method adds a callback that will be executed after all sequence items are done (but after the `endCallback`).
    # If the sequence is already done the callback will be executed right away.
    # In addition of the optional `args` that are passed to the callback the result of the previous sequence item will be passed as well.
    # So the previous return value is accessible by the last argument of the callback's arguments.
    # @param callback [Function] The callback.
    # @param context [Object] Optional. The context for the callback.
    # @param args... [mixed] Optional. The arguments for the callback.
    # @return [JSUtils.Sequence] This instance.
    done: (callback, context, args...) ->
        if typeof callback is "function"
            self = @
            # not done => push to queue
            if not @_isDone
                @_doneCallbacks.push () ->
                    return callback.apply(context, args.concat([self.lastResult]))
            # done => execute immediately
            else
                callback.apply(context, args.concat([self.lastResult]))
        return @

    then: @::done

    # This method returns the progress of the sequence in [0,1].
    # @return [Number] progress
    progress: () ->
        if @data.length > 0
            return @idx / @data.length
        return 1

    # This method is a shortcut for calling `onStart()` (see {JSUtils.Sequence#onStart}) and `onEnd()` (see {JSUtils.Sequence#onEnd}).
    # @param startFunc [Function] The callback to be executed before the sequence starts.
    # @param endFunc [Function] The callback to be executed after the sequence is done.
    # @param context [Object] Optional. The context for the callback.
    # @param args... [mixed] Optional. The arguments for the callback.
    # @return [JSUtils.Sequence] This instance.
    while: (startFunc, endFunc, context, args...) ->
        @onStart(startFunc, context, args...)
        @onEnd(endFunc, context, args...)
        return @

    # This method is used from other methods to update the data of the sequence.
    # It also takes care of wrapping functions in the object that's expected in `_invokeNextFunction()`.
    # @todo This reiterates items that have been added in case this method is called from addData().
    _setData: (data) ->
        if data instanceof Array
            for item, i in data when item instanceof Function
                data[i] = {
                    func: item
                }
            @data = data
            return @
        throw new Error("JSUtils.Sequence::_setData: Data has to be an array.")

    # This method creates a list or arguments for a function from an object or an array.
    # @private
    # @param func [Function] The function to read the signature from.
    # @param context [Object|Array] Keyword arguments or arguments.
    # @return [Array] The arguments.
    _createParamListFromContext: (func, context) ->
        if context not instanceof Array
            paramList = func.toString()
                .split(/[()]/g)[1]
                .split(/\s*,\s*/g)
            temp = []
            for argName in paramList
                temp.push context[argName]
            return temp
        return context.slice(0)

    # This method invokes the next function in the list.
    # @private
    # @param previousReult [mixed] The result the previously executed function returned or `null`.
    # @param args... [mixed] These are the arguments passed to the callback itself.
    # @return [JSUtils.Sequence] This instance.
    _invokeNextFunction: (args...) ->
        if @_isStopped
            return @

        data = @data[@idx]
        # there is data (data = next function in the list) => do stuff
        if data?
            func = data.func or data[0]
            scope = data.scope or data[1]
            params = data.params or data[2]

            if func?
                CLASS = @constructor
                self = @

                # valid params are given explicitly => override param mode
                if params instanceof Array and params.length > 0
                    @_parameterMode = CLASS.PARAM_MODES.EXPLICIT

                # console.log "sequence param mode = ", @_parameterMode

                if @_parameterMode is CLASS.PARAM_MODES.CONTEXT
                    newParams = @_createParamListFromContext(func, args[0].context)
                else if @_parameterMode is CLASS.PARAM_MODES.EXPLICIT
                    newParams = params
                else if @_parameterMode is CLASS.PARAM_MODES.IMPLICIT
                    newParams = args

                # config function given as params
                if params instanceof Function
                    d = @data[@idx - 1]
                    newParams = params(
                        args
                        {
                            func: d?.func or d?[0]
                            scope: d?.scope or d?[1] or null
                            params: d?.params?.slice(0) or d?[2]?.slice(0) or []
                        }
                        @idx
                    )

                try
                    res = func.apply(scope or window, newParams)
                catch error
                    res = null
                    if @_errorCallback not instanceof Function
                        console.error "================================================================="
                        console.error "JSUtils.Sequence::_invokeNextFunction: Given function (at index #{@idx}) threw an Error!"
                        console.warn "Here is the data:", data
                        console.warn "Here is the error:", error
                        console.error "================================================================="
                    else
                        @_errorCallback(error, data, @idx)

                    if @stopOnError
                        @interrupt()

                # ASYNC
                # return value is of type 'CONTEXT': {done: $.post(...), context: {a: 10, b: 20}}
                if res?.done? and res?.context?
                    res.done.done () ->
                        self.idx++
                        self._parameterMode = CLASS.PARAM_MODES.CONTEXT
                        # skip previous result because it should not be of interest (use context if needed)
                        # context property is retrieved in above mode check (if @_parameterMode is CLASS.PARAM_MODES.CONTEXT)
                        self._invokeNextFunction(res)
                # return value is of type ''
                else if res?.done?
                    # the good thing is the done we're adding right here will be called after all previous done methods.
                    res.done () ->
                        self.idx++
                        self._parameterMode = CLASS.PARAM_MODES.IMPLICIT
                        # use callback arguments because it should not be of interest (use context if needed)
                        self._invokeNextFunction(arguments..., res)
                # SYNC
                # only context => synchronous function => nothing to wait for
                else if res?.context
                    @idx++
                    @_parameterMode = CLASS.PARAM_MODES.CONTEXT
                    @_invokeNextFunction(res)
                # no done() and no context => synchronous function => nothing to wait for
                else
                    @idx++
                    @_parameterMode = CLASS.PARAM_MODES.IMPLICIT
                    @_invokeNextFunction(res)
        # no data => we're done doing stuff
        else
            @lastResult = args[0]
            if @_parameterMode is @constructor.PARAM_MODES.CONTEXT
                @lastResult = @lastResult.context
            @_endCallback?()
            @_execDoneCallbacks()
        return @

    # This method is called when the Sequence has executed all of its functions.
    # It will then start executing all callbacks that previously have been added via `done()` (in the order they were added).
    # No callback receives any parameters.
    # @private
    # @return [JSUtils.Sequence] This instance.
    _execDoneCallbacks: () ->
        @_isDone = true
        cb() for cb in @_doneCallbacks
        return @
