########################################################################################
########################################################################################
# MATH
prototyping["Math"] =
    isNum: (n) ->
        return n? and (typeof n is "number" or n instanceof Number) and isFinite(n)
    average: (vals...) ->
        sum = 0
        elems = 0
        for elem in vals when Math.isNum(elem)
            sum += elem
            elems++
        return sum / elems
    sign: (n) ->
        if Math.isNum(n)
            if n < 0
                return -1
            if n > 0
                return 1
            return 0
        return undefined
    log10: (x) ->
        if Math.isNum(x) and x > 0
            return Math.log(x) / Math.LN10
        return undefined


########################################################################################
########################################################################################
# FUNCTION
# inline javascript from https://gist.github.com/Sykkro/7490193
prototyping["Function::"] =
    # Function.prototype.clone = function() {
    clone: `function() {
        var that = this;
        var temp = function temporary() { return that.apply(this, arguments); };
        for( key in this ) {
            temp[key] = this[key];
        }
        return temp;
    }`


########################################################################################
########################################################################################
# OBJECT
prototyping["Object"] =
    # not in-place!
    except: (obj, keys...) ->
        if keys.first instanceof Array
            keys = keys.first

        # add keys from prototype. call Object.except(obj.__proto__) to apply .except to prototype
        keys = keys.concat Object.keys(obj.__proto__)

        res = {}
        for k, v of obj when k not in keys
            res[k] = v

        # also adjust prototype
        res.__proto__ = obj.__proto__
        return res

    values: (obj) ->
        if DEBUG
            if obj not instanceof Object
                throw new Error("Called non-object: #{obj}")

        return (val for key, val of obj)

    swapValues: (obj, keys...) ->
        if keys.length % 2 is 0
            for i in [0...keys.length] by 2
                key1 = keys[i]
                key2 = keys[i + 1]
                temp = obj[key1]
                obj[key1] = obj[key2]
                obj[key2] = temp
        return obj


########################################################################################
########################################################################################
# ELEMENT
prototyping["Element::"] =
    remove: () ->
        return @parentNode.removeChild(@)
