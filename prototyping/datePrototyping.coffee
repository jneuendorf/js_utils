Date.getCurrentYear = () ->
    return (new Date()).getFullYear()

Date::eliminateTime = () ->
    @setHours(0)
    @setMinutes(0)
    @setSeconds(0)
    @setMilliseconds(0)
    return @

Date::isValid = () ->
    if isNaN @getTime()
        return false

    return true

Date::getShortYear = () ->
    year = @getFullYear()
    year = ("" + year)
    return year[2] + year[3]

Date::getWeekNumber = () ->
    d = new Date(@getTime())
    d.setHours(0, 0, 0)
    d.setDate(d.getDate() + 4 - (d.getDay() or 7))
    return Math.ceil((((d-new Date(d.getFullYear(),0,1))/8.64e7)+1)/7)
