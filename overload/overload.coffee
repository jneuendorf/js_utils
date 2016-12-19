# A matcher determines whether a given argument(s) matches the according item(s) of a signature.
# @nodoc
class Matcher

    constructor: (@name, @matcher, @argPreprocessor) ->

    preprocess: (arg, args) ->
        if @argPreprocessor instanceof Function
            return @argPreprocessor(arg, args)
        return arg

    # The matcher must return a boolean value
    # that indicates whether a (potentially) preprocessed argument matches the according signature item
    test: (arg, signatureItem) ->
        return @matcher.call(JSUtils.overload.matchers, arg, signatureItem)

# @nodoc
class OverloadHelpers
    # parse the arguments into blocks - each containing signatures and a handler
    @parseArguments: (args) ->
        blocks = []
        firstSignatureIndex = 0
        for arg, i in args
            if arg not instanceof Array and arg not instanceof Function
                throw new Error("JSUtils.overload expects arrays and functions as arguments. '#{arg}' given.")

            if arg instanceof Function
                # there is at least 1 signature
                if i > firstSignatureIndex
                    signatures = []
                    for j in [firstSignatureIndex...i]
                        signature = args[j]
                        # assign isintanceMatcher if signature was not created by the `signature()` function for performance reasons
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

    @findHandler: (args, blocks, matchers) ->
        # save tuples: [givenArg, processedArg(s)] -> thus originals and processed are associated (hash like)
        processedArgTuples = []
        for matcher in matchers
            processedArgTuples.push do (matcher) ->
                res = []
                for arg in args
                    tuple = [arg, matcher.preprocess(arg, args)]
                    res.push(tuple)
                return res

        numArgs = args.length
        for block in blocks
            for signature in block.signatures
                # special case: empty list
                if numArgs is 0 and signature.length is 0
                    return block.handler
                if signature.length isnt args.length
                    continue
                # assume signature fits given arguments
                signatureMatches = true
                # non-empty arg list
                for arg, argIdx in args
                    foundMatchForArg = false
                    for matcher in signature.matchers when not foundMatchForArg
                        for [accordingArg, processedArg] in processedArgTuples[matchers.indexOf(matcher)] when accordingArg is arg
                            if matcher.test(processedArg, signature[argIdx]) is true
                                foundMatchForArg = true
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


# Overload functions by defining a set of signatures for a function that is executed
# if the current call's arguments match one of the signatures belonging to that function.
# Such a function is called `handler`.
# The handler of the first matching signature will be returned.
# Therefore duplicate signature won't throw errors but might lead to unexpected behavior.
# The last block may contain only a handler which is used in case no signature matched the arguments.
# @param arguments... [Blocks] For what a block can be see the example and the overload section.
# @return [Function] The overloaded function.
#
# @overload JSUtils.overload(signatures1toN..., functionToExecute1)
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
#       [Boolean, String]       # \
#       [String, Boolean]       # |
#       # duplicate signature   # |
#       [String, Number]        # |>  block
#       (x, y) ->               # |   (handler)
#           return x + y        # /
#   )
# TODO: maybe cache the caller function?? should be configurable for each overload() because caller might call same function with variable number of parameters
JSUtils.overload = (args...) ->
    {blocks, fallback} = OverloadHelpers.parseArguments(args)
    return () ->
        # TODO: find union of actually used matchers a pass potential subset of all matchers
        handler = OverloadHelpers.findHandler(arguments, blocks, JSUtils.overload.matchers.all)
        handler ?= fallback
        if handler?
            return handler.apply(@, arguments)
        throw new Error("Arguments do not match any known signature.")


# this constant is used by the `anyTypeMatcher` an array for reference identify and contains the string for debugging purposes
JSUtils.overload.ANY = ["ANY"]

# @nodoc
matchers = [
    new Matcher(
        "isintanceMatcher"
        (argClass, signatureItem) ->
            return JSUtils.overload.isSubclass(argClass, signatureItem) or argClass is signatureItem
        (arg) ->
            return arg?.constructor
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
# This object contains all available matchers.
# Currently custom matchers can not be added.
# These are the available matchers and match if the argument:
#   (1) `isintanceMatcher`: is an instance of or equals the signature item
#   (2) `nullTypeMatcher`: is `null` or `undefined` and the signature item is `null` or `undefined` (useful if `null` should be matched by `undefined` and vice versa...the isintanceMatcher won't match those cases)
#   (3) `arrayTypeMatcher`: is an array only containing elements that all get matched by the first element in the signature item. E.g. `[1,2,3]` is matched by `[Number]`.
#   (4) `anyTypeMatcher`: is anything. Useful because `null` is not matched by `Object` (using the `isintanceMatcher`) and vice versa (using the `nullTypeMatcher`).
JSUtils.overload.matchers =
    all: matchers
    isintanceMatcher: matchers[0]
    nullTypeMatcher: matchers[1]
    arrayTypeMatcher: matchers[2]
    anyTypeMatcher: matchers[3]

# Callable with `JSUtils.overload.signature()`.
# This function can be used to create signatures that will be checked only by the given matchers.
# @param signature [Array] A list of items (most commonly classes).
# @param matchers... [Matchers] These matchers will be used when trying to match a signature. Can also be `...JSUtils.overload.matchers.all`.
# @return [Array] The signature (which is used when the overloaded function is called).
signature = (signature, givenMatchers...) ->
    if signature instanceof Array
        givenMatchers = (matcher for matcher in givenMatchers when matcher in JSUtils.overload.matchers.all)
        if givenMatchers.length > 0
            signature.matchers = givenMatchers
            return signature
        throw new Error("Matchers must be matcher instances.")
    throw new Error("Signature must be an array.")

# @nodoc
JSUtils.overload.signature = signature

# Callable with `JSUtils.overload.isSubclass()`.
# Defines what is considered a subclass.
# Set the body of `JSUtils.isSubclass` to `return sub == sup` to disable support for subclass checking.
# `null/undefined` is not considered a subclass of `null/undefined`.
# @param sub [Class] potential subclass
# @param sup [Class] potential superclass
# @return [Boolean] If sub is a subclass of sup
isSubclass = (sub, sup) ->
    try
        return sub.prototype instanceof sup
    catch
        return false
    # if sub?.prototype? and sup?
    #     return sub.prototype instanceof sup
    # return false

# @nodoc
JSUtils.overload.isSubclass = isSubclass
