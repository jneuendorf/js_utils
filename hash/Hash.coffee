# This is an implementation of a dictionary/hash that does not convert its keys into Strings.
# Keys can therefore actually by anything!
# This class is not built for performance but for easy usage (without hashing anything).
# o the lookup is `O(n)` since the keys are stored in an array.
class JSUtils.Hash

    # Creates a new Hash from a given JavaScript object.
    # @param object [Object] The native object.
    # @return [JSUtils.Hash] The new instance.
    @fromObject: (obj) ->
        return new JSUtils.Hash(obj)


    ################################################################################################
    # CONSTRUCTOR

    # @param obj [Object] Optional. A JavaScript Object whose values to use to initialize the hash.
    # @param defaultVal [mixed] Optional. This value will be returned by {JSUtils.Hash#get} if the keys was not found.
    #   If this parameter is a function it will be called with the key that's currently looked up.
    # @param equality [Function] Optional. This parameter defines what keys are considered equal. Defaults to `===`.
    # @return [JSUtils.Hash] The new instance.
    constructor: (obj, defaultVal = null, equality = (a, b) -> a is b) ->
        @keys   = []
        @values = []
        @defaultVal = defaultVal
        @equality = equality

        if obj?
            for key, val of obj
                @put key, val

    # Converts the hash into a native JavaScript Object.
    # Note that the keys will be stringified.
    # You can use the optional parameter for customizing the stringification.
    # @param toString [Function] Optional. This function defines how to convert a key into a string.
    # @return [Object] A native JavaScript Object (whose keys are stringified).
    toObject: (toString = (key) -> "#{key}") ->
        res = {}
        for key, idx in @keys
            res[toString(key)] = @values[idx]
        return res

    # Clones the hash.
    # Note that neither keys nor values are deeply cloned:
    # I.e. cloning `{[1] -> 1}` and pushing an element to the key would modify both hashes.
    # @return [JSUtils.Hash] The clone.
    clone: () ->
        res = new JSUtils.Hash()
        res.keys = @keys.slice(0)
        res.values = @values.slice(0)
        return res

    # Inverts the hash.
    # The inverted hash has the keys of the original hash as values and vice versa.
    # @return [JSUtils.Hash] The inverted hash.
    invert: () ->
        res = new JSUtils.Hash()
        res.keys = @values.slice(0)
        res.values = @keys.slice(0)
        return res

    # Return the index of the given key (or `-1`).
    # @private
    # @param key [mixed] The key to find.
    # @return [JSUtils.Hash] This instance.
    _findKeyIdx: (key) ->
        for el, idx in @keys
            if @equality(el, key)
                return idx
        return -1

    # Add a new key-value pair or overwrite an existing one.
    # @param key [mixed] The key of the entry to be created.
    # @param val [mixed] The value of the entry to be created.
    # @return [JSUtils.Hash] This instance.
    put: (key, val) ->
        idx = @_findKeyIdx(key)
        # add new entry
        if idx < 0
            @keys.push key
            @values.push val
        # overwrite entry
        else
            @keys[idx] = key
            @values[idx] = val
        return @

    # Retrieve the value for the specified key.
    # If not found `defaultVal` (defined in the constructor) will be returned.
    # If `defaultVal` is a function the return value of it - called with the key parameter - will be returned instaed.
    # @param key [mixed] The key to look up.
    # @return [mixed]
    get: (key) ->
        idx = @_findKeyIdx(key)
        if idx >= 0
            return @values[idx]
        return @defaultVal?(key) or @defaultVal

    # Returns a list of all key-value pairs.
    # Each pair is an Array with the 1st element being the key, the 2nd being the value.
    # @return [Array] Key-value pairs.
    items: () ->
        return ([key, @values[idx]] for key, idx in @keys)

    # Indicates whether the hash has the specified key.
    # @param key [mixed] The key to check.
    # @return [Boolean] If the hash has an entry with the specified key.
    has: (key) ->
        return @_findKeyIdx(key) >= 0

    # Alias for {JSUtils.Hash#has}.
    # @param key [mixed] The key to check.
    # @return [Boolean] If the hash has an entry with the specified key.
    hasKey: () ->
        return @has.apply(@, arguments)

    # Returns the number of entries in the hash.
    # @return [Number] The number of entries.
    size: () ->
        return @keys.length

    # Returns all keys of the hash.
    # @param clone [Boolean] Indicates whether to clone the internal `keys` array or not.
    # @return [Array] The keys of the hash.
    getKeys: (clone = true) ->
        if clone is true
            return @keys.slice(0)
        return @keys

    # Returns all values of the hash.
    # @param clone [Boolean] Indicates whether to clone the internal `values` array or not.
    # @return [Array] The values of the hash.
    getValues: (clone = true) ->
        if clone is true
            return @values.slice(0)
        return @values

    # Returns a list of keys that have val (or anything equal as specified in 'eqFunc') as value.
    # @param value [mixed] The value to look for.
    # @param equal [Function] Optional. This function defines values are considered equal. Defaults to `===`.
    # @return [Array] A list of keys that map to the `value` parameter.
    getKeysForValue: (value, equality = (a, b) -> a is b) ->
        idxs = (idx for val, idx in @values when equality(val, value))
        return (@keys[idx] for idx in idxs)

    # Remove all entries from the hash.
    # @return [JSUtils.Hash] This instance.
    empty: () ->
        @keys = []
        @values = []
        return @

    # Remove the entry with key `key` from the hash.
    # @param key [mixed] The key of the entry that should be removed.
    # @return [JSUtils.Hash] This instance.
    remove: (key) ->
        idx = @_findKeyIdx(key)
        if idx >= 0
            @keys.splice idx, 1
            @values.splice idx, 1
        return @

    # Iterates all entries in the hash.
    # @param callback [Function] The callback will be called for every entry in the hash.
    #   The callback receives has the following signature: `(mixed key, mixed value, Number iterationIndex) ->`.
    #   If it returns `false` the iteration will be stopped.
    # @param order [Function] Optional. This compare function specifies the order of the keys for the iteration.
    # @return [JSUtils.Hash] This instance.
    each: (callback, order) ->
        if order not instanceof Function
            for key, i in @keys
                if callback(key, @values[i], i) is false
                    return @
        # iterate keys in a certain order
        else
            keys = @keys.slice(0)
            keys.sort order
            for key, i in keys
                idx = @_findKeyIdx(key)
                if callback(key, @values[idx], i) is false
                    return @
        return @
