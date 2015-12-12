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

# Makes a given DIV sortable and scrollable by arrows. It is assumed that the outer div contains li elements that are to be dragged. The created structure is
# <OUTERDIV>
#    <div class="$arrowClass left"></div>
#    <div class="$arrowClass right"></div>
#    <div class="sortableContainer">
#        <ul class="sortable">
#            ORIGINAL CONTENT
#        </ul>
#    </div>
# </OUTERDIV>
# Parameters:
#    outerDiv
#    sortableOptions        Object of options that are passed to the sortable() function
# Returns the new outerDiv
$.fn.makeSortable = (childrensWidth, containerClass = "sortableContainer", sortableOptions = {}, animOptions, arrowClass = "scroll") ->
    arrowLeft    = $("<div class=\"#{arrowClass} left disabled\"></div>")
    arrowRight    = $("<div class=\"#{arrowClass} right\"></div>")

    @children().wrapAll("<div class=\"#{containerClass}\"><ul class=\"sortable\"></ul></div>")
    @prepend(arrowLeft).prepend(arrowRight)

    # set containment (which should be the div with the container class unless differently set)
    if not sortableOptions.containment? or sortableOptions.containment is ""
        sortableOptions.containment = ".#{containerClass}"

    @find(".sortable").sortable(sortableOptions)

    self = @
    arrowLeft.click () ->
        if not $(@).hasClass("disabled")
            GUI.doScroll(true, self.find(".#{containerClass}"), childrensWidth, animOptions)
    arrowRight.click () ->
        if not $(@).hasClass("disabled")
            GUI.doScroll(false, self.find(".#{containerClass}"), childrensWidth, animOptions)

    return @

# Makes a given DIV scrollable by mouse wheel
$.fn.makeScrollable = (childrensWidth) ->
    @mousewheel (ev, delta, deltaX, deltaY)    =>
        if not @queue("fx").length
            # determine the direction to scroll into:
            # user scrolled horizontally
            if deltaX isnt 0
                str = "+=#{deltaX}px"
                dir = "left"
                if deltaX > 0
                    dir = "right"
            # user scrolled vertically
            else if deltaY isnt 0
                str = "-=#{deltaY}px"
                dir = "left"
                if deltaY < 0
                    dir = "right"

            inBounds = GUI.scrollingBounds(@, childrensWidth)

            if inBounds[dir]
                @animate    scrollLeft: str,
                            0,
                            "linear"

        return false # prevent default scrolling on page

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



#######################
# $.Color prototyping #
#######################

$.Color.fn.distanceTo = (color, distFunc) ->
    # define default function for distance calculation
    if not distFunc?
        distFunc = (c1, c2) ->
            return Math.abs(c1.red() - c2.red()) + Math.abs(c1.green() - c2.green()) + Math.abs(c1.blue() - c2.blue())

    return distFunc(@, color)

$.Color.fn.isSimilarTo = (color) ->
    return @distanceTo(color) / 255 < (1 - 1 / 1.61803398875)


# $.Color.fn.toRgbStringOld = $.Color.fn.toRgbaString.clone()
$.Color.fn.toRgbaString = () ->
    return "rgba(" + @_rgba.join(",") + ")"
