String::replaceMultiple = (array, mode) ->
    # if invalid array return the original string
    if not array? or array.length < 2
        return @

    length = array.length

    modes =
        0:            0
        tuples:        0    # ['a','b','c','d'] means 'a' -> 'b' and 'c' -> 'd'
        1:            1
        diffByOne:    1    # ['asdf','bsdf','replacement'] means 'asdf' -> 'replacement' and 'bsdf' -> 'replacement'
        2:            2
        oneByDiff:    2    # ['i',callBack(i)] means replace each i by the return value of a callback function w/ parameter = index (starting at 0)

    mode = modes[mode]
    if not mode?
        mode = 0

    temp = @
    # tuples
    if mode is 0
        # if number of elements in array is odd -> array is invalid
        if length & 1
            return @

        for i in [0...length] by 2
            temp = temp.replace(array[i], array[i + 1])


    # replace different substrings by fixed replacement
    if mode is 1
        repl = array[length - 1]
        for i in [0...(length - 1)]
            temp = temp.replace(array[i], repl)

    # replace fixed substring with different strings
    if mode is 2
        # array must have exactly 2 arguments: 1. string, 2. function
        if length isnt 2
            return @

        needle    = array.first
        cbFun    = array.second
        i = 0
        while temp.indexOf(needle) isnt -1 and i < length
            temp = temp.replace(needle, cbFun(i))
            i++

    return temp

# camel case to normal words
String::unCamelCase = () ->
    return @
        # insert a space between lower & upper
        .replace(/([a-z])([A-Z])/g, '$1-$2')
        # space before last upper in a sequence followed by lower
        .replace(/\b([A-Z]+)([A-Z])([a-z])/, '$1-$2$3')
        .toLowerCase()

String::firstToUpperCase = () ->
    return @charAt(0).toUpperCase() + @slice(1)

String::firstToLowerCase = () ->
    return @charAt(0).toLowerCase() + @slice(1)

String::snakeToCamelCase = () ->
    res = ""

    for char in @
        # not underscore
        if char isnt "_"
            # previous character was not an underscore => just add character
            if prevChar isnt "_"
                res += char
            # previous character was an underscore => add upper case character
            else
                res += char.toUpperCase()

        prevChar = char

    return res

String::camelToSnakeCase = () ->
    res = ""
    prevChar = null
    for char in @
        # lower case => just add
        if char is char.toLowerCase()
            res += char
        # upper case
        else
            if prevChar
                res += "_" + char.toLowerCase()
            else
                res += char.toLowerCase()

        prevChar = char

    return res

String::lower = String::toLowerCase
String::upper = String::toUpperCase

String::isNumeric = () ->
    return Math.isNum parseFloat(@)

String::endsWith = (end) ->
    index = @lastIndexOf end
    if index >= 0
        return index + end.length is @length
    return false

String::times = (n = 1) ->
    res = ""
    for i in [0...n]
        res += @
    return res

String::encodeHTMLEntities = () ->
    return @replace /[\u00A0-\u9999<>\&]/gim, (i) ->
        return "&##{i.charCodeAt(0)};"
