# not in-place
Array::unique = () ->
    res = []
    for elem in @ when elem not in res
        res.push elem
    return res

# not in-place
Array::uniqueBy = (propGetter, equals) ->
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

Array::intersect = (arr) ->
    arr = arr
    return (elem for elem in @ when elem in arr).unique()

Array::intersects = (arr) ->
    return @intersect(arr).length > 0

Array::groupBy = (groupFun, equality) ->
    dict = new App.Hash(null, equality)
    for elem in @
        grouped = groupFun(elem)
        if not dict.get(grouped)?
            dict.put(grouped, [])
        dict.get(grouped).push(elem)
    return dict

Array::insert = (index, elements...) ->
    @splice(index, 0, elements...)
    return @

Array::remove = (elements...) ->
    return (elem for elem in @ when elem not in elements)

Array::removeAt = (idx) ->
    @splice(idx, 1)
    return @

Array::elemMoved = (fromIdx, toIdx) ->
    res = []
    elem = @[fromIdx]
    for e, i in @ when i isnt fromIdx
        res.push e
        if i is toIdx
            res.push elem

    return res


Array::flatten = () ->
    return Array.prototype.concat.apply([], @)

Array::clone = Array::slice

Array::cloneDeep = () ->
    for elem, i in @
        if elem instanceof Array
            @[i] = elem.cloneDeep()

    return @clone()

Array::except = (vals...) ->
    if vals.first instanceof Array
        vals = vals.first
    return (el for el in @ when el not in vals)

Array::without = Array::except

###*
* Returns the first element that fulfills the condition in a recursive search.
* @param condition {Function}
* @param getSubArray {Function}
* Optional. If given, it's used to retrieve the next (lower) array for recursion.
* Default: Go deeper only on elements that are arrays themselves.
*###
Array::find = (condition, getSubArray) ->
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
Array::binIndexOf = (searchElement) ->
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

Array::sortProp = (getProp, order = "asc") ->
    if not getProp?
        getProp = (item) ->
            return item

    if order is "asc"
        cmpFunc = (a, b) ->
            a = getProp(a)
            b = getProp(b)
            if a < b
                return -1
            if b < a
                return 1
            return 0
    else
        cmpFunc = (a, b) ->
            a = getProp(a)
            b = getProp(b)
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
Array::getMax = (propertyGetter) ->
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

Array::getMin = (propertyGetter) ->
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

Array::reverseCopy = () ->
    return (item for item in @ by -1)

Array::sample = (n = 1, forceArray = false) ->
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

Array::shuffle = () ->
    arr = @sample(@length)
    for elem, i in arr
        @[i] = elem
    return @

Array::toObject = (callback) ->
    res = {}
    if not callback?
        for elem, i in @
            res[elem[0]] = elem[1]
        return res

    for elem, i in @
        elem = callback(elem)
        res[elem[0]] = elem[1]
    return res

Array::swap = (i, j) ->
    tmp = @[i]
    @[i] = @[j]
    @[j] = tmp
    return @

Array::times = (n) ->
    res = @clone()
    for i in [1...n]
        res = res.merge @
    return res

Array::prepend = Array::unshift
Array::append = Array::push


arrayProtoDefs =
    # METHODS
    and:
        value: (elem) ->
            return @.concat [elem]
    # in-place concat
    merge:
        value: (array) ->
            Array::push.apply(@, array)
            return @
    noNulls:
        value: () ->
            res = []
            for e in @ when e?
                res.push e
            return res
    # GETTERS & SETTERS
    average:
        get: () ->
            return Math.average.apply(null, @)
        set: () ->
            return
    last:
        get: () ->
            if @length > 0
                if n? and n > 0
                    return @slice(-n)
                return @[@length - 1]
            return undefined
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

indexProps = [
    "first"
    "second"
    "third"
    "fourth"
    "fifth"
    "sixth"
    "seventh"
    "eighth"
    "ninth"
    "tenth"
    "forty-second"
]
for prop, idx in indexProps
    do (prop, idx) ->
        return arrayProtoDefs[prop] =
            get: () ->
                return @[idx]
            set: (val) ->
                @[idx] = val
                return @

for key, val of arrayProtoDefs
    val.enumerable = false
    val.configurable = false

Object.defineProperties Array::, arrayProtoDefs
