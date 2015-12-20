# indentation needed so sequence and barrier are in 1 describe block
    describe "Barrier", () ->

        beforeEach () ->
            @barrier = new JSUtils.Barrier([], false)

            # basic class that implements the doneable interface and uses async functions
            class Helper
                constructor: (delay = 1000) ->
                    @cbs = []
                    @isDone = false
                    @delay = delay
                go: (result) ->
                    window.setTimeout(
                        () =>
                            @isDone = true
                            result?.push @delay
                            @_done()
                        @deplay
                    )
                _done: () ->
                    cb() for cb in @cbs
                done: (cb) ->
                    @cbs.push cb
                    if @isDone
                        @_done()
                    return @

            @helperClass = Helper

        it "execute synchronous functions pseudo-concurrently", (done) ->
            @barrier.start [
                {
                    func: () ->
                        return 2
                }
                {
                    func: () ->
                        return 8
                }
            ]
            @barrier.done (barrierResults) ->
                expect barrierResults
                    .toEqual [2, 8]
                done()


        it "execute asynchronous functions pseudo-concurrently", (done) ->
            result = []
            Helper = @helperClass
            @barrier.start [
                {
                    func: () ->
                        h = new Helper(3000)
                        h.go(result)
                        return h
                }
                {
                    func: () ->
                        h = new Helper(1000)
                        h.go(result)
                        return h
                }
            ]
            @barrier.done (barrierResults) ->
                expect result
                    .toEqual [3000, 1000]
                expect (res instanceof Helper for res in barrierResults)
                    .toEqual [true, true]
                done()


        it "execute done-callbacks on completion and aftewards", (done) ->
            result = []
            @barrier.start [
                {
                    func: () ->
                        return 2
                }
                {
                    func: (a) ->
                        return a + 8
                    scope: @
                }
            ]
            @barrier.done () =>
                # this implicitely tests the call of the callback when barrier is done
                result.push "first"

                # now check if done still fires when barrier is already done
                @barrier.done () ->
                    result.push "second"

                    expect result
                        .toEqual ["first", "second"]
                    done()

        it "set specific barrier's results (using sequences)", (done) ->
            result = []
            @barrier.start [
                {
                    func: () ->
                        return new JSUtils.Sequence([
                            {
                                func: () ->
                                    h = new @helperClass(1000)
                                    h.go(result)
                                    return {
                                        done: h
                                        context:
                                            h: h
                                    }
                                scope: @
                            }
                            {
                                func: (h) ->
                                    return {
                                        a: 2
                                        delay: h.delay
                                    }
                            }
                        ])
                    scope: @
                }
                {
                    func: () ->
                        return new JSUtils.Sequence([
                            {
                                func: () ->
                                    h = new @helperClass(1001)
                                    h.go(result)
                                    return h
                                scope: @
                            }
                            {
                                func: (h) ->
                                    return {
                                        delay: h.delay
                                    }
                            }
                        ])
                    scope: @
                }
            ]
            @barrier.done (barrierResults) ->
                expect barrierResults
                    .toEqual [
                        {
                            a: 2
                            delay: 1000
                        }
                        {
                            delay: 1001
                        }
                    ]
                done()

        it "Barrier.forArray", (done) ->
            barrier = JSUtils.Barrier.forArray [1, 2, 3, 4], (elem) ->
                return elem * elem
            barrier.done (barrierResults) ->
                expect barrierResults
                    .toEqual [1, 4, 9, 16]

                done()
