prototyping["Array.prototype"] =
    # not in-place
    unique: () ->
        res = []
        for elem in @ when elem not in res
            res.push elem
        return res
    # not in-place
    uniqueBy: (propGetter, equals) ->
        if not propGetter?
            propGetter = (item) ->
                return item
        if not equals?
            equals = (a, b) ->
                return a is b

        res = []
        for elem in @
            duplicate = false
            for done in res when equals propGetter(done), propGetter(elem)
                duplicate = true
                break

            if not duplicate
                res.push elem
        return res
    intersect: (arr) ->
        arr = arr
        return (elem for elem in @ when elem in arr).unique()
    intersects: (arr) ->
        return @intersect(arr).length > 0
    groupBy: (groupFun, equality) ->
        dict = new JSUtils.Hash(null, equality)
        for elem in @
            grouped = groupFun(elem)
            if not dict.get(grouped)?
                dict.put(grouped, [])
            dict.get(grouped).push(elem)
        return dict
    insert: (index, elements...) ->
        @splice(index, 0, elements...)
        return @
    remove: (elements..., equals, removeAllOccurences = false) ->
        if arguments.length < 3
            elements = (arg for arg in arguments)
            equals = null
            removeAllOccurences = null

        if not equals?
            equals = (a, b) ->
                return a is b

        for elem in elements
            indices = []
            for myElem, idx in @ when equals(myElem, elem)
                indices.push idx
                if not removeAllOccurences
                    break
            for idx, x in indices
                @splice(idx - x, 1)
        return @
    removeAt: (idx) ->
        @splice(idx, 1)
        return @
    moveElem: (fromIdx, toIdx) ->
        res = []
        elem = @[fromIdx]
        for e, i in @ when i isnt fromIdx
            res.push e
            if i is toIdx
                res.push elem
        return res
    flatten: () ->
        return Array.prototype.concat.apply([], @)
    cloneDeep: () ->
        for elem, i in @
            if elem instanceof Array
                @[i] = elem.cloneDeep()
        return @clone()
    except: (elements...) ->
        return (el for el in @ when el not in elements)
    ###*
    * Returns the first element that fulfills the condition in a recursive search.
    * @param condition {Function}
    * @param getSubArray {Function}
    * Optional. If given, it's used to retrieve the next (lower) array for recursion.
    * Default: Go deeper only on elements that are arrays themselves.
    *###
    find: (condition, getSubArray) ->
        # item given to find => create function that finds that item
        if condition not instanceof Function
            condition = (item) ->
                return item is condition
        if not getSubArray?
            getSubArray = (item) ->
                return item

        for item in @
            if condition(item) is true
                return item

            if (subArray = getSubArray(item)) instanceof Array
                if (res = subArray.find(condition, getSubArray))?
                    return res

        return null
    # from http://www.ineverylang.com/binary-search/javascript/
    binIndexOf: (searchElement) ->
        minIndex = 0
        maxIndex = @length - 1

        while minIndex <= maxIndex
            currentIndex    = (minIndex + maxIndex) // 2
            currentElement  = @[currentIndex]

            if currentElement < searchElement
                minIndex = currentIndex + 1
            else if currentElement > searchElement
                maxIndex = currentIndex - 1
            else
                return currentIndex

        return -1
    sortByProp: (propGetter, order = "asc") ->
        if not propGetter?
            propGetter = (item) ->
                return item

        if order is "asc"
            cmpFunc = (a, b) ->
                a = propGetter(a)
                b = propGetter(b)
                if a < b
                    return -1
                if b < a
                    return 1
                return 0
        else
            cmpFunc = (a, b) ->
                a = propGetter(a)
                b = propGetter(b)
                if a > b
                    return -1
                if b > a
                    return 1
                return 0

        return @sort cmpFunc
    ###*
     * @method getMax
     * @param {Function} propertyGetter
     * The passed callback extracts the value being compared from the array elements.
     * @return {Array} An array of all maxima.
    *###
    getMax: (propertyGetter) ->
        max = null
        res = []
        if not propertyGetter?
            propertyGetter = (item) ->
                return item

        for elem in @
            val = propertyGetter(elem)
            # new max found (or first compare) => restart list with new max value
            if val > max or max is null
                max = val
                res = [elem]
            # same as max found => add to list
            else if val is max
                res.push elem

        return res
    getMin: (propertyGetter) ->
        min = null
        res = []
        if not propertyGetter?
            propertyGetter = (item) ->
                return item

        for elem in @
            val = propertyGetter(elem)
            # new min found (or first compare) => restart list with new min value
            if val < min or min is null
                min = val
                res = [elem]
            # same as min found => add to list
            else if val is min
                res.push elem

        return res
    reverseCopy: () ->
        return (item for item in @ by -1)
    sample: (n = 1, forceArray = false) ->
        if n is 1
            if not forceArray
                return @[ Math.floor(Math.random() * @length) ]
            return [ @[ Math.floor(Math.random() * @length) ] ]

        if n > @length
            n = @length

        i = 0
        res = []
        arr = @clone()
        while i++ < n
            elem = arr.sample(1)
            res.push elem
            arr.remove elem
        return res
    shuffle: () ->
        arr = @sample(@length)
        for elem, i in arr
            @[i] = elem
        return @
    swap: (i, j) ->
        tmp = @[i]
        @[i] = @[j]
        @[j] = tmp
        return @
    times: (n) ->
        res = @clone()
        for i in [1...n]
            res = res.merge @
        return res
    and: (elem) ->
        return @concat [elem]
    # in-place concat
    merge: (array) ->
        Array::push.apply(@, array)
        return @
    noNulls: () ->
        res = []
        for e in @ when e?
            res.push e
        return res
    getLast: (n = 1) ->
        return @slice(-n)
    # GETTERS & SETTERS
    average:
        get: () ->
            return Math.average.apply(null, @)
        set: () ->
            return
    last:
        get: () ->
            return @[@length - 1]
        set: (val) ->
            @[@length - 1] = val
            return @
    sum:
        get: () ->
            res = 0
            res += elem for elem in @ when Math.isNum(elem)
            return res
        set: () ->
            console.warn "[].sum is not settable!"
            return @
    # INDEX GETTERS
    first:
        get: () ->
            return @[0]
        set: (val) ->
            @[0] = val
            return @
    second:
        get: () ->
            return @[1]
        set: (val) ->
            @[1] = val
            return @
    third:
        get: () ->
            return @[2]
        set: (val) ->
            @[2] = val
            return @
    fourth:
        get: () ->
            return @[3]
        set: (val) ->
            @[3] = val
            return @
    fifth:
        get: () ->
            return @[4]
        set: (val) ->
            @[4] = val
            return @
    sixth:
        get: () ->
            return @[5]
        set: (val) ->
            @[5] = val
            return @
    seventh:
        get: () ->
            return @[6]
        set: (val) ->
            @[6] = val
            return @
    eighth:
        get: () ->
            return @[7]
        set: (val) ->
            @[7] = val
            return @
    ninth:
        get: () ->
            return @[8]
        set: (val) ->
            @[8] = val
            return @
    tenth:
        get: () ->
            return @[9]
        set: (val) ->
            @[9] = val
            return @
    eleventh:
        get: () ->
            return @[10]
        set: (val) ->
            @[10] = val
            return @
    twelveth:
        get: () ->
            return @[11]
        set: (val) ->
            @[11] = val
            return @

# aliases
aliasing["Array.prototype"] =
    prepend: "unshift"
    append: "push"
    clone: "slice"
    without: "except"
