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

    ##################################################################################################################
    it "constructorMatcher", () ->
        f = JSUtils.overload(
            JSUtils.overload.signature([undefined], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([Boolean], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([Object], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([Array], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([Number], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([String], JSUtils.overload.matchers.constructorMatcher)
            JSUtils.overload.signature([@A], JSUtils.overload.matchers.constructorMatcher)
            (cls) ->
                return cls
        )

        expect f(undefined)
            .toBe undefined
        expect f(null)
            .toBe null
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
            (nullOrUndefined) ->
                return nullOrUndefined
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
    it "func results of overloading", () ->
        testInstance = new @TestClass()
        a = new @A()

        start = performance.now()
        expect testInstance.method1()
            .toBe null
        expect testInstance.method1(null, 23)
            .toBe null
        expect testInstance.method1("adsf", undefined)
            .toBe null

        expect testInstance.method1(10, "20")
            .toBe 30
        expect testInstance.method1("20", 20)
            .toBe 40
        expect testInstance.method1(a, "20")
            .toBe 1357

        expect () -> testInstance.method1(a, a)
            .toThrow()

        expect testInstance.method1(true, "a")
            .toBe "truea"
        expect testInstance.method1("a", true)
            .toBe "atrue"
        console.log "testing took", (performance.now() - start), "ms for 9 calls with 8 signatures each"

        expect testInstance.method2(1, "a")
            .toBe "1-a"
        expect testInstance.method2(1, "a", "b")
            .toBe "1-a+b"

        expect testInstance.method3
            .toBeUndefined()

    ##################################################################################################################
    it "supports subclass checking", () ->
        class Super
        class Sub extends Super

        f = JSUtils.overload(
            [Super]
            () -> true
        )

        expect f(new Super())
            .toBe true
        expect f(new Sub())
            .toBe true
        expect () -> f("asdf")
            .toThrow()

    ##################################################################################################################
    it "signatures created by signature() function", () ->
        f = JSUtils.overload(
            JSUtils.overload.signature(
                [Number, Object],
                JSUtils.overload.matchers.constructorMatcher
            )
            () -> true
        )

        expect f(1, {})
            .toBe true
        # subclass checking should not work
        expect () -> f(1, 2)
            .toThrow()
