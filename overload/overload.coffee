# non-recursive version
validArgList = (definedArgList, currentArgList) ->
    if definedArgList.length isnt currentArgList.length
        return false

    for expected, i in definedArgList
        current = currentArgList[i]
        if expected isnt current and not JSUtils.overload.isSubclass(current, expected)
            return false
    return true

# find matching arglist and then find according function
funcForArgs = (args, argLists, funcs) ->
    argListToCheck = (arg.constructor for arg in args)
    for argList, i in argLists
        if validArgList(argList, argListToCheck)
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

###Set this to "return sub == sup" to disable support for subclass checking###
JSUtils.overload.isSubclass = (sub, sup) ->
    return sub.prototype instanceof sup
