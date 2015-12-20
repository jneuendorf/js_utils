# non-recursive version
arrEquals = (arr1, arr2) ->
    if arr1.length isnt arr2.length
        return false

    for x, i in arr1 when x isnt arr2[i]
        return false

    return true

# find matching arglist and then find according function
funcForArgs = (args, argLists, funcs) ->
    argListToCheck = (arg.constructor for arg in args)

    for argList, i in argLists
        if arrEquals(argList, argListToCheck)
            return funcs[i] or funcs[lastMatchedIdx]
        lastMatchedIdx = i
    return null

JSUtils.overload = (args...) ->
    argLists = []
    funcs = []

    i = 0
    len = args.length
    while i < len
        # get all argument lists (before function is defined)
        j = i
        while (argList = args[j]) not instanceof Function and j < len
            if argList not instanceof Array
                argLists.push(type for name, type of argList)
            else
                argLists.push argList
            j++

        # if not: last element reached and last element is not a function <=> wrong mapping given
        if j < len
            # add function
            funcs.push args[j]
            # we know (j - i) many arg lists have been pushed => push that many -1 nulls
            for k in [0...(j - i - 1)]
                funcs.push null
            i = j + 1
        else
            throw new Error("No function given for argument lists: #{JSON.stringify(arg.name for arg in argList for argList in args.slice(i))}")

    return () ->
        if (f = funcForArgs(arguments, argLists, funcs))?
            return f.apply(@, arguments)

        throw new Error("Arguments do not match any known argument list!")
