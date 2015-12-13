$.fn.content = (n)    ->
    # set method
    if n?
        if typeof n is "string"
            children = @children().detach()
            @empty().append(n).append(children)

        return @
    # get method
    else
        children = @children().detach()
        text = @text()
        @append(children)
        return text

# toggle either HTML or CSS attribute of a $Object; if toggle "fails" val1 is set
$.fn.toggleAttr = (attr, val1, val2, css) ->
    for elem in @
        if css is true
            if $(elem).css(attr) is val1
                $(elem).css(attr, val2)
            else
                $(elem).css(attr, val1)
        else
            if $(elem).attr(attr) is val1
                $(elem).attr(attr, val2)
            else
                $(elem).attr(attr, val1)
    return @

$.fn.dimensions = () ->
    return {
        x: parseInt @width(), 10
        y: parseInt @height(), 10
    }

$.fn.outerDimensions = (margins = true) ->
    return {
        x: @outerWidth margins
        y: @outerHeight margins
    }

$.fn.showFast = (display = "block") ->
    @[0].style.display = display
    return @

$.fn.hideFast = () ->
    @[0].style.display = "none"
    return @

# Checks whether the object is in the DOM or not
$.fn.inDom = () ->
    return $.contains(document.documentElement, @[0])

# Override jQuery's .wrapAll() function in order to also work for element that are NOT (yet) attached to the DOM
oldWrapAll = $.fn.wrapAll
$.fn.wrapAll = (wrapper) ->
    # the element is in the DOM => call jQuery's function
    if @inDom()
        return oldWrapAll.call(@, wrapper)
    # now we've gotta do it ourselves!
    else
        # make sure wrapper is a jQuery object
        if wrapper not instanceof $
            wrapper = $ wrapper
        # this is the wrapping
        wrapper.append @
        return @

# intended to match naming in prototyping.coffee (see "Element" section)
$.fn.appendLog = (args..., trackingList) ->
    @append(args...)
    trackingList = trackingList.push(args...)
    return @



##############################################
# $.Color prototyping

$.Color.fn.distanceTo = (color, distFunc) ->
    # define default function for distance calculation
    if not distFunc?
        distFunc = (c1, c2) ->
            return Math.abs(c1.red() - c2.red()) + Math.abs(c1.green() - c2.green()) + Math.abs(c1.blue() - c2.blue())

    return distFunc(@, color)

$.Color.fn.isSimilarTo = (color) ->
    return @distanceTo(color) / 255 < (1 - 1 / 1.61803398875)


# @Override
$.Color.fn.toRgbaString = () ->
    return "rgba(" + @_rgba.join(",") + ")"
