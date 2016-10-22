describe "overload", () ->

    ##################################################################################################################
    beforeEach () ->
        class @A
            a: () ->
                return 1337
        A = @A

        class @TestClass

            method1: JSUtils.overload(
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

            try
                @::method3 = JSUtils.overload(
                    [String, A]
                    [A, Boolean]
                )
            catch e
                expect e.message
                    .toBe "No function given for argument lists: [[\"String\",\"A\"],[\"A\",\"Boolean\"]]"

    ##################################################################################################################
    it "func results of overloading", () ->
        testInstance = new @TestClass()
        a = new @A()

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
