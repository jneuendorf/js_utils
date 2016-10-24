# JSUtils.Doneable = new JSUtils.Sequence()
# @todo this should be different...
Object.defineProperties JSUtils, {
    Doneable: {
        get: () ->
            return new App.Sequence([])
        set: () ->
            return false
    }
}
