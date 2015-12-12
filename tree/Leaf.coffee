class App.Leaf extends App.Tree

    CLASS = @

    @new = (node) ->
        return new @(node)

    ##################################################################################################
    ##################################################################################################
    # CONSTRUCTOR
    constructor: (node) ->
        super(node)
        delete @children
        Object.defineProperty @, "children", {
            get: () ->
                return []
            set: () ->
                throw new Error("App.Leaf::children=: Cannot set children of a leaf!")
        }

    ##################################################################################################
    # READ-ONLY PROPERTIES

    ##################################################################################################
    # INTERNAL
    _cacheDescendants: () ->
        return @

    ##################################################################################################
    # INFORMATION ABOUT THE TREE
    findNodes: (param) ->
        return null

    getDepth: () ->
        return 0

    getSize: () ->
        return 0

    getLevel: () ->
        return @_level

    getLeaves: () ->
        return []

    isLeaf: () ->
        return true

    serialize: (format) ->
        if not format?
            return {
                children: []
                data: @data.serialize?() or JSON.parse(JSON.stringify(@data))
            }
        return format(@, [], @data.serialize?() or JSON.parse(JSON.stringify(@data)))

    deserialize: (data) ->
        @data = data
        return @

    ##################################################################################################
    # NODE RELATIONS
    getChildren: () ->
        return []

    ##################################################################################################
    # MODIFYING THE TREE
    addChild: () ->
        throw new Error("App.Leaf::addChild: Cannot add a child to a leaf!")

    addChildren: () ->
        throw new Error("App.Leaf::addChildren: Cannot add children to a leaf!")

    setChildren: () ->
        throw new Error("App.Leaf::setChildren: Cannot set children of a leaf!")

    removeChild: () ->
        throw new Error("App.Leaf::removeChild: Cannot remove children of a leaf!")

    removeChildAt: (idx) ->
        throw new Error("App.Leaf::removeChildAt: Cannot remove children of a leaf!")

    adjustLevels: () ->
        return @
