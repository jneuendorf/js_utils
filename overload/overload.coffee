# A matcher determines whether a given argument(s) matches the according item(s) of a signature.
class Matcher

    constructor: (@name, @matcher, @argPreprocessor) ->

    preprocess: (arg, args) ->
        return @argPreprocessor?(arg, args) or [arg]

    test: (args, signatureItems) ->
        return @matcher(args, signatureItems)


class OverloadHelpers

    @parseArguments: (args) ->
        blocks = []
        firstSignatureIndex = 0
        for arg, i in args
            if arg not instanceof Array and arg not instanceof Function
                throw new Error("JSUtils.overload expects arrays and functions as arguments. '#{arg}' given.")

            if arg instanceof Function
                # there is at least 1 signature
                if i > firstSignatureIndex
                    # signatures = (args[j] for j in [firstSignatureIndex...i])
                    signatures = []
                    for j in [firstSignatureIndex...i]
                        signature = args[j]
                        # assign all matchers if signature was not created by the `signature()` function
                        signature.matchers ?= matchers
                        signatures.push(signature)
                    handler = arg
                    blocks.push({
                        signatures
                        handler
                    })
                    firstSignatureIndex = i + 1
                else
                    # last func => then interpret as fallback function
                    if i is args.length - 1
                        fallback = arg
                    else
                        throw new Error("JSUtils.overload: no signatures given for function '#{arg}'.")
        if blocks.length is 0
            throw new Error("JSUtils.overload: Either no functions were given or no arguments at all.")
        return {
            blocks
            fallback
        }

    # each preprocessor must return an array (because the original arg might be expanded to a list)
    @argPreprocessors:
        # instance |-> constructor
        toClass: (arg, args) ->
            return [arg?.constructor]

    @findHandler: (args, blocks, matchers) ->
        # save tuples: [givenArg, processedArg(s)] -> thus originals and processed are associated (hash like)
        processedArgTuples = []
        for matcher in matchers
            processedArgTuples.push do (matcher) ->
                res = []
                res.numProcessedArgs = 0
                for arg in args
                    tuple = [arg, matcher.preprocess(arg, args)]
                    res.push(tuple)
                    res.numProcessedArgs += tuple[1].length
                return res

        numArgs = args.length
        for block in blocks
            for signature in block.signatures
                # special case: empty list
                if numArgs is 0 and signature.length is 0
                    return block.handler
                # assume signature fits given arguments
                signatureMatches = true
                # non-empty arg list
                for arg, argIdx in args
                    foundMatchForArg = false
                    for matcher, matcherIdx in signature.matchers when not foundMatchForArg
                        for [accordingArg, processedArgs] in processedArgTuples[matcherIdx] when accordingArg is arg
                            for processedArg, processedArgIdx in processedArgs
                                if matcher.test(processedArg, signature[argIdx]) is true
                                    foundMatchForArg = true
                                    break
                            if foundMatchForArg
                                break
                        if foundMatchForArg
                            break
                    # no `matcher` returned true for `arg`
                    if not foundMatchForArg
                        signatureMatches = false
                        break
                if signatureMatches
                    return block.handler
        return null

matchers = [
    # no constructor means `undefined` (for e.g. null) => nothing will match [null] because null !== undefined (=== null.constructor)
    new Matcher(
        "constructorMatcher"
        (argClass, signatureItem) ->
            return argClass is signatureItem
        OverloadHelpers.argPreprocessors.toClass
    )
    new Matcher(
        "isintanceMatcher"
        (argClass, signatureItem) ->
            return JSUtils.overload.isSubclass(argClass, signatureItem) or argClass is signatureItem is Object
        OverloadHelpers.argPreprocessors.toClass
    )
    # anyTypeMatcher
    new Matcher(
        "nullTypeMatcher"
        (arg, signatureItem) ->
            return not arg? and not signatureItem?
    )
    # arrayTypeMatcher
    # splatMatcher
]




# TODO: maybe cache the caller function?? should be configurable for each overload() because caller might call same function with variable number of parameters
JSUtils.overload = (args...) ->
    {blocks, fallback} = OverloadHelpers.parseArguments(args)
    return () ->
        handler = OverloadHelpers.findHandler(arguments, blocks, matchers)
        if handler?
            return handler.apply(@, arguments)
        throw new Error("Arguments do not match any known signature.")

# CONSTANTS
JSUtils.overload.FALLBACK = ["FALLBACK"]
JSUtils.overload.ANY = ["ANY"]

JSUtils.overload.matchers = {}
for matcher in matchers
    JSUtils.overload.matchers[matcher.name] = matcher


# This function can be used to create signatures that will be checked only by the given matchers
JSUtils.overload.signature = (signature, givenMatchers...) ->
    if signature instanceof Array
        givenMatchers = (matcher for matcher in givenMatchers when matcher in matchers)
        if givenMatchers.length > 0
            signature.matchers = givenMatchers
            return signature
        throw new Error("Matchers must be matcher instances.")
    throw new Error("Signature must be an array.")






# @nodoc
# non-recursive version
# validArgList = (definedArgList, currentArgList) ->
#     if definedArgList.length isnt currentArgList.length
#         return false
#
#     for expected, i in definedArgList
#         current = currentArgList[i]
#         # treat undefined and null the equally => a defined list [undefined] will match a call f(null)
#         if not expected? and not current?
#             continue
#         if expected isnt current
#             try
#                 if not JSUtils.overload.isSubclass(current, expected)
#                     return false
#             catch error
#                 return false
#     return true

# @nodoc
# find matching arglist and then find according function
# funcForArgs = (args, argLists, funcs) ->
#     argListToCheck = ((arg?.constructor or null) for arg in args)
#     for argList, i in argLists
#         if validArgList(argList, argListToCheck)
#             return funcs[i] or funcs[lastMatchedIdx]
#         lastMatchedIdx = i
#     return null


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
#       [Number, String]                # \ (signature)
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
# JSUtils.overload = (args...) ->
#     argLists = []
#     funcs = []
#     i = 0
#     len = args.length
#     while i < len
#         # get all argument lists (before function is defined)
#         j = i
#         while (argList = args[j]) not instanceof Function and j < len
#             argLists.push argList
#             j++
#
#         # if not: last element reached and last element is not a function <=> wrong mapping given
#         if j < len
#             # add function
#             funcs.push args[j]
#             # we know (j - i) many arg lists have been pushed => push that many -1 nulls
#             for k in [0...(j - i - 1)]
#                 # TODO: fix this...pushing null should be sufficient but somehow the lastMatchedIdx is wrong so overload tries `null()`
#                 funcs.push args[j]
#             i = j + 1
#         else
#             throw new Error("No function given for argument lists: #{JSON.stringify(arg.name for arg in argList for argList in args.slice(i))}")
#     console.log funcs
#
#     return () ->
#         if (f = funcForArgs(arguments, argLists, funcs))?
#             return f.apply(@, arguments)
#
#         throw new Error("Arguments do not match any known argument list! Given arguments: #{JSON.stringify(arg for arg in arguments)}. Available signatures: #{JSON.stringify((arg?.name or null for arg in argList) for argList in argLists)}")

# TODO: way to keep things simple and fast (only constructorMatcher will be used)
# JSUtils.overloadSimple()

# Defines what is considered a subclass.
# Set the body of `JSUtils.isSubclass` to `return sub == sup` to disable support for subclass checking.
# # `null/undefined` is considered a subclass of `null/undefined`.
#
# @param sub [Class] potential subclass
# @param sup [Class] potential superclass
# @return [Boolean] If sub is a subclass of sup
isSubclass = (sub, sup) ->
    if sub?.prototype? and sup?
        return sub.prototype instanceof sup
    return false

# @nodoc
JSUtils.overload.isSubclass = isSubclass
