# THE FOLLOWING 2 METHODS MUST BE ON TOP!!!!

# this is really really black magic...even Lord Voldemort is scared
# http://stackoverflow.com/questions/5916900/detect-version-of-browser

window.getBrowserAndVersion = () ->
    ua = navigator.userAgent
    M = ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) or []
    if /trident/i.test(M[1])
        tem = /\brv[ :]+(\d+)/g.exec(ua) or []
        # return "IE " + (tem[1] || "")
        return {
            browser: "IE"
            version: parseFloat(tem[1]) or 0
        }

    if M[1] is "Chrome"
        tem = ua.match(/\bOPR\/(\d+)/)
        if tem?
            # return "Opera " + tem[1]
            return {
                browser: "Opera"
                version: parseFloat(tem[1])
            }

    M = if M[2] then [M[1], M[2]] else [navigator.appName, navigator.appVersion, "-?"]
    if (tem = ua.match(/version\/(\d+)/i))?
        M.splice(1, 1, tem[1])

    return {
        browser: M[0]
        version: parseFloat(M[1])
    }

window.xml2Str = (xmlNode) ->
    if xmlNode instanceof jQuery
        xmlNode = xmlNode.get(0)

    if xmlNode instanceof Object
        if XMLSerializer
            o = new XMLSerializer()
            if o.serializeToString
                return (new XMLSerializer()).serializeToString(xmlNode)
            return false
        else if /MSIE (\d+\.\d+);/.test(navigator.userAgent)
            return xmlNode.xml

    return false

window.prefix = do () ->
    styles = window.getComputedStyle(document.documentElement, '')
    pre = (Array.prototype.slice
        .call(styles)
        .join('')
        .match(/-(moz|webkit|ms)-/) or (styles.OLink is '' and ['', 'o'])
    )[1]
    dom = ('WebKit|Moz|MS|O').match(new RegExp('(' + pre + ')', 'i'))[1]
    return {
        dom: dom
        lowercase: pre
        css: '-' + pre + '-'
        js: pre[0].toUpperCase() + pre.substr(1)
    }

window.zip = () ->
    args = argsToArray arguments

    # last element is a function => use that for getting the array of the objects in args
    if (last = args.last) instanceof Function
        getArray = last
        args = args.slice(0, -1)
    else
        getArray = (array) -> array

    # map each object to its array
    arrays = (getArray(item) for item in args)

    longest = null
    for array in arrays when longest is null or array.length > longest.length
        longest = array
    return ((array[i] for array in arrays) for item, i in longest)

window.getById = (id) ->
    return document.getElementById id

window.get$ById = (id) ->
    return $ getById(id)

window.getRandomInt = (min, max) ->
    return Math.floor(Math.random() * (max - min + 1)) + min

window.repeat = (iterable, cycles) ->
    l = []
    if cycles < 1
        return []
    for i in [0..(cycles - 1)]
        for elem in iterable
            l.push(elem)
    return l

window.all = (iterable) ->
    # return true iff all elements of iterable are true-ish
    result = true
    (result = false) for element in iterable when not element
    return result

window.any = (iterable) ->
    # return true iff any element of iterable is true-ish
    for element in iterable
        if element
            return true
    return false

window.utf8ToBase64 = (utf8) ->
    return base64js.fromByteArray(TextEncoderLite.encode(utf8))

window.base64ToUtf8 = (base64) ->
    return TextDecoderLite.decode(base64js.toByteArray(base64))
