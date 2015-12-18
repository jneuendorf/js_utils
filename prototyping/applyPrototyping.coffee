for setName, set of prototyping
    if setName[setName.length - 1] is ":"
        parent = window[setName.slice(0, -2)].prototype
    else
        parent = window[setName]

    if not preferJSUtils
        for methodName, method of set
            if parent[methodName]?
                methodName = "_#{methodName}"
            # if not parent[methodName]?
            #     # parent[methodName] = method
            #     if method instanceof Function
            #         Object.defineProperty parent, methodName, {
            #             value: method
            #             configurable: false
            #             enumerable: false
            #             writable: false
            #         }
            #     # assume given data is a property descriptor
            #     else
            #         Object.defineProperty parent, methodName, method
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
