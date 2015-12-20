describe "jOverload", () ->

    ##################################################################################################################
    it "jOverload setup", () ->
        class window.A
            a: () ->
                return 1337

        class window.TestClass

            method1: JSUtils.jOverload(
                {a: Number, b: String}
                (a, b) ->
                    return a + parseInt(b, 10)

                {a: String, b: Number}
                (a, b) ->
                    return parseInt(a, 10) + b

                [Boolean, String]
                [String, Boolean]
                (x, y) ->
                    return x + y

                {a: A, b: String}
                (a, b) ->
                    return a.a() + parseInt(b, 10)
            )

            try
                @::method2 = JSUtils.jOverload(
                    [String, A]
                    [A, Boolean]
                )
            catch e
                expect e.message
                    .toBe "No function given for argument lists: [[\"String\",\"A\"],[\"A\",\"Boolean\"]]"

    ##################################################################################################################
    it "overloading", () ->
        testInstance = new TestClass()
        a = new A()

        expect testInstance.method1(10, "20")
            .toBe 30

        expect testInstance.method1("20", 20)
            .toBe 40

        expect testInstance.method1(a, "20")
            .toBe 1357

        try
            testInstance.method1(a, a)
        catch e
            expect e.message
                .toBe "Arguments do not match any known argument list!"

        expect testInstance.method1(true, "a")
            .toBe "truea"

        expect testInstance.method1("a", true)
            .toBe "atrue"

        expect testInstance.method2
            .toBeUndefined()
