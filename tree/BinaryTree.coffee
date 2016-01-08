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

    @init()

    # CONSTRUCTOR
    constructor: (node, compareNodes) ->
        if compareNodes?.compareNodes
            compareNodes = compareNodes.compareNodes
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
        CLASS = @constructor

        # get list of sorted nodes
        nodes = []
        @inorder (node) ->
            nodes.push node
            return true

        resetNodeRelations = (node) ->
            # node._level = 0
            node.children = []
            node.descendants = []
            node.parent = null
            return node

        index = nodes.length // 2
        root = nodes[index]
        resetNodeRelations(root)

        nodes = (n for n in nodes when n isnt root)

        insertNodes = (list) =>
            len = list.length
            if len is 0
                return true

            idx = len // 2
            # if list would be split into lists with sizes 2 and (5 or 6) -> use lists with sizes 3 and (4 or 5) instead
            # this results in a perfect(ly balanced) left subtree and a potentially better balanced right subtree
            if idx is 2
                idx++
            node = list[idx]
            # when we put the node into the tree that is current 'self' -> create new instance to avoid 'this.children' containing 'this'
            if node isnt @
                node = resetNodeRelations(node)
            else
                node = new CLASS(node.data, @compareNodes)

            root.addChild node, false
            insertNodes(list.slice(0, idx))
            insertNodes(list.slice(idx + 1))
            return true

        insertNodes(nodes.slice(0, index))
        insertNodes(nodes.slice(index + 1))

        @data = root.data
        @children = root.children
        @_adjustLevels()

        return @

    ################################################################################
    # @Override

    addChild: (node, adjustLevels = true) ->
        if not isTree(node)
            node = new @constructor(node, @compareNodes)

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

    inorder: (callback, level = 0, index = @children.length // 2, info = {idx: 0, ctx: @}) ->
        @left?.inorder(callback, level + 1, index, info)
        info.idx++

        if callback.call(info.ctx, @, level, info.idx) is false
            return @

        @right?.inorder(callback, level + 1, index, info)
        info.idx++

        return @
