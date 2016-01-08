###*
* A class that starts executing asynchronous functions and waits for them to finish.
*
* @example
* `var barrier = new Barrier([
*     {
*      func: () ->
*          return true
*      scope: someObject
*      params: [1,2,3]
*     }
*     {
*      func: () ->
*          return new JSUtils.Sequence(...)
*      scope: someObject
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
* @class Barrier
* @extends Object
* @constructor
* @param data {Array}
* Each element of that array is either an object like `{func: ..., scope: ..., params: ...}` and an array with the same values in that order.
* For each element applies:
* 'func' (or the 1st array element) is the function being executed.
* 'scope' (or the 2nd element) is an object that serves as `this` in 'func'.
* 'params' (or the 3rd element) is an array of parameters being passed to 'func'
* or a function that creates such an array. In that case that function must have the form:
* @param start {Boolean}
* Optional. Default is `true`. If it's `!== true` the Sequence will not start automatically. The `start()` method can be used to start it whenever.
*###
class JSUtils.Barrier

    # callback is called on every element of the given array. its result is returned (and therefore accessible in Barrier::funcResults when done)
    @forArray: (array = [], callback, start = true) ->
        data = []
        for elem, index in array
            data.push {
                func: do (elem, index) ->
                    return () ->
                        return callback(elem, index)
            }
        return new JSUtils.Barrier(data, start)

    ################################################################################################
    # CONSTRUCTOR
    constructor: (data = [], start = true) ->
        @data               = data
        @remainingThreads   = data.length
        @funcResults        = []
        @_doneCallbacks     = []
        @_startCallback     = null
        @_endCallback       = null
        @_endAllCallback    = null

        @_isDone = false
        @_isStopped = false
        @_sequences = []

        if start is true
            @start()

    ###*
    * This method starts the Barrier in case it has been created with `false` as start parameter.
    * @method start
    * @param newData {Array}
    * Optional. If an array is given it will replace the possibly previously set data.
    * @return This istance. {Barrier}
    * @chainable
    *###
    start: (newData) ->
        if newData instanceof Array
            @data = newData
            @remainingThreads = newData.length

        @_startCallback?()

        if @remainingThreads > 0
            for d, idx in @data when d?
                @_invokeNextFunction(d, idx)
        else
            @_funcDone()

        return @

    ###*
    * This method invokes the next function in the list.
    * @protected
    * @method _invokeNextFunction
    * @param data {Object|Array}
    * Function data (same structure as in JSUtils.Sequence)
    * @return This istance. {Barrier}
    * @chainable
    *###
    _invokeNextFunction: (data, idx) ->
        func = data.func or data[0]
        scope = data.scope or data[1]
        params = data.params or data[2]
        # create wrapper that notifies the barrier that the function is done
        @_sequences.push new JSUtils.Sequence([
            {
                func: () ->
                    try
                        return func.apply(scope, params)
                    catch error
                        return error
            }
            {
                func: (prevResOrResponse) ->
                    # save previous result (or 1st callback param if prev func was async)
                    @funcResults[idx] = prevResOrResponse
                    @_funcDone()
                    return @
                scope: @
            }
        ])
        return @

    _funcDone: () ->
        # console.log "barrier: decrementing remainingThreads from #{@remainingThreads} to #{@remainingThreads - 1}"
        if --@remainingThreads <= 0 # no problem here because JS is not multi-threaded
            @_isDone = true
            @_endCallback?()
            @_execDoneCallbacks()
            @_endAllCallback?()
        return @

    ###*
    * This method adds a callback that will be executed after all functions have returned.
    * @method done
    * @param callback {Function}
    * A function (without parameters).
    * @param context {Object}
    * @param args... {Function}
    * Arguments to be passed to the callback function.
    * @return This istance. {Barrier}
    * @chainable
    *###
    done: (callback, context, args...) ->
        if typeof callback is "function"
            self = @
            # not done => push to queue
            if not @_isDone
                @_doneCallbacks.push () ->
                    return callback.apply(context, args.concat([self.funcResults]))
            # done => execute immediately
            else
                callback.apply(context, args.concat([self.funcResults]))
        return @

    then: @::done

    ###*
    * This method returns the progress (how many async function have already reached the Barrier) in [0,1].
    * @method progress
    * @return progress {Number}
    *###
    progress: () ->
        return 1 - @remainingThreads / @data.length

    ###*
    * This method is called when the Sequence has executed all of its functions. It will then start executing all callbacks that previously have been added via `done()` (in the order they were added). No callback receives any parameters.
    * @protected
    * @method _execDoneCallbacks
    * @return This istance. {Barrier}
    * @chainable
    *###
    _execDoneCallbacks: () ->
        do cb for cb in @_doneCallbacks
        return @

    ###*
    * This method sets the start and end callback that are executed before the Barrier starts and after it's done (but before the done callbacks are being executed).
    * @protected
    * @method while
    * @return This istance. {Barrier}
    * @chainable
    *###
    while: (startCallback, endCallback, context) ->
        if context?
            @_startCallback = () ->
                return context.startCallback()
            @_endCallback = () ->
                return context.endCallback()
        else
            @_startCallback = startCallback
            @_endCallback   = endCallback

        return @
