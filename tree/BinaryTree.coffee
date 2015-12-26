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
                    return @children[0]
                set: (node) ->
                    @children[0] = node
                    return @
            right:
                get: () ->
                    return @children[1]
                set: (node) ->
                    @children[1] = node
                    return @
        }

    addChild: (node, adjustLevels) ->
        if not isTree(node)
            node = new @constructor(node)

        # node already exists
        relation = @compareNodes(@, node)
        if relation is 0
            return @

        if relation < 0
            if @left?
                @left.addChild node, adjustLevels
            else
                @left = node
                node.parent = @
        else
            if @right?
                @right.addChild node, adjustLevels
            else
                @right = node
                node.parent = @

        if adjustLevels
            node._adjustLevels @level + 1
        return @

    moveTo: () ->
        throw new Error()
