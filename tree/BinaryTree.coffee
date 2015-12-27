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

        @_children = @children
        # used to define an absolute order on the nodes
        @compareNodes = compareNodes

        Object.defineProperties @, {
            children:
                get: () ->
                    if @_children[0]? and @_children[1]?
                        return [@_children[0], @_children[1]]
                    if not @_children[0]? and not @_children[1]?
                        return []

                    if not @_children[0]?
                        return [@_children[1]]
                    # if not @_children[1]?
                    return [@_children[0]]
                set: (children) ->
                    @_children = children
                    return @
            left:
                get: () ->
                    return @_children[0] or null
                set: (node) ->
                    @_children[0] = node
                    return @
            right:
                get: () ->
                    return @_children[1] or null
                set: (node) ->
                    @_children[1] = node
                    return @
        }

    balance: () ->

        return @

    # @Override

    addChild: (node, adjustLevels) ->
        if not isTree(node)
            node = new @constructor(node)

        console.log "adding child: #{node.n} to #{@n}"

        relation = @compareNodes(@, node)
        # node already exists
        if relation is 0
            return @

        # left
        if relation < 0
            if @left?
                @left.addChild node, adjustLevels
            else
                @left = node
                node.parent = @
        # right
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
