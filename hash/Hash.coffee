###*
 * This is an implementation of a dictionary/hash that does not convert its keys into Strings. Keys can therefore actually by anything! :)
 * @class Configurator
 * @constructor
*###
class JSUtils.Hash

    ###*
     * Creates a new Hash from a given JavaScript object.
     * @static
     * @method fromObject
     * @param object {Object}
    *###
    @fromObject: (obj) ->
        hash = new JSUtils.Hash()
        for key, val of obj
            hash.put key, val
        return hash

    constructor: (obj, defaultVal = null, equality) ->
        @keys   = []
        @values = []
        @equality = equality

        if obj?
            for key, val of obj
                @put key, val

    toObject: () ->
        res = {}
        for key, idx in @keys
            res[key] = @values[idx]
        return res


    clone: () ->
        res         = new JSUtils.Hash()
        res.keys    = @keys.clone()
        res.values  = @values.clone()
        return res

    invert: () ->
        res         = new JSUtils.Hash()
        res.keys    = @values.clone()
        res.values  = @keys.clone()
        return res

    ###*
     * Adds a new key-value pair or overwrites an existing one.
     * @private
     * @method _putObject
     * @param object {Object}
     * @return {Hash} This instance.
     * @chainable
    *###
    _putObject = (obj) ->
        for key, val of obj
            @put key, val
        return @

    ###*
     * Return the index of the given key
     * @method findKeyIdx
     * @param key {mixed}
     * @return {Hash} This instance.
     * @chainable
    *###
    findKeyIdx: (key) ->
        for el, idx in @keys
            if @equality?(el, key) or el is key
                return idx
        return -1

    ###*
     * Adds a new key-value pair or overwrites an existing one.
     * @method put
     * @param key {mixed}
     * @param val {mixed}
     * @return {Hash} This instance.
     * @chainable
    *###
    put: (key, val) ->
        # no value given => assume an object was passed
        if not val?
            return _putObject.call(@, key)

        idx = @findKeyIdx(key)
        # add new entry
        if idx < 0
            @keys.push key
            @values.push val
        # overwrite entry
        else
            @keys[idx] = key
            @values[idx] = val

        return @

    ###*
     * Adds a new key-value pair or overwrites an existing one.
     * @method putMultiple
     * @param pairs... {mixed}
     * @param val {mixed}
     * @return {Hash} This instance.
     * @chainable
    *###
    putMultiple: (pairs...) ->
        for [key, val] in pairs
            # no value given => assume an object was passed
            if not val?
                _putObject.call(@, key)

            idx = @findKeyIdx(key)
            # add new entry
            if idx < 0
                @keys.push key
                @values.push val
            # overwrite entry
            else
                idx = @keys.indexOf key
                # add new entry
                if idx < 0
                    @keys.push key
                    @values.push val
                # overwrite entry
                else
                    @keys[idx] = key
                    @values[idx] = val

        return @

    ###*
     * Returns the value (or null) for the specified key.
     * @method get
     * @param key {mixed}
     * @param [equalityFunction] {Function}
     * This optional function can overwrite the test for equality between keys. This function expects the parameters: (the current key in the key iteration, 'key'). If this parameters is omitted '===' is used.
     * @return {mixed}
    *###
    get: (key, eqFunc) ->
        if not eqFunc?
            idx = @findKeyIdx(key)
        else
            idx = (i for k, i in @keys when eqFunc(k, key) is true).first

        if idx >= 0
            return @values[idx]

        return @defaultVal?() or @defaultVal

    ###*
     * Returns a list of all key-value pairs. Each pair is an Array with the 1st element being the key, the 2nd being the value.
     * @method getAll
     * @return {Array} Key-value pairs.
    *###
    getAll: () ->
        res = []

        for key, idx in @keys
            res.push [ key, @values[idx] ]

        return res

    ###*
     * Indicates whether the Hash has the specified key.
     * @method hasKey
     * @param key {mixed}
     * @return {Boolean}
    *###
    hasKey: (key) ->
        return @findKeyIdx(key) >= 0

    has: @::hasKey

    ###*
     * Returns the number of entries in the Hash.
     * @method size
     * @return {Integer}
    *###
    size: () ->
        return @keys.length

    ###*
     * Returns all the keys of the Hash.
     * @method getKeys()
     * @return {Array}
    *###
    getKeys: () ->
        return @keys

    ###*
     * Returns all the values of the Hash.
     * @method getValues()
     * @return {Array}
    *###
    getValues: () ->
        return @values

    ###*
     * Returns a list of keys that have val (or anything equal as specified in 'eqFunc') as value.
     * @method getKeysForValue
     * @param val {mixed}
     * @param [equalityFunction] {Function}
     * This optional function can overwrite the test for equality between values. This function expects the parameters ('value' and the current value in the value iteration). If this parameters is omitted '===' is used.
     * @return {mixed}
    *###
    getKeysForValue: (value, eqFunc) ->
        if not eqFunc?
            idxs = (idx for val, idx in @values when @equality(val, value) or val is value)
        else
            idxs = (idx for val, idx in @values when eqFunc(val, value) is true)

        return (@keys[idx] for idx in idxs)

    empty: () ->
        @keys   = []
        @values = []
        return @

    remove: (key) ->
        idx = @keys.indexOf key
        if idx >= 0
            @keys.splice idx, 1
            @values.splice idx, 1
        else
            console.warn "Could not remove key '#{key}'!"
        return @

    each: (callback) ->
        for key, i in @keys
            if callback(key, @values[i], i) is false
                return @
        return @
