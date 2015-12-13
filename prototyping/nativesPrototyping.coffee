########################################################################################
########################################################################################
# MATH

Math.sign = (n) ->
    if n?
        if n < 0
            return -1
        return 1
    return 0

Math.isNum = (n) ->
    return n? and isFinite(n)

Math.average = (vals...) ->
    if vals[0] instanceof Array
        vals = vals[0]

    sum = 0
    elems = 0
    for elem in vals when Math.isNum(elem)
        sum += elem
        elems++
    return sum / elems

Math.log10 = (x) ->
    if x? and x > 0
        return Math.log(x) / Math.LN10
    return undefined

# round to significant
# roundToSig: Number (x Number) -> Number
Math.roundToSig = (num, digits) ->
    return parseFloat(num.toPrecision(digits))

Math.toSig = (num, digits, separator = "") ->
    rounded = Math.roundToSig(num, digits)

    # digits of rounded number = floor(log10(rounded)) + 1
    # roundedDigits = ~~Math.log10(rounded) + 1
    roundedDigits = "#{rounded}".replace("\.", "").length

    # no enough digits or decimal places
    if roundedDigits < digits or ~~rounded isnt rounded
        format = "0.#{("0" for i in [0...Math.abs(digits - roundedDigits)]).join("")}"
    # enough digits and no decimal places
    else
        format = "0"

    return numeral(rounded).format(format)


########################################################################################
########################################################################################
# FUNCTION

# inline javascript from https://gist.github.com/Sykkro/7490193
`Function.prototype.clone = function() {
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

# not in-place!
Object.except = (obj, keys...) ->
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

Object.values = (obj) ->
    if DEBUG
        if obj not instanceof Object
            throw new Error("Called non-object: #{obj}")

    res  = []
    for k, v of obj
        res.push v
    return res

Object.values = (obj) ->
    if DEBUG
        if obj not instanceof Object
            throw new Error("Called non-object: #{obj}")

    return (val for key, val of obj)

Object.swapKeys = (obj, keys...) ->
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

if not Element::remove?
    Element::remove = () ->
        return @parentNode.removeChild(@)
