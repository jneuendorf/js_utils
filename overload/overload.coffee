# A matcher determines whether a given argument(s) matches the according item(s) of a signature.
class Matcher
    constructor: (@name, @matcher, @argPreprocessor) ->

    preprocess: (arg, args) ->
        return @argPreprocessor?(arg, args) or [arg]

    test: (arg, signatureItem) ->
        return @matcher.call(JSUtils.overload.matchers, arg, signatureItem)


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
                        # assign isintanceMatcher if signature was not created by the `signature()` function for performance reasons
                        # if all matchers (or any combination of them) are needed use the `signature()` function
                        signature.matchers ?= [JSUtils.overload.matchers.isintanceMatcher]
                        signatures.push(signature)
                    handler = arg
                    blocks.push({
                        signatures
                        handler
                    })
                    firstSignatureIndex = i + 1
                # no signature in block
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
                    for matcher in signature.matchers when not foundMatchForArg
                        for [accordingArg, processedArgs] in processedArgTuples[matchers.indexOf(matcher)] when accordingArg is arg
                            for processedArg, processedArgIdx in processedArgs
                                if matcher.test(processedArg, signature[argIdx]) is true
                                    foundMatchForArg = true
                                    break
                            if foundMatchForArg
                                break
                        if foundMatchForArg
                            break
                    # no `matcher` returned true for `arg` => assumption is now `false`
                    if not foundMatchForArg
                        signatureMatches = false
                        break
                if signatureMatches
                    return block.handler
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
#       [Number, String]                # \  (signature)
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
#       (x, y) ->           # |   (handler)
#           return x + y    # /
#   )
# TODO: maybe cache the caller function?? should be configurable for each overload() because caller might call same function with variable number of parameters
JSUtils.overload = (args...) ->
    {blocks, fallback} = OverloadHelpers.parseArguments(args)
    return () ->
        # TODO: find union of actually used matchers a pass potential subset of all matchers
        handler = OverloadHelpers.findHandler(arguments, blocks, JSUtils.overload.matchers.all)
        if handler?
            return handler.apply(@, arguments)
        throw new Error("Arguments do not match any known signature.")

# CONSTANTS
# this constant is an array for reference identify and contains the string for debugging purposes
JSUtils.overload.ANY = ["ANY"]

matchers = [
    new Matcher(
        "isintanceMatcher"
        (argClass, signatureItem) ->
            return JSUtils.overload.isSubclass(argClass, signatureItem) or argClass is signatureItem
        OverloadHelpers.argPreprocessors.toClass
    )
    new Matcher(
        "nullTypeMatcher"
        (arg, signatureItem) ->
            return not arg? and not signatureItem?
    )
    new Matcher(
        "arrayTypeMatcher"
        (arr, signatureItem) ->
            if arr not instanceof Array or signatureItem not instanceof Array or signatureItem.length isnt 1
                return false
            type = signatureItem[0]
            for elem in arr when not @isintanceMatcher.test(elem?.constructor, type)
                return false
            return true
    )
    new Matcher(
        "anyTypeMatcher"
        (arg, signatureItem) ->
            return signatureItem is JSUtils.overload.ANY
    )
]
JSUtils.overload.matchers =
    all: matchers
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
