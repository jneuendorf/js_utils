# A class that executes functions in order.
# It waits for each function to finish before going to the next.
# The cool thing is that the function can be both: synchronous or asynchronous.
# Each asynchronous function MUST return an object that implements a `done()` method in order to be waited on.
# This is due to jQuery's done().
# This `done()` method takes one callback function as parameter (not like jQuery which can take multiple and arrays)!
# If parameters are to be passed to the callback, take care of it yourself (closuring).
#
# About the parameter mode:
# The `parameterMode` of a sequence is used internally and
# is used to decide how to process the return value of the previous function.
#   `CONTEXT` means the previous function returned an object with a key `context`.
#   `context` is an object of keyword arguments of an array of arguments for the next function.
#   The object can optionally contain a 'done' key. The according value must return a 'doneable'.
#   The next item will be executed when this 'doneable' is `done()`.
#   `IMPLICIT` means the return value of the previous function will be passed to the current function.
#   This is the case when a 'normal' value or a 'doneable' was returned and
#   the next function does NOT have `params` defined.
#   In case the previous function returned a 'doneable' the next function gets
#   whatever is passed to the `done()` callback of the 'doneable' plus the previous returned value.
#   `EXPLICIT` means the current function has `params` defined.
#
# @example Sample structure
#   seq = new JSUtils.Sequence([
#       {
#           # parameter mode == EXPLICIT
#           func: () ->
#               return true
#           scope: someObject
#           params: [1,2,3]
#       }
#       [
#           # parameter mode == IMPLICIT
#           (bool) ->
#               return true
#           someObject
#       ]
#   ])
class JSUtils.Sequence extends JSUtils.AsyncBase

    # The parameter modes (enum-like).
    # See the class documentation for more details.
    @PARAM_MODES:
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
        seq = new @([{func, scope, params}], false)
        window.setTimeout(
            () ->
                return seq.start()
            delay
        )
        # return empty sequence in order to attach a done() callback to it which will be triggered when seq.start() finishes
        return seq


    ################################################################################################
    # CONSTRUCTOR

    # @param data [Array<Objects>,Array<Arrays>]
    #   Each element of `data` is either an object like `{.func, .scope, .params}` or an array with the same values (see the example).
    #   Each element looks like:
    #   `func` (or the 1st array element) is the function being executed.
    #   `scope` (or the 2nd element) is an object that serves as `this` in 'func'.
    #   `params` (or the 3rd element) is an array of parameters being passed to 'func'.
    # @param start [Boolean] Optional. Whether to start the sequence immediately.
    # @param stopOnError [Boolean] Optional. Whether an error within a sequence item will cause the sequence to stop executing any more items.
    # @return [JSUtils.Sequence] A new instance of `JSUtils.Sequence`
    constructor: (data, start = true, stopOnError = true) ->
        super(data)
        @_setData(data)
        @idx = 0
        @stopOnError = stopOnError
        # indicates what param mode was chosen in the previous function:
        # - defined params attribute -> EXPLICIT
        # - context in return value -> CONTEXT
        # - nothing (= take prev result)) -> IMPLICIT
        # NOTE: default is explicit because first function in sequence has no predecessor thus no special processing
        @parameterMode = @constructor.PARAM_MODES.EXPLICIT
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
    # @param data [Array] Optional. If an array is given it will replace the possibly previously set data.
    # @return [JSUtils.Sequence] This instance.
    start: (data) ->
        super(data)
        @_invokeNextFunction()
        return @

    # This method resumes the sequence.
    # @return [JSUtils.Sequence] This instance.
    # @todo this probably won't work...
    resume: () ->
        super()
        # TODO: pass correct params here (prev res....)
        @_invokeNextFunction()
        return @

    # This method returns the progress of the sequence in [0,1].
    # @return [Number] progress
    progress: () ->
        return super() or @idx / @data.length

    # Returns the result when this sequence (available only if done).
    # @return [mixed] What ever the last function has returned (if it was an object with `context` this `context` is the result).
    result: () ->
        return @lastResult

    # This method creates a list or arguments for a function from an object or an array.
    # @private
    # @param func [Function] The function to read the signature from.
    # @param context [Object,Array] Keyword arguments or arguments.
    # @return [Array] The arguments.
    _createParamListFromContext: (func, context) ->
        # explit check for plain object (thus in case some custom instance it won't be considered)
        if typeof context is 'object' and context.constructor is Object
            paramList = func.toString()
                .split(/[()]/g)[1]
                .split(/\s*,\s*/g)
            params = []
            passContext = false
            for paramName in paramList
                params.push context[paramName]
                if DEBUG and not context[paramName]?
                    passContext = true
            if passContext
                console.warn "JSUtils.Sequence::_createParamListFromContext: Context does not contain enough data for supply all parameters. Falling back to passing the context as it is."
                console.info "func:", func, "context:", context
                return context
            return params
        # arrays and anything other than plain objects are returned untouched
        return context

    # This method invokes the next function in the list.
    # @private
    # @param args... [mixed] These are the arguments passed to the callback itself.
    # @return [JSUtils.Sequence] This instance.
    _invokeNextFunction: (args...) ->
        if @_isStopped
            return @

        data = @data[@idx]
        # there is data (data = next function in the list) => do stuff
        if data?
            func = data.func or data[0]
            if func?
                scope = data.scope or data[1]
                params = data.params or data[2]

                CLASS = @constructor
                self = @

                # valid params are given explicitly => override param mode
                if params instanceof Array and params.length > 0
                    @parameterMode = CLASS.PARAM_MODES.EXPLICIT

                if @parameterMode is CLASS.PARAM_MODES.CONTEXT
                    params = @_createParamListFromContext(func, args[0])
                # else if @parameterMode is CLASS.PARAM_MODES.EXPLICIT
                #     params = params
                else if @parameterMode is CLASS.PARAM_MODES.IMPLICIT
                    params = args

                try
                    res = func.apply(scope or window, params)
                catch error
                    res = null
                    if @_errorCallback not instanceof Function
                        console.error "JSUtils.Sequence::_invokeNextFunction: Function at index #{@idx} caused an error!", data
                        throw error
                    else
                        if @_errorCallback(error, data, @idx) isnt false
                            if @stopOnError
                                @interrupt()
                        else if DEBUG
                            console.info "JSUtils.Sequence::_invokeNextFunction: Execution was stopped because onError callback returned false. The error was '#{error.message}'"

                # ASYNC
                # return value is of type 'CONTEXT': {done: $.post(...), context: {a: 10, b: 20}}
                if res?.done? and res?.context?
                    res.done.done () ->
                        self.idx++
                        self.parameterMode = CLASS.PARAM_MODES.CONTEXT
                        # skip previous result because it should not be of interest (use context if needed)
                        # context property is retrieved in above mode check (if @parameterMode is CLASS.PARAM_MODES.CONTEXT)
                        self._invokeNextFunction(res.context)
                # return value 'doneable'
                # i.e. 'res' may be a sequence use context if res' param mode is CONTEXT
                else if res?.done?
                    res.done () ->
                        self.idx++
                        # use callback arguments because res should not be of much interest (if it is use CONTEXT)
                        if res.parameterMode isnt CLASS.PARAM_MODES.CONTEXT
                            self.parameterMode = CLASS.PARAM_MODES.IMPLICIT
                            return self._invokeNextFunction(arguments..., res)
                        # else: res' parameterMode is CONTEXT => it was a sequence => auto unpack
                        self.parameterMode = CLASS.PARAM_MODES.CONTEXT
                        self._invokeNextFunction(res.result())
                # SYNC
                # only context => synchronous function => nothing to wait for
                else if res?.context
                    @idx++
                    @parameterMode = CLASS.PARAM_MODES.CONTEXT
                    @_invokeNextFunction(res.context)
                # no done() and no context => synchronous function => nothing to wait for
                else
                    @idx++
                    @parameterMode = CLASS.PARAM_MODES.IMPLICIT
                    @_invokeNextFunction(res)
        # no data => we're done doing stuff
        else
            @lastResult = args[0]
            @_endCallback?()
            @_execDoneCallbacks()
        return @
