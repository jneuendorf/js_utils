# @nodoc
# This function finds an object for a string like "obj.prop1.prop2" in the global namespace
getObjectFromPath = (path) ->
    parts = path.split "."
    res = window
    for part in parts
        res = res?[part]
    return res

for setName, set of prototyping
    parent = getObjectFromPath(setName)

    if not parent?
        continue

    # PREFER ALREADY IMPLEMENTED METHODS
    if not preferJSUtils
        for methodName, method of set
            if parent[methodName]?
                methodName = "_#{methodName}"
            if method instanceof Function
                Object.defineProperty parent, methodName, {
                    value: method
                    configurable: true
                    enumerable: false
                    writable: false
                }
            # assume given data is a property descriptor
            else
                Object.defineProperty parent, methodName, method
        # ALIASING
        if aliasing[setName]?
            for aliasName, methodName of aliasing[setName]
                if parent[aliasName]?
                    aliasName = "_#{aliasName}"
                parent[aliasName] = parent[methodName]
    # PREFER JSUTILS' METHODS
    else
        for methodName, method of set
            if parent[methodName]?
                parent["_#{methodName}"] = parent[methodName]

            if method instanceof Function
                Object.defineProperty parent, methodName, {
                    value: method
                    configurable: true
                    enumerable: false
                    writable: false
                }
                # assume given data is a property descriptor
            else
                Object.defineProperty parent, methodName, method
        # ALIASING
        if aliasing[setName]?
            for aliasName, methodName of aliasing[setName]
                if parent[aliasName]?
                    parent["_#{aliasName}"] = parent[aliasName]
                parent[aliasName] = parent[methodName]
