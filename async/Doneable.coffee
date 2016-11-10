Object.defineProperties JSUtils, {
    Doneable: {
        get: () ->
            return new JSUtils.Sequence([])
        set: () ->
            return false
    }
}
