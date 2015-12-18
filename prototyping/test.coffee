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

        it "unique", () ->
            expect [1, 2, 2, 3, 1, 3, 4, 3, 1, 4, 3, 2].unique()
                .toEqual [1, 2, 3, 4]

        it "uniqueBy", () ->
            objs = ({a: {x: [i % 3, i % 3]}} for i in [0..10])
            expect(objs.uniqueBy(
                (obj) ->
                    return obj.a.x
                (arr1, arr2) ->
                    return arr1[0] + arr1[1] is arr2[0] + arr2[1]
            )).toEqual [{a: x: [0, 0]}, {a: x: [1, 1]}, {a: x: [2, 2]}]

        it "intersect & intersects", () ->
            expect [1, 2, 3, 4, 5].intersect([2, 5, 6, 7, 8])
                .toEqual [2, 5]
            expect [1, 2, 3, 4, 5].intersect([6, 7, 8])
                .toEqual []

            expect [1, 2, 3, 4, 5].intersects([2, 5, 6, 7, 8])
                .toBe true
            expect [1, 2, 3, 4, 5].intersects([6, 7, 8])
                .toBe false

        it "groupBy", () ->
            # ~> [0, 1, 2, 0, 1, 2, 0, 1, 2, 0]
            objs = ({a: i % 3} for i in [0...10])
            hash1 = new JSUtils.Hash()
            hash1.put 0, [objs[0], objs[3], objs[6], objs[9]]
            hash1.put 1, [objs[1], objs[4], objs[7]]
            hash1.put 2, [objs[2], objs[5], objs[8]]

            hash2 = objs.groupBy (o) ->
                return o.a

            expect hash1.keys
                .toEqual hash2.keys
            expect hash1.values
                .toEqual hash2.values

        it "insert", () ->
            expect [1, 2, 2, 3].insert(2, "a", "b")
                .toEqual [1, 2, "a", "b", 2, 3]

        it "remove", () ->
            expect [1, 2, 2, 3].remove(2, null, true)
                .toEqual [1, 3]
            expect [1, 2, 2, 3].remove(2)
                .toEqual [1, 2, 3]
            expect [1, 2, 2, 3].remove(2, null, false)
                .toEqual [1, 2, 3]

        it "removeAt", () ->
            expect [1, 2, 2, 3].removeAt(0)
                .toEqual [2, 2, 3]

        it "moveElem", () ->
            expect [1, 2, 2, 3].moveElem(0, 3)
                .toEqual [2, 2, 3, 1]

        it "flatten", () ->
            expect [[1, 2], [2, 3]].flatten(0)
                .toEqual [1, 2, 2, 3]

        it "cloneDeep", () ->
            arr = [1, [2, 2], 3]
            expect arr.cloneDeep()
                .toEqual arr

            expect arr.cloneDeep() is arr
                .toBe false

        it "except & without", () ->
            expect [1, 2, 2, 3].except(2, 3)
                .toEqual [1]
            expect [1, 2, 2, 3].without(2, 3)
                .toEqual [1]

        it "find", () ->
            expect [1, [2, [2, "a"]], 3].find (elem) -> return elem[1] is "a"
                .toEqual [2, "a"]

        it "binIndexOf", () ->
            expect [1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10].binIndexOf(4)
                .toBe 4

        it "sortByProp", () ->
            objs = ({a: i % 3} for i in [0...6])
            expect objs.sortByProp (o) -> return o.a
                .toEqual [{a: 0}, {a: 0}, {a: 1}, {a: 1}, {a: 2}, {a: 2}]
            expect(objs.sortByProp(
                (o) ->
                    return o.a
                "desc"
            )).toEqual [{a: 2}, {a: 2}, {a: 1}, {a: 1}, {a: 0}, {a: 0}]

        it "getMax", () ->
            objs = ({a: i % 3} for i in [0...6])
            expect objs.getMax (o) -> return o.a
                .toEqual [{a: 2}, {a: 2}]

        it "getMin", () ->
            objs = ({a: i % 3} for i in [0...6])
            expect objs.getMin (o) -> return o.a
                .toEqual [{a: 0}, {a: 0}]

        it "reverseCopy", () ->
            arr = [1, 2, 1, 3]
            expect arr.reverseCopy()
                .toEqual [3, 1, 2, 1]
            expect arr.reverseCopy() is arr
                .toBe false

        it "sample", () ->
            arr = [1, 2, 1, 3]
            expect arr.sample(2).length
                .toBe 2

        xit "shuffle", () ->


        it "swap", () ->
            expect [1, 2, 2, 3].swap(1, 3)
                .toEqual [1, 3, 2, 2]

        it "times", () ->
            expect [1, 2, 2, 3].times(3)
                .toEqual [1, 2, 2, 3, 1, 2, 2, 3, 1, 2, 2, 3]

        it "and", () ->
            expect [1, 2, 2, 3].and(0)
                .toEqual [1, 2, 2, 3, 0]

        it "merge", () ->
            expect [1, 2, 2, 3].merge([0, 8, 9])
                .toEqual [1, 2, 2, 3, 0, 8, 9]

        it "noNulls", () ->
            expect [1, false, 2, 0, null, 2, null, undefined, 3].noNulls()
                .toEqual [1, false, 2, 0, 2, 3]

        it "getLast", () ->
            expect [1, 2, 2, 3].getLast()
                .toEqual [3]
            expect [1, 2, 2, 3].getLast(2)
                .toEqual [2, 3]

        it "average", () ->
            expect [1, 2, 2, 3].average
                .toBe 2

        it "last", () ->
            expect [1, 2, 2, 3].last
                .toBe 3

        it "sum", () ->
            expect [1, 2, 2, 3].sum
                .toBe 8

        it "first", () ->
            expect [1, 2, 2, 3].first
                .toBe 1

        it "second", () ->
            expect [1, 2, 2, 3].second
                .toBe 2

        it "third", () ->
            expect [1, 2, 2, 3].third
                .toBe 2

        it "fourth", () ->
            expect [1, 2, 2, 3].fourth
                .toBe 3

        it "aliases: prepend, append, clone (without is tested in 'expect')", () ->
            arr = [1, 2, 2, 3]
            expect arr.prepend(42)
                .toBe 5
            expect arr
                .toEqual [42, 1, 2, 2, 3]

            expect arr.append(43)
                .toBe 6
            expect arr
                .toEqual [42, 1, 2, 2, 3, 43]

            expect arr.clone()
                .toEqual arr
            expect arr.clone() is arr
                .toBe false


    ##################################################################################################################
    describe "jQueryPrototyping", () ->
