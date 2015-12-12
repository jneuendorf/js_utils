# NOTE: idea from: http://stackoverflow.com/questions/10692100/invoke-a-callback-at-the-end-of-a-transition
d3.transition::done = (callback) ->
    # NOTE: d3.select(document.body).transition().__proto__ === d3.transition.prototype

    endAll = (transition) ->
        callback() if transition.size() is 0

        n = 0
        transition
            .each () ->
                ++n
                return true
            .each "end", () ->
                if not --n
                    callback.apply(@, arguments)
                return true

        return @

    return @call(endAll, callback)
