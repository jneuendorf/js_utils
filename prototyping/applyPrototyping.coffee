for setName, set of prototyping
    if setName[setName.length - 1] is ":"
        parent = window[setName.slice(0, -2)].prototype
    else
        parent = window[setName]

    # PREFER ALREADY IMPLEMENTED METHODS
    if not preferJSUtils
        for methodName, method of set
            if parent[methodName]?
                methodName = "_#{methodName}"
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
                    configurable: false
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
