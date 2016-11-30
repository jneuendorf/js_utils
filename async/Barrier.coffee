# A class that starts executing functions - called "threads" - (pretty much) simultaneously and is done iff. all threads are done.
# Each function can be both: synchronous or asynchronous.
# Each asynchronous function MUST return an object that implements a `done()` method in order to be waited on.
# This is due to jQuery's done().
# This `done()` method takes one callback function as parameter (not like jQuery which can take multiple and arrays)!
# If parameters are to be passed to the callback, take care of it yourself (closuring).
#
# @example
#   barrier = new Barrier([
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
#       [
#           () -> return true,
#           someObject,
#           [1,2,3]
#       ]
#   ])
class JSUtils.Barrier extends JSUtils.AsyncBase

    # This method can be used to define multiple "threads" doing the same thing with different data (which is based on the array).
    # That means the callback is called on every element of the given array.
    # Its result is accessible in the callback to `done()` (see {JSUtils.Barrier#done}).
    # @param array [Array] The array will be used to construct the data for the barrier.
    # @param callback [Function] The function `(element, index) ->` that will be called on each array element.
    # @param start [Boolean] Optional. Whether to start the barrier immediately.
    # @return [JSUtils.Barrier] The barrier.
    # @example
    #   urls = ["localhost/books.json", "localhost/authors/2"]
    #   barrier = JSUtils.Barrier
    #       .forArray urls, (url, index) ->
    #           return $.get(url)
    #       .done () ->
    @forArray: (array, callback, start = true) ->
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

    # @param data [Array of Object]
    #   Each element of `data` is either an object like `{.func, .scope, .params}` or an array with the same values (see the example).
    #   Each element looks like:
    #   `func` (or the 1st array element) is the function being executed.
    #   `scope` (or the 2nd element) is an object that serves as `this` in 'func'.
    #   `params` (or the 3rd element) is an array of parameters being passed to 'func'.
    # @param start [Boolean] Optional. Whether to start the barrier immediately.
    # @return [JSUtils.Barrier] An instance of `JSUtils.Barrier`
    constructor: (data, start = true) ->
        super(data)
        @remainingThreads = data.length
        @funcResults = []
        @_sequences = []
        if start is true
            @start()

    # This method starts the Barrier in case it has been created with `false` as constructor parameter.
    # @param data [Array] Optional. If an array is given it will replace the possibly previously set data.
    # @return [JSUtils.Barrier] This instance.
    start: (data) ->
        super(data)
        # 'this.data' instead of 'data' because if no data is given no error occurs
        @remainingThreads = @data.length
        if @remainingThreads > 0
            for d, idx in @data when d?
                @_invokeNextFunction(d, idx)
        else
            @_funcDone()
        return @

    # This method stops more "thread" from being started.
    # @param execCallbacks [Boolean] Optional. Whether to execute previously added callbacks.
    # @return [JSUtils.Barrier] This instance.
    stop: (execCallbacks = true) ->
        sequence.stop(execCallbacks) for sequence in @_sequences
        super(execCallbacks)
        return @

    # This method returns the progress (how many async function have already reached the Barrier) in [0,1].
    # @return progress [Number]
    progress: () ->
        return super() or 1 - @remainingThreads / @data.length

    # Returns the result when this barrier (available only if done).
    # @return [Array] A list of results (one for each "thread").
    result: () ->
        return @funcResults

    # This method invokes the next function in the list.
    # @private
    # @param data [Array] Function data (same structure as in the constructor)
    # @return [JSUtils.Barrier] This instance.
    _invokeNextFunction: (data, idx) ->
        if @_isStopped
            return @

        func = data.func or data[0]
        scope = data.scope or data[1]
        params = data.params or data[2]
        # create wrapper that notifies the barrier that the function is done
        @_sequences.push new JSUtils.Sequence([
            {
                func: () =>
                    try
                        return func.apply(scope, params)
                    catch error
                        if @_errorCallback not instanceof Function
                            console.error "JSUtils.Barrier::_invokeNextFunction: Function (at index #{idx}) caused an error!", data
                            throw error
                        else
                            @_errorCallback.call(@, error, data, idx)
            }
            {
                func: (result) =>
                    # save previous result (or 1st callback param if prev func was async)
                    @funcResults[idx] = result
                    @_funcDone()
                    return @
            }
        ])
        return @

    # This method is called when a sequence has completed (-> when a "thread" is done).
    # @private
    _funcDone: () ->
        # console.log "barrier: decrementing remainingThreads from #{@remainingThreads} to #{@remainingThreads - 1}"
        if --@remainingThreads <= 0 # no problem here because JS is not multi-threaded
            @_isDone = true
            @_endCallback?()
            @_execDoneCallbacks()
            @_endAllCallback?()
        return @
