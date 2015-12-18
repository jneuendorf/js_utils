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

            it "log10", () ->
                expect Math.log10 instanceof Function
                    .toBe true
                expect Math.log10(1)
                    .toBe 0

    ##################################################################################################################
    describe "stringPrototyping", () ->

    ##################################################################################################################
    describe "arrayPrototyping", () ->

    ##################################################################################################################
    describe "jQueryPrototyping", () ->
