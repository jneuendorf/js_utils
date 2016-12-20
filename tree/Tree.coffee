# This class is an implementation of a tree structure supporting an extended set of traversal and selection methods.
# Each node has a `data` object that is filled upon instantiation.
# All properties of that `data` object that are made accesible on the node directly (except if they would collide with class method names).
class JSUtils.Tree

    # This function checks if an object is an instance of the {JSUtils.Tree} class.
    # This should be overriden in case you have something like multi inheritance for example.
    # @param obj [mixed] The object to check for being an instance of {JSUtils.Tree}.
    # @return [Boolean] If `obj` is an instance of {JSUtils.Tree}
    @isTree: (obj) ->
        return obj instanceof @

    # This method creates the default options used when calling {JSUtils.Tree.new}.
    # @private
    # @param CLASS [JSUtils.Tree] The tree class (or a subclass).
    # @return [Object] The default instantiation options.
    @_newOptions: (CLASS) ->
        return {
            getChildren: (nodeData) ->
                return nodeData.children
            instantiate: (nodeData) ->
                return new CLASS(nodeData)
            afterInstantiate: (nodeData, node) ->
                return false
            adjustLevels: true
        }

    # @private
    # @param node [mixed] A {JSUtils.Tree} instance or data object (like in the constructor)
    # @param options [Object] Optional. Any given key will override the default. Here are the keys:
    #   `adjustLevels`: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to `false` if you do it later
    #   `afterInstantiate`: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    #   `getChildren`: Function that specifies how to retrieve the children from the node object.
    #   `getParent`: Function that specifies how to retrieve the parent from the node object. This is used only if `getChildren` is is not set
    #   `instantiate`: how to create an instance from the node object. Parameter is the node object.
    # @return [JSUtils.Tree] The new instance.
    @_new: (node, options) ->
        CLASS = @
        if not node? or CLASS.isTree(node)
            return new CLASS(node)

        if node.children? or options.getChildren instanceof Function
            return CLASS.new.byChildRef(node, options)

        if node.parent? or options.getParent instanceof Function
            return CLASS.new.byParentRef(node, options)

        return new CLASS(node, options)

    # @private
    # @param node [mixed] A {JSUtils.Tree} instance or data object (like in the constructor)
    # @param options [Object] Optional. Any given key will override the default. Here are the keys:
    #   `adjustLevels`: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to `false` if you do it later
    #   `afterInstantiate`: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    #   `getChildren`: Function that specifies how to retrieve the children from the node object.
    #   `instantiate`: how to create an instance from the node object. Parameter is the node object.
    # @return [JSUtils.Tree] The new instance.
    @_newByChildRef: (node, options) ->
        CLASS = @
        defaultOptions = CLASS._newOptions(CLASS)
        options = $.extend defaultOptions, options

        # cache value because it will be set to false for recursion calls
        adjustLevels = options.adjustLevels
        options.adjustLevels = false

        tree = options.instantiate node
        options.afterInstantiate node, tree

        for child in options.getChildren(node) or []
            childInstance = CLASS.new.byChildRef(child, options)
            tree.addChild(childInstance, null, false)

        if adjustLevels
            tree._adjustLevels 0

        return tree

    # @private
    # @param node [mixed] A {JSUtils.Tree} instance or data object (like in the constructor)
    # @param options [Object] Optional. Any given key will override the default. Here are the keys:
    #   `adjustLevels`: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to `false` if you do it later
    #   `afterInstantiate`: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    #   `getParent`: Function that specifies how to retrieve the parent from the node object. This is used only if `getChildren` is is not set
    #   `instantiate`: how to create an instance from the node object. Parameter is the node object.
    # @return [JSUtils.Tree] The new instance.
    # @todo This still needs to be implemented
    @_newByParentRef: (node, getParent) ->
        # TODO
        tree = new CLASS()

    # This method initializes the `new` class method.
    # The `new` class method has two properties itself: `byChildRef` and `byParentRef`.
    # Use that method to construct a new tree from an object with a tree structure.
    # Usually, the object has a `children` property which is used to create the hierarchy.
    # If you use `children` anyway you can also use `JSUtils.Tree.new.byChildRef()`.
    #
    # @example
    #   tree = JSUtils.Tree.new(
    #       {label: "root", children: [
    #           {...}, ...
    #       ]}
    #   )
    @init: () ->
        Object.defineProperty @, "new", {
            get: () ->
                CLASS = @
                f = () ->
                    return CLASS._new.apply(CLASS, arguments)
                f.byChildRef = () ->
                    return CLASS._newByChildRef.apply(CLASS, arguments)
                f.byParentRef = () ->
                    return CLASS._newByParentRef.apply(CLASS, arguments)
                return f
        }

        @fromRecursive = @new

    @init()


    ##################################################################################################
    # CONSTRUCTOR

    # Each {JSUtils.Tree} instance has the following read-only properties:
    #   `depth` same as `getDepth()`
    #   `size` same as `getSize()`
    #   `level` same as `getLevel()`
    #   `root` same as `getRoot()`
    # Additionally, all properties of the data object are made accesible on the node directly.
    # @overload constructor()
    #   Create a tree node without data.
    #   @param node [JSUtils.Tree] An instance of {JSUtils.Tree}
    #   @return [JSUtils.Tree] The new instance.
    # @overload constructor(data)
    #   Create a tree node with `data`.
    #   @param node [JSUtils.Tree] An instance of {JSUtils.Tree}
    #   @return [JSUtils.Tree] The new instance.
    # @overload constructor(treeNode)
    #   Create a tree node with the same data as `treeNode`.
    #   @param node [JSUtils.Tree] An instance of {JSUtils.Tree}
    #   @return [JSUtils.Tree] The new instance.
    constructor: (node) ->
        @children = []
        @parent = null
        @descendants = []
        @orderMode = "postorder"
        self = @

        if not node?
            @data = {}
        else
            # references the original object! if independency is wanted use $.extend([true,] {}, node)
            @data = node.data or node
            # create pseudo properties for directly accessing the node's data
            forbiddenKeys = Object.keys(@constructor.prototype).concat [
                "children", "parent", "descendants", "data", "orderMode"
                "getClass", "getClassName"
                "constructor"
            ]
            for k, v of node when k not in forbiddenKeys
                if v not instanceof Function
                    do (k, v) ->
                        Object.defineProperty self, k, {
                            get: () ->
                                return self.data[k]
                            set: (val) ->
                                self.data[k] = val
                                return self
                        }
                else
                    do (k, v) ->
                        self[k] = () ->
                            return v.call(node, arguments...)

    ##################################################################################################
    # READ-ONLY PROPERTIES
    Object.defineProperties @::, {
        depth:
            get: () ->
                return @getDepth()
            set: () ->
                return @
        size:
            get: () ->
                return @getSize()
            set: () ->
                return @
        level:
            get: () ->
                return @getLevel()
            set: () ->
                return @
        root:
            get: () ->
                return @getRoot()
            set: () ->
                return @
    }


    ##################################################################################################
    # INTERNAL

    # Cache all descendants of this node.
    # @private
    # @return [JSUtils.Tree] This instance.
    _cacheDescendants: () ->
        res = []
        for child in @children when child?
            child._cacheDescendants()
            res = res.concat child.descendants

        @descendants = @children.concat res
        return @

    # Set the correct level for all nodes in the tree.
    # @private
    # @return [JSUtils.Tree] This instance.
    _adjustLevels: (startLevel = 0) ->
        @_cacheDescendants().each (n, l, i) ->
            n._level = startLevel + l
            return true
        return @


    ##################################################################################################
    # INFORMATION ABOUT THE TREE

    # Indicates whether a node is within this subtree.
    # @return [Boolean] If the node is in the tree.
    hasNode: (node) ->
        return @ is node or node in @descendants

    # Find the first occurence of a node in the subtree that fulfills `filter`.
    # @param filter [Function] The function that defines when a node is matched. It gets the currently iterated tree node as argument.
    # @return [JSUtils.Tree] The matched node or `null`.
    findNode: (filter) ->
        return @findNodes(filter)?.first or null

    # Alias for {JSUtils.Tree#findNode}.
    # @param filter [Function] The function that defines when a node is matched. It gets the currently iterated tree node as argument.
    # @return [JSUtils.Tree] The matched node or `null`.
    findDescendant: () ->
        return @findNode.apply(@, arguments)

    # Find all nodes in the subtree that fulfill `filter`.
    # @param filter {Function} The function that defines when a node is matched. It gets the currently iterated tree node as argument.
    # @return [Array] An array of all matched nodes.
    findNodes: (filter) ->
        if filter instanceof Function
            return (node for node in @descendants when node? and filter(node))
        return []

    # Alias for {JSUtils.Tree#findNodes}.
    # @param filter {Function} The function that defines when a node is matched. It gets the currently iterated tree node as argument.
    # @return [Array] An array of all matched nodes.
    findDescendants: () ->
        return @findNodes.apply(@, arguments)

    # Get the depth of the subtree (meaning the distance from this node to the farthest descendant).
    # @return [Number] The depth.
    getDepth: () ->
        if @children.length > 0
            maxLevel = null
            for descendant in @descendants when descendant? and (not maxLevel? or descendant.level > maxLevel)
                maxLevel = descendant.level
            return maxLevel - @level
        return 0

    # Get number of nodes in subtree.
    # @return [Number] The size.
    getSize: () ->
        return (descendant for descendant in @descendants when descendant?).length + 1

    # Get the level of the node (meaning the distance to the root node).
    # @return [Number] The level.
    getLevel: () ->
        return @_level

    # Get root node of the tree.
    # @return [JSUtils.Tree] The root node.
    getRoot: () ->
        if not (root = @parent)?
            return @
        while root.parent?
            root = root.parent
        return root

    # Get all leaves of the subtree.
    # @return [Array] An array of tree leaves.
    getLeaves: () ->
        leaves = []
        for child in @children when child?
            if child.children.length > 0
                leaves = leaves.concat child.getLeaves()
            else
                leaves.push child
        return leaves

    # Indicate if this node is a leaf (meaning it has no children).
    # @return [Boolean] If this node is a leaf.
    isLeaf: () ->
        return @children.length is 0

    # Serialize the tree to a plain object or a string.
    # @param format [Function] Optional. This function can postprocess the current object before returning it.
    # @param doneNodes [Array] This list is carried along to prevent serializing circles.
    # @return [Object|String] The serialized tree.
    serialize: (format, doneNodes) ->
        serializedChildren = []
        for child in @children when child? and child not in doneNodes
            doneNodes.push child
            serializedChildren.push child.serialize(format, doneNodes) or {}
        return format(@, serializedChildren, @data.serialize?() or @data)

    # Alias for {JSUtils.Tree#serialize}.
    # @param toString [Boolean] Whether to return the result as a string.
    # @param format [Function] Optional. This function can postprocess the current object before returning it.
    # @param doneNodes [Array] This list is carried along to prevent serializing circles.
    # @return [Object|String] The serialized tree.
    toObject: () ->
        return @serialize.apply(@, arguments)

    # Deserialize a data object to this tree.
    # @param data [Object] The data object.
    # @return [JSUtils.Tree] This instance.
    deserialize: (data) ->
        tree = @constructor.new(data)
        @setChildren tree.children

        for key, val of data when key isnt "children"
            @[key] = val
        return @


    ##################################################################################################
    # NODE RELATIONS

    # Get all siblings of this node (meaning the parent's children without this node).
    # @return [Array] The siblings.
    getSiblings: () ->
        if @parent? and @parent.children.length > 0
            return (node for node in @parent.children when node isnt @)
        return []

    # Get all siblings of this node across the entire tree (meaning all nodes in the tree with the same level).
    # @return [Array] The siblings.
    getLevelSiblings: () ->
        self = @
        siblings = @getRoot().findNodes (node) ->
            return node.level is self.level and node isnt self
        return siblings or []

    # Get the parent of this node.
    # @return [JSUtils.Tree] This parent or `null`.
    getParent: () ->
        return @parent

    # Get the (direct) children of this node.
    # @return [Array] The children.
    getChildren: () ->
        return @children

    # Get all descendants of this node (meaning all nodes in the subtree without this node).
    # @return [Array] This descendants.
    getDescendants: () ->
        return @descendants

    # Get a list of nodes from this node to the root.
    # @return [Array] This path to the root.
    pathToRoot: () ->
        res = [@]
        parent = @parent
        while parent?
            res.push parent
            parent = parent.parent
        return res

    # Get a list of nodes from the root to this node.
    # @return [Array] This path from the root.
    pathFromRoot: () ->
        res = @pathToRoot()
        res.reverse()
        return res

    # Find the closest parent that matches `filter`.
    # @param filter [Function] The function that decides what parent is matches.
    # @return [JSUtils.Tree] The matched parent or `null`.
    closest: (filter) ->
        for ancestor in @pathToRoot().slice(1) when filter(ancestor)
            return ancestor
        return null

    ##################################################################################################
    # MODIFYING THE TREE

    # Add a node as child of this node.
    # This can also move nodes within the tree or between trees (if the node was attached somewhere else before).
    # @param node [mixed] A tree node or a data object (just like using the constructor).
    # @param index [Number] Optional. The index where to insert the node. If no index is given the child will be appended.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    addChild: (node, index, adjustLevels = true) ->
        if not @constructor.isTree(node)
            node = new @constructor(node)

        # node is attached somewhere else => correctly move between (sub)trees
        if node.parent? and node.parent isnt @
            # this will call @addChild again but the parent of the node is gone!
            node.moveTo(@, index)
            return @

        if not index?
            @children.push node
        else
            @children.splice index, 0, node

        node.parent = @
        # TODO: isn't it enough to just adjust the levels of the new node?
        if adjustLevels
            @getRoot()._adjustLevels()
        return @

    # Alias for {JSUtils.Tree#addChild}.
    # @param node [mixed] A tree node or a data object (just like using the constructor).
    # @param index [Number] Optional. The index where to insert the node. If no index is given the child will be appended.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    appendChild: () ->
        return @addChild.apply(@, arguments)

    # Add multiple nodes as children of this node.
    # This can also move nodes within the tree or between trees (if a node was attached somewhere else before).
    # @param nodes [Array] An array containing tree nodes or data objects (just like using the constructor).
    # @param index [Number] Optional. The index where to insert the node. If no index is given the child will be appended.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    addChildren: (nodes, index, adjustLevels = true) ->
        if index?
            # inverse for correct indices (due to splice at index)
            nodes.reverse()
        for node in nodes when node?
            @addChild node, index, false
        if adjustLevels
            # TODO: see TODO in addChild()
            @_adjustLevels @level
        return @

    # Alias for {JSUtils.Tree#addChildren}.
    # @param nodes [Array] An array containing tree nodes or data objects (just like using the constructor).
    # @param index [Number] Optional. The index where to insert the node. If no index is given the child will be appended.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    appendChildren: () ->
        return @addChildren.apply(@, arguments)

    # Set the children of this node (discarding the previous ones).
    # @param nodes [Array] An array containing tree nodes or data objects (just like using the constructor).
    # @param clone [Boolean] Optional. Whether to clone the nodes before using them as children.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    setChildren: (nodes, clone = false, adjustLevels = true) ->
        @children = []

        if clone
            nodes = (node.clone?() for node in nodes when node?)

        for node in nodes
            @addChild node

        if adjustLevels
            @_adjustLevels @level
        return @

    # Moves this node to a new parent.
    # @param targetParent [JSUtils.Tree] The new parent.
    # @param index [Number] Optional. The index where to insert this node among the parent's children.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    moveTo: (targetParent, index, adjustLevels = true) ->
        @remove(false)
        targetParent.addChild @, index, adjustLevels
        return @

    # Alias for {JSUtils.Tree#moveTo}.
    # @param targetParent [JSUtils.Tree] The new parent.
    # @param index [Number] Optional. The index where to insert this node among the parent's children.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    appendTo: () ->
        return @moveTo.apply(@, arguments)

    # Removes this node (and the whoel subtree) from its parent.
    # @param adjustLevels [Boolean] Optional. Whether to make sure the levels of all nodes (i.e. the newly inserted ones) are correct.
    # @return [JSUtils.Tree] This instance.
    remove: (adjustLevels = true) ->
        if @parent?
            @parent.children = (child for child in @parent.children when child isnt @)
            @parent._cacheDescendants()
            @parent = null
            if adjustLevels
                @_adjustLevels()
        return @

    # Removes a child from this node.
    # @overload removeChild(index)
    #   Removes the child at `index`.
    #   @param index [Number] The index specifying the child to remove.
    #   @return [JSUtils.Tree] This instance.
    # @overload removeChild(filter)
    #   Removes the child that fulfills `filter`.
    #   @param filter [Function] A function defining what child node to remove.
    #   @return [JSUtils.Tree] This instance.
    # @overload removeChild(node)
    #   Removes `node` form the children (if it is a child).
    #   @param node [JSUtils.Tree] A tree node.
    #   @return [JSUtils.Tree] This instance.
    removeChild: (param) ->
        if typeof param is "number" or param instanceof Number
            node = @children[param]
        else if param instanceof Function
            node = (node for node in @children when param(node))[0]
        else
            node = param
        if node? and node in @children
            node.remove()
        return @


    ##################################################################################################
    # TRAVERSING THE TREE

    # Traverses the tree calling `callback` for every visisted node.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param orderMode [String] Optional. Default is "postorder". Possible are "postorder", "preorder", "inorder", "levelorder".
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    traverse: (callback, orderMode = @orderMode or "postorder", info = {idx: 0, ctx: @}) ->
        return @[orderMode](callback, null, info)

    # Alias for {JSUtils.Tree#traverse}
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param orderMode [String] Optional. Default is "postorder". Possible are "postorder", "preorder", "inorder", "levelorder".
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    each: () ->
        return @traverse.apply(@, arguments)

    # Shortcut for `tree.each(callback, "postorder")`.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param level [Number] This parameter should not be used. It is used to provide the correct relative level to the callback.
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    postorder: (callback, level = 0, info = {idx: 0, ctx: @}) ->
        for child in @children when child?
            child.postorder(callback, level + 1, info)
            info.idx++
        if callback.call(info.ctx, @, level, info.idx) is false
            return @
        return @

    # Shortcut for `tree.each(callback, "preorder")`.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param level [Number] This parameter should not be used. It is used to provide the correct relative level to the callback.
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    preorder: (callback, level = 0, info = {idx: 0, ctx: @}) ->
        if callback.call(info.ctx, @, level, info.idx) is false
            return @
        for child in @children when child?
            child.preorder(callback, level + 1, info)
            info.idx++
        return @

    # Shortcut for `tree.each(callback, "inorder")`.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param level [Number] This parameter should not be used. It is used to provide the correct relative level to the callback.
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    inorder: (callback, level = 0, index = @children.length // 2, info = {idx: 0, ctx: @}) ->
        for i in [0...index]
            @children[i]?.inorder(callback, level + 1, index, info)
            info.idx++
        if callback.call(info.ctx, @, level, info.idx) is false
            return @
        for i in [index...@children.length]
            @children[i]?.inorder(callback, level + 1, index, info)
            info.idx++
        return @

    # Shortcut for `tree.each(callback, "levelorder")`.
    # @param callback [Function] The callback gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters. In the callback `this` refers to the root of traversal. Returning `false` causes the traversal to stop.
    # @param level [Number] This parameter should not be used. It is used to provide the correct relative level to the callback.
    # @param info [Object] This parameter should not be used. It is used primarily to provide the correct index to the callback.
    # @return [JSUtils.Tree] This instance.
    levelorder: (callback, level = 0, info = {idx: 0, ctx: @, levelIdx: 0}) ->
        list = [@]
        startLevel = @level
        prevLevel = 0

        while list.length > 0
            # remove 1st elem from list
            el = list.shift()
            # this is only in case any child is null. this is the case with binary trees
            if el?
                currentLevel = el.level - startLevel

                # going to new level => reset level index
                if currentLevel > prevLevel
                    info.levelIdx = 0
                if callback.call(info.ctx, el, currentLevel, info) is false
                    return @
                prevLevel = currentLevel
                info.idx++
                info.levelIdx++
                list = list.concat el.children
        return @
