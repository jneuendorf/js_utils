describe "Hash", () ->

    beforeEach () ->
        @hash = new JSUtils.Hash()
        @hash.put 1, "2"
        @hash.put 2, "3"

        @hashEq = new JSUtils.Hash(
            null
            42
            (key1, key2) ->
                return key1[0] + key1[1] is key2[0] + key2[1]
        )

    it "get & put", () ->
        # GET
        expect @hash.get(1)
            .toBe "2"
        expect @hash.get(["a", "b"])
            .toBe undefined

        # PUT
        expect @hash.get(2)
            .toBe "3"
        # replace
        @hash.put 2, "4"
        expect @hash.get(2)
            .toBe "4"

        # array as key
        arr = ["a", "b"]
        @hash.put arr, "3"
        expect @hash.get(arr)
            .toBe "3"
        expect @hash.get(["a", "b"])
            .toBeUndefined()

        # object as key
        objectKey = {key: "object"}
        objectVal = {someObject: "that's me"}
        @hash.put objectKey, objectVal
        expect @hash.get(objectKey)
            .toBe objectVal

        # special equals-function: any key with the same sum of the first two elements is considered equal!
        @hashEq.put [1, 2], 3
        expect @hashEq.get [1, 2]
            .toBe 3
        expect @hashEq.get [2, 1]
            .toBe 3

        @hashEq.put [3, 0], 3
        expect @hashEq.get [3, 0]
            .toBe 3
        expect @hashEq.get [2, 1]
            .toBe 3

    it "remove", () ->
        arr = ["a", "b"]
        @hash.put arr, "3"

        @hash.remove 1
        expect @hash.get(1)
            .toBeUndefined()

        expect @hash.get(2)
            .toBe "3"

        @hashEq.put [1, 2], 3
        @hashEq.remove [2, 1]
        # NOTE: 42 here because this value was defined as the defaultValue of this.hashEq
        expect @hashEq.get [1, 2]
            .toBe 42

    it "empty", () ->
        arr = ["a", "b"]
        @hash.put arr, "3"

        @hash.empty()

        expect @hash.keys.length
            .toBe 0
        expect @hash.values.length
            .toBe 0

    it "items", () ->
        arr = ["a", "b"]
        @hash.put arr, "3"

        expect @hash.items()
            .toEqual [
                [1, "2"]
                [2, "3"]
                [["a", "b"], "3"]
            ]

    it "has (== hasKey)", () ->
        arr = ["a", "b"]
        @hash.put arr, "3"

        expect @hash.has 1
            .toBe true
        expect @hash.has 2
            .toBe true
        expect @hash.has arr
            .toBe true

        expect @hash.has ["a", "b"]
            .toBe false
        expect @hash.has 3
            .toBe false

    it "size", () ->
        expect @hash.size()
            .toBe 2

        obj = {a: 10, b: 20}
        @hash.put obj
        expect @hash.size()
            .toBe 3
        @hash.put {x: 1e3, y: 0.4}, "value"
        expect @hash.size()
            .toBe 4
        @hash.remove(obj)
        expect @hash.size()
            .toBe 3

    it "getKeys", () ->
        expect @hash.getKeys().length
            .toBe @hash.keys.length
        expect @hash.getKeys()
            .toEqual @hash.keys
        expect @hash.getKeys() is @hash.keys
            .toBe false
        expect @hash.getKeys(false) is @hash.keys
            .toBe true

    it "getValues", () ->
        expect @hash.getValues().length
            .toBe @hash.values.length
        expect @hash.getValues()
            .toEqual @hash.values
        expect @hash.getValues() is @hash.values
            .toBe false
        expect @hash.getValues(false) is @hash.values
            .toBe true

    it "getKeysForValue", () ->
        @hash.put 3, "3"
        expect @hash.getKeysForValue("3")
            .toEqual [2, 3]

    it "JSUtils.Hash.fromObject", () ->
        hash = JSUtils.Hash.fromObject {
            a: 10
            "myKey": ["a", 22]
        }
        expect hash.getKeys()
            .toEqual ["a", "myKey"]
        expect hash.getValues()
            .toEqual [10, ["a", 22]]

    it "toObject", () ->
        hash = JSUtils.Hash.fromObject {
            a: 10
            "myKey": ["a", 22]
        }
        expect hash.toObject()
            .toEqual {
                a: 10
                myKey: ["a", 22]
            }

    it "clone", () ->
        expect {k: @hash.clone().getKeys(), v: @hash.clone().getValues()}
            .toEqual {k: @hash.getKeys(), v: @hash.getValues()}
        expect @hash.clone() is @hash
            .toBe false

    it "invert", () ->
        inverted = @hash.invert()
        expect inverted.getKeys()
            .toEqual ["2", "3"]
        expect inverted.getValues()
            .toEqual [1, 2]

    it "each", () ->
        maxIdx = null
        @hash.each (key, val, idx) =>
            expect key
                .toBe @hash.getKeys()[idx]
            expect val
                .toBe @hash.getValues()[idx]
            maxIdx = idx
        expect maxIdx
            .toBe @hash.size() - 1

        # iterate in certain order
        result = []
        @hash.each(
            (key, val, idx) ->
                result.push [key, val]
            (a, b) ->
                return b - a
        )
        expect result
            .toEqual [[2, "3"], [1, "2"]]
