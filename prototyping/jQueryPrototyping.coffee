prototyping["$.fn"] =
    content: (content) ->
        # set method
        if content?
            if typeof content is "string"
                children = @children().detach()
                @empty().append(content).append(children)

            return @
        # get method
        else
            children = @children().detach()
            text = @text()
            @append(children)
            return text.trim()
    # toggle either HTML attribute of a $Object; if toggle "fails" val1 is set
    toggleAttr: (attr, val1, val2) ->
        for elem in @
            $elem = $(elem)
            if val1? and val2?
                $elem.attr("data-toggle-attr-#{attr}-val1", val1)
                $elem.attr("data-toggle-attr-#{attr}-val2", val2)
            else
                val1 = $elem.attr("data-toggle-attr-#{attr}-val1")
                val2 = $elem.attr("data-toggle-attr-#{attr}-val2")

            if $elem.attr(attr) is val1
                $elem.attr(attr, val2)
            else
                $elem.attr(attr, val1)
        return @
    toggleCss: (attr, val1, val2) ->
        for elem in @
            $elem = $(elem)
            if val1? and val2?
                $elem.attr("data-toggle-css-#{attr}-val1", val1)
                $elem.attr("data-toggle-css-#{attr}-val2", val2)
            else
                val1 = $elem.attr("data-toggle-css-#{attr}-val1")
                val2 = $elem.attr("data-toggle-css-#{attr}-val2")

            if $elem.css(attr) is val1
                $elem.css(attr, val2)
            else
                $elem.css(attr, val1)
        return @
    dimensions: () ->
        res =
            x: @width()
            y: @height()
        res.width = res.x
        res.height = res.y
        return res
    outerDimensions: (margins = true) ->
        res =
            x: @outerWidth margins
            y: @outerHeight margins
        res.width = res.x
        res.height = res.y
        return res
    showNow: (display = "block") ->
        @[0].style.display = display
        return @
    hideNow: () ->
        @[0].style.display = "none"
        return @
    # Checks whether the object is in the DOM or not
    inDom: () ->
        return $.contains(document.documentElement, @[0])
    # Override jQuery's .wrapAll() function in order to also work for element that are NOT (yet) attached to the DOM
    wrapAll: (wrapper) ->
        # make sure wrapper is a jQuery object
        if wrapper not instanceof $
            wrapper = $ wrapper
        # this is the wrapping
        wrapper.append @
        return @

##############################################
# $.Color prototyping
prototyping["$.Color.fn"] =
    distanceTo: (color, distFunc) ->
        # define default function for distance calculation
        if not distFunc?
            distFunc = (c1, c2) ->
                return Math.abs(c1.red() - c2.red()) + Math.abs(c1.green() - c2.green()) + Math.abs(c1.blue() - c2.blue())

        return distFunc(@, color)

    isSimilarTo: (color) ->
        return @distanceTo(color) / 255 < (1 - 1 / 1.61803398875)

    # @Override
    toRgbaString: () ->
        return "rgba(#{@_rgba.join(",")})"
