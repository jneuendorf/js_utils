class JSUtils.BinaryTree extends JSUtils.Tree

    @_newOptions: (CLASS) ->
        options = super(CLASS)
        options.instantiate = (nodeData, compareNodes) ->
            return new CLASS(nodeData, compareNodes)
        return options

    @_newByChildRef: (node, options) ->
        CLASS = @

        defaultOptions = CLASS._newOptions(CLASS)
        options = $.extend defaultOptions, options

        # cache value because it will be set to false for recursion calls
        adjustLevels = options.adjustLevels
        options.adjustLevels = false

        console.log node
        tree = options.instantiate node, options.compareNodes
        options.afterInstantiate node, tree

        for child in options.getChildren(node) or []
            childInstance = CLASS.new.byChildRef(child, options)
            tree.addChild(childInstance, false)

        if adjustLevels
            tree._adjustLevels 0

        return tree

    @init(@)

    # CONSTRUCTOR
    constructor: (node, compareNodes) ->
        if compareNodes not instanceof Function or compareNodes.length isnt 2
            throw new Error("BinaryTree::constructor: Invalid nodes compare function given!")

        super(node)

        # used to define an absolute order on the nodes
        @compareNodes = compareNodes

        Object.defineProperties @, {
            left:
                get: () ->
                    return @children[0] or null
                set: (node) ->
                    @children[0] = node
                    return @
            right:
                get: () ->
                    return @children[1] or null
                set: (node) ->
                    @children[1] = node
                    return @
        }

    balance: () ->
        # TODO
        return @

    # @Override

    # TODO: override findNodes for better performance

    addChild: (node, adjustLevels = true) ->
        if not isTree(node)
            node = new @constructor(node, @compareNodes)

        # console.log "adding child: #{node.n} to #{@n}"

        relation = @compareNodes(@, node)
        # node already exists
        if relation is 0
            return @

        # left
        if relation < 0
            if @left?
                @left.addChild node, adjustLevels
                return @
            else
                @left = node
                node.parent = @
        # right
        else
            if @right?
                @right.addChild node, adjustLevels
                return @
            else
                @right = node
                node.parent = @

        # @descendants.push(node)
        if adjustLevels
            @getRoot()._adjustLevels()
        return @

    addChildren: (nodes, adjustLevels) ->
        return super(nodes, null, adjustLevels)

    setChildren: () ->
        throw new Error("BinaryTree::setChildren: Children cannot be set. Use removeChild() and addChild()!")

    moveTo: () ->
        throw new Error("BinaryTree::moveTo: Cannot move a node!")
    appendTo: () ->
        throw new Error("BinaryTree::appendTo: Cannot move a node!")

    remove: (adjustLevels = true) ->
        if @parent?
            children = @parent.children
            if children[0] is @
                @parent.children = [null, children[1]]
            else
                @parent.children = [children[0], null]
            @parent._cacheDescendants()
            @parent = null
            if adjustLevels
                @_adjustLevels()
        return @

    deserialize: (data) ->
        tree = @constructor.new(data, {compareNodes: @compareNodes})
        @children = tree.children

        for key, val of data when key isnt "children"
            @[key] = val

        return @
