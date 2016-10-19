# @nodoc
# non-recursive version
validArgList = (definedArgList, currentArgList) ->
    if definedArgList.length isnt currentArgList.length
        return false

    for expected, i in definedArgList
        current = currentArgList[i]
        if expected isnt current and not JSUtils.overload.isSubclass(current, expected)
            return false
    return true

# @nodoc
# find matching arglist and then find according function
funcForArgs = (args, argLists, funcs) ->
    argListToCheck = (arg.constructor for arg in args)
    for argList, i in argLists
        if validArgList(argList, argListToCheck)
            return funcs[i] or funcs[lastMatchedIdx]
        lastMatchedIdx = i
    return null


# Overload functions be defining a set of signatures for a function so that function gets executed if the current call's arguments match one of the signatures.
# @param arguments... [Blocks] For what a block can be see the example and the overload section.
# @return [Function] The overloaded function.
#
# @overload JSUtils.overload(signatures1toN, functionToExecute1)
#   Defines one function for N different signatures.
#   So let's call such a block a list of signatures belonging to one function: Any number of blocks can be passed to JSUtils.overload().
#   @param signatures1toN... [Array of Array of class] Signatures. Any number of arrays (of classes).
#   @param functionToExecute1 [Function] Function body for the previously defined signatures.
#   @return [Function] The overloaded function
#
# @example Simple overload example
#   f = JSUtils.overload(
#       [Number, String]                # \
#       (a, b) ->                       # |> block
#           return a + parseInt(b, 10)  # /
#
#       [String, Number]                # \
#       (a, b) ->                       # |> block
#           return parseInt(a, 10) + b  # /
#
#       [Boolean, String]   # \
#       [String, Boolean]   # |
#       [String, Number]    # |>  block
#       (x, y) ->           # |
#           return x + y    # /
#   )
JSUtils.overload = (args...) ->
    argLists = []
    funcs = []
    i = 0
    len = args.length
    while i < len
        # get all argument lists (before function is defined)
        j = i
        while (argList = args[j]) not instanceof Function and j < len
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

# Defines what is considered a subclass.
# Set the body of `JSUtils.isSubclass` to `return sub == sup` to disable support for subclass checking
#
# @param sub [Class] potential subclass
# @param sup [Class] potential superclass
# @return [Boolean] If sub is a subclass of sup
isSubclass = (sub, sup) ->
    return sub.prototype instanceof sup
# @nodoc
JSUtils.overload.isSubclass = isSubclass
