# Abstract super class of `Sequence` and `Barrier`
class JSUtils.AsyncBase

    # @param data [Array<Objects>,Array<Arrays>]
    #   Each element of `data` is either an object like `{.func, .scope, .params}` or an array with the same values (see the example).
    #   Each element looks like:
    #   `func` (or the 1st array element) is the function being executed.
    #   `scope` (or the 2nd element) is an object that serves as `this` in 'func'.
    #   `params` (or the 3rd element) is an array of parameters being passed to 'func'.
    # @return [JSUtils.AsyncBase] A new instance of `JSUtils.AsyncBase`
    constructor: (data) ->
        @_setData(data)
        @_doneCallbacks = []
        @_startCallback = null
        @_endCallback = null
        @_errorCallback = null
        @_isDone = false
        @_isStopped = false

    # This method starts execution.
    # @param data [Array] Optional. If an array is given it will replace the possibly previously set data.
    # @return [JSUtils.AsyncBase] This instance.
    start: (data) ->
        if data?
            @_setData(data)
        @_startCallback?()
        return @

    # This method stops execution.
    # @param execCallbacks [Boolean] Optional. Whether to execute previously added callbacks.
    # @return [JSUtils.AsyncBase] This instance.
    stop: (execCallbacks = true) ->
        @_isStopped = true
        if execCallbacks
            @_endCallback?()
            @_execDoneCallbacks()
        return @

    # This method stops execution but no callbacks will be called.
    # Differently than `stop()` callbacks won't be executed.
    # @return [JSUtils.AsyncBase] This instance.
    interrupt: () ->
        return @stop(false)

    # This method resumes execution.
    # @return [JSUtils.AsyncBase] This instance.
    resume: () ->
        @_isStopped = false
        return @

    # Returns the result when this instance is done.
    # @abstract
    result: () ->

    # This method returns the progress in [0,1].
    # @return [Number] progress
    progress: () ->
        if @data.length is 0
            return 1
        return NaN

    # This method adds a callback that will be executed after execution has finished (but after the `endCallback`).
    # If this method is called when this instance is already done the callback will be executed right away.
    # The result will be passed to the callback.
    # @param callback [Function] The callback.
    # @return [JSUtils.AsyncBase] This instance.
    done: (callback) ->
        # not done => push to queue
        if not @_isDone
            @_doneCallbacks.push () =>
                return callback(@result())
        # done => execute immediately
        else
            callback(@result())
        return @

    # Set the callback that is executed before execution starts.
    # @param callback [Function] The callback.
    # @return [JSUtils.AsyncBase] This instance.
    onStart: (callback) ->
        @_startCallback = callback
        return @

    # Set the callback that is executed after execution is done (but before the done callbacks are triggered).
    # @param callback [Function] The callback.
    # @return [JSUtils.AsyncBase] This instance.
    onEnd: (callback) ->
        @_endCallback = callback
        return @

    # Callback that gets called in case an error occurs while execution.
    # The callback receives the error, the item's data and the item's index in the sequence.
    # @param callback [Function] The callback.
    # @return [JSUtils.AsyncBase] This instance.
    onError: (callback) ->
        @_errorCallback = callback
        return @

    # This method is a shortcut for calling `onStart()` (see {JSUtils.AsyncBase#onStart}) and `onEnd()` (see {JSUtils.AsyncBase#onEnd}).
    # @param startFunc [Function] The callback to be executed before the sequence starts.
    # @param endFunc [Function] The callback to be executed after the sequence is done.
    # @return [JSUtils.AsyncBase] This instance.
    while: (startFunc, endFunc) ->
        @onStart(startFunc)
        @onEnd(endFunc)
        return @

    # This method is used from other methods to update the data of the sequence.
    # It also takes care of wrapping functions in the object that's expected in `_invokeNextFunction()`.
    # @private
    # @return [JSUtils.AsyncBase] This instance.
    # @throw Data has to be an array.
    # @todo This reiterates items that have been added in case this method is called from addData().
    _setData: (data) ->
        if data instanceof Array
            for item, i in data when item instanceof Function
                # use array instead of object as wrapper for performance reasons
                data[i] = [item]
            @data = data
            return @
        throw new Error("JSUtils.#{@constructor.name}::_setData: Data has to be an array.")

    # This method is called when execution has finished.
    # It will then start executing all callbacks that previously have been added via `done()` (in the order they were added).
    # Each callback receives the result of this instance as a parameter.
    # @private
    # @return [JSUtils.AsyncBase] This instance.
    _execDoneCallbacks: () ->
        @_isDone = true
        result = @result()
        cb(result) for cb in @_doneCallbacks
        return @
