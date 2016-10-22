# This class implements a binary tree.
# Therefore, there is a function that compares nodes and decides which one of them is "smaller".
# Upon insert, the smaller node will be placed into the left subtree (recursively - when compared the current node in the tree).
class JSUtils.BinaryTree extends JSUtils.Tree

    # This method creates the default options used when calling {JSUtils.Tree.new}.
    # @private
    # @param CLASS [JSUtils.Tree] The tree class (or a subclass).
    # @return [Object] The default instantiation options.
    @_newOptions: (CLASS) ->
        options = super(CLASS)
        options.instantiate = (nodeData, compareNodes) ->
            return new CLASS(nodeData, compareNodes)
        return options

    # This is just like {JSUtils.Tree._newByChildRef} except it passes the `compareNodes` function to the `instantiate` callback.
    # @private
    # @param node [Object]
    # @param options [Object] Optional. Any given key will override the default. Here are the keys:
    #   `adjustLevels`: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to `false` if you do it later
    #   `afterInstantiate`: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    #   `getChildren`: Function that specifies how to retrieve the children from the node object.
    #   `instantiate`: how to create an instance from the node object. Parameter is the node object and the compare function.
    # @return [JSUtils.Tree] The new instance.
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


    ##################################################################################################
    # CONSTRUCTOR

    # The first parameter can have different types just like in {JSUtils.Tree.constructor}.
    # New is the second parameter which is the compare function (to decide how to insert nodes).
    # Each {JSUtils.BinaryTree} instance has the following read-only properties (in addition to what {JSUtils.Tree} provides):
    #   `left` the "smaller" child
    #   `right` the "greater or equal" child
    # @param node [mixed] The node parameter (for details see {JSUtils.Tree.constructor})
    # @param compareNodes [Function] The function used for finding the right place for a node when inserting one.
    # @return [JSUtils.BinaryTree] The new instance.
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

    # This method can be used to balance the tree (in place).
    # If possible the nodes will be rearranged to make the tree less deep.
    # All node relations will still be intact meaning that the left child is still "smaller" and the right on "greater or equal".
    # @return [JSUtils.BinaryTree] This instance.
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

    # This method inserts a node into this subtree.
    # Due to how an binary tree works it is possible that the new node will not be a child of the this node but a descendant instead.
    # @param node [mixed] A tree node or a data object (just like using the constructor).
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes are correct.
    # @return [JSUtils.BinaryTree] This instance.
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

    # Add multiple nodes to this subtree.
    # This is just a shortcut for calling `addChild()` multiple times.
    # @param nodes [Array] An array containing tree nodes or data objects (just like using the constructor).
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes are correct.
    # @return [JSUtils.BinaryTree] This instance.
    addChildren: (nodes, adjustLevels) ->
        return super(nodes, null, adjustLevels)

    # Children can't be directly set on BinaryTree nodes.
    # @throw [Error] Children cannot be set. Use removeChild() and addChild()!
    setChildren: () ->
        throw new Error("BinaryTree::setChildren: Children cannot be set. Use removeChild() and addChild()!")

    # Nodes can't be moved that way because the node relations might break.
    # @throw [Error] Cannot move a node!
    moveTo: () ->
        throw new Error("BinaryTree::moveTo: Cannot move a node!")
    # Nodes can't be moved that way because the node relations might break.
    # @throw [Error] Cannot move a node!
    appendTo: () ->
        throw new Error("BinaryTree::appendTo: Cannot move a node!")

    # Removes this node from the tree.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes are correct.
    # @return [JSUtils.BinaryTree] This instance.
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

    # Just like {JSUtils.Tree#deserialize}.
    # @param data [Object] The data object.
    # @return [JSUtils.Tree] This instance.
    deserialize: (data) ->
        tree = @constructor.new(data, {compareNodes: @compareNodes})
        @children = tree.children
        for key, val of data when key isnt "children"
            @[key] = val
        return @

    # Just like {JSUtils.Tree#inorder}.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param level [Number] This parameter should not be used. It is used to provide the correct relative level to the callback.
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.BinaryTree] This instance.
    inorder: (callback, level = 0, index = @children.length // 2, info = {idx: 0, ctx: @}) ->
        @left?.inorder(callback, level + 1, index, info)
        info.idx++
        if callback.call(info.ctx, @, level, info.idx) is false
            return @
        @right?.inorder(callback, level + 1, index, info)
        info.idx++
        return @
