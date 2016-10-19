# A class that starts executing functions - called "threads" - (pretty much) simultaneously and is done iff. all threads are done.
# Each function can be both: synchronous or asynchronous.
# Each asynchronous function MUST return an object that implements a `done()` method.
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
class JSUtils.Barrier

    # This method can be used to define multiple "threads" doing the same thing with different data (which is based on the array).
    # That means the callback is called on every element of the given array.
    # Its result is accessible in the callback to `done()` (@see {JSUtils.Barrier#done}).
    # @param array [Array] The array will be used to construct the data for the barrier.
    # @param callback [Function] The function `(element, index) ->` that will be called on each array element.
    # @param start [Boolean] Optional. Whether to start the barrier immediately.
    # @return [Barrier] The barrier.
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
    #       'func'   (or the 1st array element) is the function being executed.
    #       'scope'  (or the 2nd element) is an object that serves as `this` in 'func'.
    #       'params' (or the 3rd element) is an array of parameters being passed to 'func'.
    # @param start [Boolean] Optional. Whether to start the barrier immediately.
    # @return [Barrier] An instance of `JSUtils.Barrier`
    constructor: (data, start = true) ->
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

    # This method starts the Barrier in case it has been created with `false` as constructor parameter.
    # @param [Array] newData
    #   Optional. If an array is given it will replace the possibly previously set data.
    # @return [Barrier] This instance.
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

    # This method invokes the next function in the list.
    # @private
    # @param data [Array] Function data (same structure as in the constructor)
    # @return [Barrier] This instance.
    _invokeNextFunction: (data, idx) ->
        if @_isStopped
            return @

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
                        console.error "================================================================="
                        console.error "App.Barrier::_invokeNextFunction: Given function (at index #{idx}) threw an Error!"
                        console.warn "Here is the data:", data
                        console.warn "Here is the error:", error
                        console.error "================================================================="
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

    # This method adds a callback that will be executed after all functions have returned (including the `endCallback`).
    # If the barrier is done already the callback will be executed right away.
    # In addition of the optional `args` that are passed to the callback the results of the barrier will be passed as well.
    # So the callback gets `arg1, ... , argN, resultOfThread1, ... , resultOfThreadM` (if there would be M threads).
    # @param callback [Function] The callback invoked with the following parameters.
    # @param context [Object] Optional. This object serves as context (`this`) for the callback.
    # @param args... [Mixed...] Optional. Arguments to be passed to the callback function.
    # @return [Barrier] This instance.
    done: (callback, context, args...) ->
        if typeof callback is "function"
            # not done => push to queue
            if not @_isDone
                @_doneCallbacks.push () =>
                    return callback.apply(context, args.concat([@funcResults]))
            # done => execute immediately
            else
                callback.apply(context, args.concat([@funcResults]))
        return @

    then: @::done

    # This method returns the progress (how many async function have already reached the Barrier) in [0,1].
    # @return progress [Number]
    progress: () ->
        return 1 - @remainingThreads / @data.length

    # This method is called when the Sequence has executed all of its functions.
    # It will then start executing all callbacks that previously have been added via `done()` (in the order they were added).
    # No callback receives any parameters.
    # @private
    # @return [Barrier] This instance.
    _execDoneCallbacks: () ->
        cb() for cb in @_doneCallbacks
        return @

    # This method sets the start and end callback that are executed before the Barrier starts and after it's done (but before the done callbacks are being executed).
    # @private
    # @param startCallback [Function] The callback being executed before the barrier starts.
    # @param endCallback [Function] The callback being executed after the barrier starts.
    # @param context [Object] Optional. The `this` context for both callbacks.
    # @return [Barrier] This instance.
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

    # This method stops more "thread" from being started.
    # @param execCallbacks [Boolean] Optional. Whether to execute previously added callbacks.
    # @return [Barrier] This instance.
    stop: (execCallbacks = true) ->
        @_isStopped = true
        sequence.stop(execCallbacks) for sequence in @_sequences
        if execCallbacks
            @_endCallback?()
            @_execDoneCallbacks()
        return @

    # This method stops more "thread" from being started.
    # Differently than `stop()` callbacks won't be executed.
    # @return [Barrier] This instance.
    interrupt: () ->
        return @stop(false)

    # This method resumes the barrier meaning more "thread" can be started.
    # @return [Barrier] This instance.
    # @todo this probably won't work...
    resume: () ->
        @_isStopped = false
        # TODO: pass correct params here (prev res....)
        @_invokeNextFunction()
        return @
