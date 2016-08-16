# JSUtils.Doneable = new JSUtils.Sequence()
Object.defineProperties JSUtils, {
    Doneable: {
        get: () ->
            return new App.Sequence()
        set: () ->
            return false
    }
}
