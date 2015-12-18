describe "prototyping", () ->

    ##################################################################################################################
    describe "nativesPrototyping", () ->

        describe "Math", () ->

            it "isNum", () ->
                expect Math.isNum instanceof Function
                    .toBe true
                expect Math.isNum(0)
                    .toBe true
                expect Math.isNum(-2.34)
                    .toBe true

                expect Math.isNum("-2.34")
                    .toBe false
                expect Math.isNum(Infinity)
                    .toBe false
                expect Math.isNum(-Infinity)
                    .toBe false
                expect Math.isNum(true)
                    .toBe false

            it "average", () ->
                expect Math.average instanceof Function
                    .toBe true
                expect Math.average(1, 2)
                    .toBe 1.5
                expect Math.average(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
                    .toBe 5.5
                expect Math.average(-3, 2)
                    .toBe -0.5

            it "sign", () ->
                expect Math.sign instanceof Function
                    .toBe true
                expect Math.sign(0)
                    .toBe 0
                expect Math.sign(3)
                    .toBe 1
                expect Math.sign(-3)
                    .toBe -1

                expect Math.sign("-3")
                    .toBe undefined
                expect Math.sign(Infinity)
                    .toBe undefined

            it "log10", () ->
                expect Math.log10 instanceof Function
                    .toBe true
                expect Math.log10(1)
                    .toBe 0
                expect Math.log10(10)
                    .toBe 1
                expect Math.log10(100)
                    .toBe 2
                expect Math.log10(1e5)
                    .toBe 5

        describe "Function", () ->

            it "clone", () ->
                f1 = (a) ->
                    return a + 2
                f2 = f1.clone()
                for i in [-100..100] by 0.5
                    expect f1(i)
                        .toBe f2(i)

        describe "Object", () ->

            it "except", () ->
                a =
                    a: 10
                    b: 20
                    c: 30

                expect Object.except(a, "b")
                    .toEqual {a: 10, c: 30}

            it "values", () ->
                a =
                    a: 10
                    b: 20
                    c: 30

                expect Object.values(a)
                    .toEqual [10, 20, 30]

            it "swapValues", () ->
                a =
                    a: 10
                    b: 20
                    c: 30

                expect Object.swapValues(a, "a", "c")
                    .toEqual {a: 30, b: 20, c: 10}

        describe "Element", () ->

            it "remove", () ->
                body = $(document.body)
                body.append "<div class='_test' />"
                document.querySelector("._test").remove()
                expect body.find("._test").length
                    .toBe 0



    ##################################################################################################################
    describe "stringPrototyping", () ->

        it "replaceMultiple", () ->
            str = "me me me you me you bla"
            expect str.replaceMultiple(["me", "I", "you", "you all"], 0)
                .toBe "I me me you all me you bla"
            expect str.replaceMultiple(["me", "I", "you", "you all"], "tuples")
                .toBe "I me me you all me you bla"

            expect str.replaceMultiple(["me", "you", "him"], 1)
                .toBe "him me me him me you bla"
            expect str.replaceMultiple(["me", "you", "him"], "diffByOne")
                .toBe "him me me him me you bla"

            expect str.replaceMultiple(["me", (index) -> return "#{index + 1}"], 2)
                .toBe "1 2 3 you 4 you bla"
            expect str.replaceMultiple(["me", (index) -> return "#{index + 1}"], "oneByDiff")
                .toBe "1 2 3 you 4 you bla"

        it "firstToUpper", () ->
            expect "manylittleletters".firstToUpper()
                .toBe "Manylittleletters"

        it "firstToLower", () ->
            expect "MANYBIGLETTERS".firstToLower()
                .toBe "mANYBIGLETTERS"

        it "capitalize", () ->
            expect "hello world, this is me".capitalize()
                .toBe "Hello World, This Is Me"

        it "camelToKebab", () ->
            expect "MyAwesomeClass".camelToKebab()
                .toBe "my-awesome-class"

        it "snakeToCamel", () ->
            expect "my_awesome_function".snakeToCamel()
                .toBe "myAwesomeFunction"

        it "camelToSnake", () ->
            expect "myAwesomeFunction".camelToSnake()
                .toBe "my_awesome_function"

        it "lower & upper", () ->
            expect String::upper
                .toBe String::toUpperCase
            expect String::lower
                .toBe String::toLowerCase

        it "isNumeric", () ->
            expect "234".isNumeric()
                .toBe true
            expect "+234".isNumeric()
                .toBe true
            expect "-234.567".isNumeric()
                .toBe true

            expect "some string".isNumeric()
                .toBe false

        it "endsWith", () ->
            expect "myAwesomeFunction".endsWith("Function")
                .toBe true

            expect "myAwesomeFunction".endsWith("Wunction")
                .toBe false

        it "times", () ->
            expect "word ".times(5)
                .toBe "word word word word word "
            expect "word ".times(1)
                .toBe "word "

        it "encodeHTMLEntities", () ->
            expect "ü".encodeHTMLEntities()
                .toBe "&#252;"

    ##################################################################################################################
    describe "arrayPrototyping", () ->

    ##################################################################################################################
    describe "jQueryPrototyping", () ->
