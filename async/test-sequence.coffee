describe "async", () ->

    ##################################################################################################################
    describe "Sequence", () ->

        beforeEach () ->
            @sequence = new JSUtils.Sequence([], false)

            # basic class that implements the doneable interface and uses async functions
            class Helper
                constructor: (delay = 100) ->
                    @cbs = []
                    @isDone = false
                    @delay = delay
                go: (result) ->
                    window.setTimeout(
                        () =>
                            @isDone = true
                            result?.push @delay
                            @_done()
                        @delay
                    )
                _done: () ->
                    cb() for cb in @cbs
                done: (cb) ->
                    @cbs.push cb
                    if @isDone
                        @_done()
                    return @

            @helperClass = Helper

        it "execute synchronous functions in correct order", (done) ->
            result = []
            @sequence.start [
                {
                    func: () ->
                        result.push "func1"
                }
                {
                    func: () ->
                        result.push "func2"
                }
                [
                    () ->
                        result.push "func3"
                ]
            ]
            @sequence.done () ->
                expect result
                    .toEqual ["func1", "func2", "func3"]
                done()

        it "execute asynchronous in correct order", (done) ->
            result = []
            Helper = @helperClass

            @sequence.start [
                {
                    func: () ->
                        h = new Helper(300)
                        h.go(result)
                        return h
                }
                {
                    func: () ->
                        h = new Helper(100)
                        h.go(result)
                        return h
                }
                [
                    () ->
                        h = new Helper(150)
                        h.go(result)
                        return h
                ]
            ]
            @sequence.done () ->
                expect result
                    .toEqual [300, 100, 150]
                done()

        it "apply different contexts to sequence functions", (done) ->
            result = []
            @sequence.start [
                {
                    func: () ->
                        result.push @
                    scope: window
                }
                {
                    func: () ->
                        result.push @
                    scope: @
                }
            ]
            self = @
            @sequence.done () ->
                expect result[0] is window
                    .toBe true
                expect result[1] is self
                    .toBe true
                done()

        it "access previous results", (done) ->
            @sequence.start [
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
            @sequence.done (lastResult) ->
                expect lastResult
                    .toBe 10
                done()

        it "execute done-callbacks on completion and aftewards", (done) ->
            result = []
            @sequence.start [
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
            @sequence.done (lastResult) =>
                # this implicitely tests the call of the callback when sequence is done
                result.push "first"

                # now check if done still fires when sequence is already done
                @sequence.done () ->
                    result.push "second"

                    expect result
                        .toEqual ["first", "second"]
                    done()

        it "nested sequences (and previous result access)", (done) ->
            result = []
            @sequence.start [
                {
                    func: () ->
                        result.push "func1"
                }
                {
                    func: () ->
                        result.push "func2"
                        return new JSUtils.Sequence([
                            {
                                func: () ->
                                    result.push "func2.1"
                                    return 2
                            }
                            {
                                func: (shouldBeTwo) ->
                                    result.push "func2.2 -> #{shouldBeTwo}"
                                    return shouldBeTwo * 3
                            }
                        ])
                }
                [
                    # NOTE: auto unpack last result from nested sequence
                    (shouldBeSix) ->
                        result.push "func3 -> #{shouldBeSix}"
                ]
            ]
            @sequence.done () ->
                expect result
                    .toEqual ["func1", "func2", "func2.1", "func2.2 -> 2", "func3 -> 6"]
                done()

        it "stopping (no more functions in sequence will be executed, callbacks will fire)", (done) ->
            result = []
            Helper = @helperClass
            h1 = null

            @sequence.start [
                {
                    func: () ->
                        h1 = new Helper(300)
                        h1.go(result)
                        h1.done () =>
                            @sequence.stop()
                        return h1
                    scope: @
                }
                {
                    func: () ->
                        h = new Helper(100)
                        h.go(result)
                        return h
                }
                [
                    () ->
                        h = new Helper(150)
                        h.go(result)
                        return h
                ]
            ]
            @sequence.done () ->
                expect result
                    .toEqual [300]
                done()

        it "interrupting (no more functions in sequence will be executed, callbacks will NOT fire)", (done) ->
            result = []
            Helper = @helperClass
            h1 = null

            @sequence.start [
                {
                    func: () ->
                        h1 = new Helper(300)
                        h1.go(result)
                        h1.done () =>
                            @sequence.interrupt()
                            window.setTimeout(
                                () ->
                                    expect result
                                        .toEqual [300]
                                    done()
                                200
                            )
                        return h1
                    scope: @
                }
                {
                    func: () ->
                        h = new Helper(100)
                        h.go(result)
                        return h
                }
                [
                    () ->
                        h = new Helper(150)
                        h.go(result)
                        return h
                ]
            ]
            @sequence.done () ->
                result.push "should not be in result!"

        it "stopping & interrupting on error", (done) ->
            result = []
            Helper = @helperClass
            self = @

            @sequence.onError(
                (error, sequenceData, index, args...) ->
                    expect result
                        .toEqual [300]
                    expect @ is self
                        .toBe true
                    expect error.message
                        .toBe "Whatever!"
                    expect index
                        .toBe 1
                    # check arguments that were passed to onError(func, scope, params...)
                    expect args[0]
                        .toBe 1
                    expect args[1]
                        .toBe 2
                    done()
                @
                1, 2
            )

            @sequence.start [
                {
                    func: () ->
                        h = new Helper(300)
                        h.go(result)
                        return h
                }
                {
                    func: () ->
                        throw new Error("Whatever!")
                }
                [
                    () ->
                        h = new Helper(150)
                        h.go(result)
                        return h
                ]
            ]

        it "returning a doneable object will also make it accessible in the next function", (done) ->
            result = []
            Helper = @helperClass
            h = null

            @sequence.start [
                {
                    func: () ->
                        h = new Helper(300)
                        h.go()
                        return h
                    scope: @
                }
                {
                    func: (prevH) ->
                        result.push prevH is h
                        return 2
                }
            ]
            @sequence.done () ->
                expect result
                    .toEqual [true]
                done()

        it "use context to pass multiple parameters for next function in sequence", (done) ->
            result = []
            Helper = @helperClass

            @sequence.start [
                {
                    func: () ->
                        h = new Helper(300)
                        h.go()
                        return {
                            done: h
                            context:
                                a: 1
                                b: 2
                        }
                    scope: @
                }
                {
                    func: (b, a) ->
                        result.push [b, a]
                        h = new Helper(100)
                        h.go()
                        return {
                            done: h
                            context: ["a", "b", "c"]
                        }
                }
                [
                    (x, y, z) ->
                        result.push [x, y, z]
                        h = new Helper(150)
                        h.go()
                        return h
                ]
            ]
            @sequence.done () ->
                expect result
                    .toEqual [[2, 1], ["a", "b", "c"]]
                done()

        it "while", (done) ->
            result = []
            @sequence.while(
                () ->
                    result.push "very first"
                () ->
                    expect result
                        .toEqual ["very first", "func1", "func2", "func3"]
                    done()
            )
            @sequence.start [
                {
                    func: () ->
                        result.push "func1"
                }
                {
                    func: () ->
                        result.push "func2"
                }
                [
                    () ->
                        result.push "func3"
                ]
            ]

        it "progress", (done) ->
            result = []
            sequence = @sequence
            # an empty sequence is done
            expect sequence.progress()
                .toBe 1
            sequence.start [
                {
                    func: () ->
                        result.push sequence.progress()
                }
                {
                    func: () ->
                        result.push sequence.progress()
                }
                [
                    () ->
                        result.push sequence.progress()
                ]
            ]
            sequence.done () ->
                result.push sequence.progress()
                expect result
                    .toEqual [
                        0
                        1 / 3
                        2 / 3
                        1
                    ]
                done()

        it "addData", () ->
            @sequence.start()
            expect @sequence.progress()
                .toBe 1
            checkpoints = []
            # auto resume when done
            @sequence.addData([
                {
                    func: () ->
                        checkpoints.push(1)
                        return 1
                }
            ])
            expect checkpoints
                .toEqual [1]
            # don't resume when resume = false
            @sequence.addData([
                {
                    func: () =>
                        checkpoints.push(2)
                        @sequence.interrupt()
                        return 2
                }
                {
                    func: () ->
                        checkpoints.push(3)
                        return 3
                }
            ], false)
            expect checkpoints
                .toEqual [1]
            expect @sequence._isDone
                .toBe false
            # add more data, resume -> it will stop at checkpoint == 2
            @sequence.addData([
                {
                    func: () ->
                        checkpoints.push(4)
                        return 4
                }
            ])
            expect checkpoints
                .toEqual [1, 2]
            expect @sequence._isStopped
                .toBe true
            # should resume also when stopped
            # add more data, resume -> it should be done and not stopped
            @sequence.addData([
                {
                    func: () ->
                        checkpoints.push(5)
                        return 5
                }
            ])
            expect @sequence._isStopped
                .toBe false
            expect @sequence._isDone
                .toBe true

        it "can take plain functions as data", () ->
            checkpoints = []
            @sequence.start([
                () ->
                    checkpoints.push(1)
                    return 1
                () ->
                    checkpoints.push(2)
                    return 2
            ])
            expect checkpoints
                .toEqual [1, 2]
