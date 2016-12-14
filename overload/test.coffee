describe "overload", () ->

    ##################################################################################################################
    beforeEach () ->
        class @A
            a: () ->
                return 1337
        A = @A

        class @TestClass
            method1: JSUtils.overload(
                []
                [undefined, Object]
                [Object, undefined]
                () ->
                    return null

                [Number, String]
                (a, b) ->
                    return a + parseInt(b, 10)

                [String, Number]
                (a, b) ->
                    return parseInt(a, 10) + b

                [Boolean, String]
                [String, Boolean]
                (x, y) ->
                    return x + y

                [A, String]
                (a, b) ->
                    return a.a() + parseInt(b, 10)
            )

            method2: JSUtils.overload(
                [Number, String]
                (n, str) ->
                    return "#{n}-#{str}"
                [Number, String, String]
                (n, str1, str2) ->
                    return "#{n}-#{str1}+#{str2}"

            )


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
            # expect () -> f(undefined)
            #     .toThrow()
            # expect () -> f(null)
            #     .toThrow()

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
