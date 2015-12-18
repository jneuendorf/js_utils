for setName, set of prototyping
    if setName[setName.length - 1] is ":"
        parent = window[setName.slice(0, -2)].prototype
    else
        parent = window[setName]

    for methodName, method of set when not parent[methodName]?
        # parent[methodName] = method
        if method instanceof Function
            Object.defineProperty parent, methodName, {
                value: method
                configurable: false
                enumerable: false
                writable: false
            }
        # assume given data is a property descriptor
        else
            Object.defineProperty parent, methodName, method
