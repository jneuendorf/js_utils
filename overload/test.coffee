describe "overload", () ->

    ##################################################################################################################
    beforeEach () ->
        class @A
        A = @A
        class @TestClass


    ##################################################################################################################
    it "invalid overload definitions", () ->
        expect(() -> JSUtils.overload()).toThrow()
        expect(() =>
            JSUtils.overload(
                [String, @A]
                [@A, Boolean]
            )
        ).toThrow()
        expect(() =>
            JSUtils.overload(
                [String, @A]
                "What is this?"
                [@A, Boolean]
                () ->
                    return "handled"
            )
        ).toThrow()
        expect(() ->
            JSUtils.overload(
                () ->
                    return "handler only?"
            )
        ).toThrow()

    describe "matchers (single block)", () ->

        ##################################################################################################################
        it "isintanceMatcher", () ->
            f = JSUtils.overload(
                JSUtils.overload.signature([undefined], JSUtils.overload.matchers.isintanceMatcher)
                JSUtils.overload.signature([Object], JSUtils.overload.matchers.isintanceMatcher)
                JSUtils.overload.signature([@A], JSUtils.overload.matchers.isintanceMatcher)
                (arg) ->
                    return arg
            )

            expect f(null)
                .toBe null
            expect f(undefined)
                .toBe undefined
            expect f(false)
                .toBe false
            expect f({})
                .toEqual {}
            expect f([])
                .toEqual []
            expect f(1)
                .toBe 1
            expect f("string")
                .toBe "string"
            a = new @A()
            expect f(a)
                .toBe a

            expect () -> f(new @TestClass())
                .toThrow()

        ##################################################################################################################
        it "nullTypeMatcher", () ->
            f = JSUtils.overload(
                JSUtils.overload.signature([null], JSUtils.overload.matchers.nullTypeMatcher)
                (arg) ->
                    return arg
            )

            expect f(null)
                .toBe null
            expect f(undefined)
                .toBe undefined
            expect () -> f(false)
                .toThrow()
            expect () -> f({})
                .toThrow()
            expect () -> f([])
                .toThrow()
            expect () -> f(1)
                .toThrow()
            expect () -> f("a")
                .toThrow()
            expect () -> f(new @A())
                .toThrow()

        ##################################################################################################################
        it "arrayTypeMatcher", () ->
            f = JSUtils.overload(
                JSUtils.overload.signature([[String]], JSUtils.overload.matchers.arrayTypeMatcher)
                JSUtils.overload.signature([[Number]], JSUtils.overload.matchers.arrayTypeMatcher)
                (arr) ->
                    return arr.reduce (prev, curr) ->
                        return prev + curr
            )

            expect f([1, 2, 3])
                .toBe 6
            expect f(["1", "2", "3"])
                .toBe "123"

            expect () -> f(["1", 2])
                .toThrow()
            expect () -> f(["1", true])
                .toThrow()
            expect () -> f(["1", {}])
                .toThrow()
            expect () -> f(["1", []])
                .toThrow()
            expect () -> f([["1"]])
                .toThrow()

            expect () -> f(null)
                .toThrow()
            expect () -> f(undefined)
                .toThrow()
            expect () -> f(false)
                .toThrow()
            expect () -> f({})
                .toThrow()
            expect () -> f([])
                .toThrow()
            expect () -> f(1)
                .toThrow()
            expect () -> f("a")
                .toThrow()
            expect () -> f(new @A())
                .toThrow()

        ##################################################################################################################
        it "anyTypeMatcher", () ->
            f = JSUtils.overload(
                JSUtils.overload.signature([JSUtils.overload.ANY], JSUtils.overload.matchers.anyTypeMatcher)
                (arg) ->
                    return arg
            )

            expect f(false)
                .toBe false
            expect f({})
                .toEqual {}
            expect f([])
                .toEqual []
            expect f(1)
                .toBe 1
            expect f("string")
                .toBe "string"
            a = new @A()
            expect f(a)
                .toBe a
            expect f(undefined)
                .toBe undefined
            expect f(null)
                .toBe null

    ##################################################################################################################
    it "fallback handler", () ->
        f = JSUtils.overload(
            JSUtils.overload.signature([String], JSUtils.overload.matchers.isintanceMatcher)
            (arg) ->
                return arg
            () ->
                return "fallback"
        )

        expect f("string")
            .toBe "string"

        expect f(false)
            .toBe "fallback"
        expect f({})
            .toBe "fallback"
        expect f([])
            .toBe "fallback"
        expect f(1)
            .toBe "fallback"
        a = new @A()
        expect f(a)
            .toBe "fallback"
        expect f(undefined)
            .toBe "fallback"
        expect f(null)
            .toBe "fallback"

    ##################################################################################################################
    it "simple signatures", () ->
        f = JSUtils.overload(
            [undefined]
            [Object]
            [@A]
            (arg) ->
                return arg
        )

        # this should match the behavior of the `isintanceMatcher`
        expect f(null)
            .toBe null
        expect f(undefined)
            .toBe undefined
        expect f(false)
            .toBe false
        expect f({})
            .toEqual {}
        expect f([])
            .toEqual []
        expect f(1)
            .toBe 1
        expect f("string")
            .toBe "string"
        a = new @A()
        expect f(a)
            .toBe a

        expect () -> f(new @TestClass())
            .toThrow()

    ##################################################################################################################
    describe "realistic use cases (multiple, blocks, multiple matchers)", () ->

        it "getter/setter", () ->
            obj = {}
            obj.attr = JSUtils.overload(
                [String]
                (key) ->
                    return @[key]

                JSUtils.overload.signature(
                    [String, JSUtils.overload.ANY]
                    JSUtils.overload.matchers.isintanceMatcher
                    JSUtils.overload.matchers.anyTypeMatcher
                )
                (key, value) ->
                    @[key] = value
                    return @
            )

            # before value was set
            expect obj.attr("a")
                .toBe undefined
            # setting values for "a"
            obj.attr("a", "a")
            expect obj.attr("a")
                .toBe "a"
            obj.attr("a", 1)
            expect obj.attr("a")
                .toBe 1
            obj.attr("a", null)
            expect obj.attr("a")
                .toBe null
            obj.attr("a", undefined)
            expect obj.attr("a")
                .toBe undefined
            obj.attr("a", [])
            expect obj.attr("a")
                .toEqual []
            obj.attr("a", {})
            expect obj.attr("a")
                .toEqual {}

            expect () -> obj.attr(1)
                .toThrow()
            expect () -> obj.attr([], {})
                .toThrow()


            # f = JSUtils.overload(
            #     [Number, String]
            #     (a, b) ->
            #         return a + parseInt(b, 10)
            #
            #     [String, Number]
            #     (a, b) ->
            #         return parseInt(a, 10) + b
            #
            #       [Boolean, String]   # \
            #       [String, Boolean]   # |
            #       [String, Number]    # |>  block
            #       (x, y) ->           # |   (handler)
            #           return x + y    # /
            # )
