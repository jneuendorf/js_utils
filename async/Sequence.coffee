###*
 * A class that executes asynchronous functions in an order.
 *
 * @example
 * `var seq = new Sequence([
 *     {
 *      func: () ->
 *          return true
 *      scope: someObject
 *      params: [1,2,3]
 *     }
 *     {
 *      func: () ->
 *          return new App.Sequence(...)
 *      scope: someObject
 *      params: (prevRes, presFunc, prevParams, idx) ->
 *          return [...]
 *     }
 *     [
 *      () -> return true,
 *      someObject,
 *      [1,2,3]
 *     ]
 * ])`
 *
 * Each asynchronous function MUST return an object that implements a `done()` method!
 *
 * This `done()` method takes 1 callback function as parameter (not like jQuery which can take multiple and arrays)! If parameters are to be passed to the callback, take care of it yourself (closuring?!).
 * When using `done()` callbacks in that asynchronous function those callbacks MUST be synchronous to make sure the order remains correct.
 *
 * @class Sequence
 * @extends Object
 * @constructor
 * @param data {Array}
 * Each element of that array is either an object like `{func: ..., scope: ..., params: ...}` and an array with the same values in that order.
 * For each element applies:
 * 'func' (or the 1st array element) is the function being executed.
 * 'scope' (or the 2nd element) is an object that serves as `this` in 'func'.
 * 'params' (or the 3rd element) is either
 * an array of parameters being passed to 'func'
 * or a function that creates such an array. In that case that function must have the form:
 * `(resultOfPreviouslyExecutedFunction, parametersOfPreviousCallback, previouslyExecutedFunction, scopeOfPreviouslyExecutedFunction, parametersOfPreviouslyExecutedFunction, indexInExecutionList) ->
 *     params = [...do stuff...]
 *     return params`
 * See the example or the static `test()` method for details.
 * @param start {Boolean}
 * Optional. Default is `true`. If it's `!== true` the Sequence will not start automatically. The `start()` method can be used to start it whenever.
*###
class App.Sequence

    @PARAM_MODES =
        CONTEXT:    "CONTEXT"
        IMPLICIT:   "IMPLICIT"
        EXPLICIT:   "EXPLICIT"

    ###*
    * This method does the same as window.setTimeout() but makes it useable by App.Sequence. It also takes an additional (optional) scope parameter.
    * Basically window.setTimeout() is used in order to delay a whole Sequence.
    *
    * The mechanism is lik so:
    * An empty Sequence is created and returned (after it returns the `done()` callback is added by the Sequence itself).
    * The empty Sequence is delayed by 'delay' (with the help of window.setTimeout()) and when before it starts the passed function 'func', 'scope', and all 'params' passed to the Sequence.
    * @static
    * @method setTimeout
    * @param {Function|String} func
    * This parameter is either a function or a code string.
    * @param {Integer} delay
    * @param {Function} scope
    * @param {mixed} param1
    * @param {mixed} param2
    * @param ...
    *###
    # @setTimeout: (func, delay, scope, params...) ->
    #     seq = new @([], false)
    #
    #     window.setTimeout(
    #         () ->
    #             seq.start([
    #                 func: func
    #                 scope: scope
    #                 params: params
    #             ])
    #         delay
    #     )
    #
    #     # return empty sequence in order to attach a done() callback to it which will be triggered when seq.start() finishes
    #     return seq

    ################################################################################################
    # CONSTRUCTOR
    constructor: (data = [], start = true, stopOnError = true) ->
        @data   = data
        @idx    = 0
        @stopOnError = stopOnError
        @_doneCallbacks = []
        @_startCallback = null
        @_endCallback   = null
        @_isDone        = false
        @_isStopped     = false

        # indicates what param mode was chosen in the previous function:
        # - defined params attribute        -> EXPLICIT
        # - context in return value         -> CONTEXT
        # OR
        # - nothing (= take prev result))   -> IMPLICIT
        # NOTE: default is explicit because first function in sequence has no predecessor
        @_parameterMode = @constructor.PARAM_MODES.EXPLICIT

        if start is true
            @start()

    ###*
    * This method starts the Sequence in case it has been created with `false` as start parameter.
    * @method start
    * @param newData {Array}
    * Optional. If an array is given it will replace the possibly previously set data.
    * @return This istance. {Sequence}
    * @chainable
    *###
    start: (newData) ->
        if newData instanceof Array
            @data = newData

        @_startCallback?()

        @_invokeNextFunction()
        return @

    _createParamListFromContext: (func, context) ->
        if context not instanceof Array
            paramList = func.toString()
                .split /[()]/g
                .second
                .split /\s*,\s*/g
            temp = []
            for argName in paramList
                temp.push context[argName]
            return temp
        return context.slice(0)

    ###*
    * This method invokes the next function in the list.
    * @protected
    * @method _invokeNextFunction
    * @param previousReult {mixed}
    * The result the previously executed function returned or `null`.
    * @param args... {mixed}
    * These are the arguments passed to the callback itself.
    * @return This istance. {Sequence}
    * @chainable
    *###
    # _invokeNextFunction: (prevRes, callbackArgs...) ->
    _invokeNextFunction: (args...) ->
        if @_isStopped
            return @

        data = @data[@idx]

        # there is data (data = next function in the list) => do stuff
        if data?
            if data instanceof Array
                func    = data[0]
                scope   = data[1]
                params  = data[2]
            else
                func    = data.func
                scope   = data.scope
                params  = data.params

            if func?
                CLASS   = @constructor
                self    = @

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
                if params instanceof Function #and params.isParameterFunction is true
                    d = @data[@idx - 1]
                    newParams = params(
                        args
                        {
                            func:   d?.func or d?[0]
                            scope:  d?.scope or d?[1] or null
                            params: d?.params?.slice(0) or d?[2]?.slice(0) or []
                        }
                        @idx
                    )

                try
                    res = func.apply(scope or window, newParams)
                catch error
                    res = null
                    console.error "================================================================="
                    console.error "App.Sequence::_invokeNextFunction: Given function (at index #{@idx}) threw an Error!"
                    console.warn "Here is the data:", data
                    console.warn "Here is the error:", error
                    console.error "================================================================="
                    if @stopOnError
                        @interrupt()

                # TODO: enable sequence concatenation: if res is a sequence somehow pass the last result to next function (as if they were defined in 1 sequence)
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
                        self._invokeNextFunction(arguments...)
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

    ###*
    * This method is called when the Sequence has executed all of its functions. It will then start executing all callbacks that previously have been added via `done()` (in the order they were added). No callback receives any parameters.
    * @protected
    * @method _execDoneCallbacks
    * @return This istance. {Sequence}
    * @chainable
    *###
    _execDoneCallbacks: () ->
        @_isDone = true
        cb() for cb in @_doneCallbacks
        return @

    stop: (execCallbacks = true) ->
        @_isStopped = true
        if execCallbacks
            @_endCallback?()
            @_execDoneCallbacks()
        return @

    interrupt: () ->
        return @stop(false)

    resume: () ->
        @_isStopped = false
        # TODO: pass correct params here (prev res....)
        @_invokeNextFunction()
        return @

    ###*
    * Callback that gets called before the queue is being processed.
    * @method onStart
    *###
    onStart: (callback, context, args...) ->
        if typeof callback is "function"
            @_startCallback = () ->
                return callback.apply(context, args)
        return @

    ###*
    * Callback that gets called after the queue is processed but before the done callbacks are triggered.
    * @method onEnd
    *###
    onEnd: (callback, context, args...) ->
        if typeof callback is "function"
            @_endCallback = () ->
                return callback.apply(context, args)
        return @

    ###*
    * This method adds a callback that will be executed after all functions have returned.
    * @method done
    * @param callback {Function}
    * A function (without parameters).
    * @param context {Object}
    * @param args... {Function}
    * Arguments to be passed to the callback function.
    * @return This istance. {Sequence}
    * @chainable
    *###
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

    ###*
    * This method returns the progress of the Sequence in [0,1].
    * @method getProgress
    * @return progress {Number}
    *###
    progress: () ->
        return @idx / @data.length

    ###*
    * @method while
    * @return {Sequence}
    * @chainable
    *###
    while: (startFunc, endFunc, context, args) ->
        @onStart startFunc, context, args
        @onEnd endFunc, context, args
        return @



################################################################################################
# TESTING METHOD
if DEBUG
    App.Sequence.test = () ->
        sequence = new App.Sequence([
            # testing new setTimeout...
            # {
            #     func: () ->
            #         delay = 2000
            #         return App.Sequence.setTimeout(
            #             () ->
            #                 console.log("func0! was timed out by #{delay}")
            #             delay
            #             $
            #         )
            #     scope: window
            #     params: []
            # }
            # make an API call
            {
                func: (id, idx) ->
                    # http://localhost:3000/api/reports?channel=1
                    console.log "func1! idx = #{idx}#{if idx? then " (called again...so actually func2 ^^)" else ""}"
                    # s = Date.now()
                    return @get "http://localhost:3000/api/report/#{id}"
                    # return @get "http://localhost:3000/api/reports?channel=#{id}", (resp) ->
                    #     # console.log "api call took", resp, Date.now() - s, "ms"
                    #     console.log "func1 (id=#{id}) res =", resp
                    #     return true
                scope: $
                params: [12]
            }
            # jquery.get callback
            {
                func: (response) ->
                    console.log "jquery get callback:", response
                    return response
            }
            {
                func: (response) ->
                    console.log "next seq function with prev result:", response
                    return true

            }
            # # do exactly what you did before
            # {
            #     func: (prevRes, prevCallbackParams, prevFunc, prevScope, prevParams, currentIndex) ->
            #         return new App.Sequence([
            #             func: prevFunc
            #             # this has to jQuery as well because func uses the previous function (which is returned by the params function) that actually uses jQuery as `this`
            #             scope: prevScope
            #             params: () ->
            #                 params = prevParams.concat(currentIndex)
            #                 params[0]++
            #                 return params
            #         ])
            #     scope: window
            #     params: (prevRes, prevCallbackParams, prevFunc, prevScope, prevParams, currentIndex) ->
            #         return [prevRes, prevCallbackParams, prevFunc, prevScope, prevParams, currentIndex]
            # }
            # execute a synchronous function using array notation
            # [
            #     () ->
            #         console.log "func3 (synchronous function)!"
            #         return { data: "awesome data" }
            #     null
            #     [42]
            # ]
            # # just something...
            # {
            #     func: (prevRes) ->
            #         console.log "func4 (using previous result)!", "'#{prevRes.data}' and some more chars! :D"
            #         return @
            #     scope: null
            #     params: (prevRes, prevCallbackParams, prevFunc, prevScope, prevParams, currentIndex) ->
            #         return [prevRes]
            # }
        ], false)
        .while(
            loadingIndicator.start
            loadingIndicator.stop
            loadingIndicator
        )
        .start()
