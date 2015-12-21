isTree = (obj) ->
    return obj instanceof JSUtils.Tree or obj?.__instanceof__?(JSUtils.Tree) or false

class JSUtils.Tree

    CLASS = @

    ###*
    * @method new
    * @static
    * @param node {Object}
    * @param options {Object}
    * Optional. Any given key will override the default. Here are the keys:
    * adjustLevels: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to false if you're doing the aftermath later!!
    * afterInstantiate: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    * getChildren: Function that specifies how to retrieve the children from the node object.
    * getParent: Function that specifies how to retrieve the parent from the node object. getChildren is checked 1st so it doesn't make sense to pass getChildren AND getParent!
    * instantiate: Function that specifies how to create an instance from the node object. Parameter is the node object.
    *###
    @new = (node, options) ->
        CLASS = @
        if not node? or isTree(node)
            return new CLASS(node)

        if node.children?
            return CLASS.new.byChildRef(node)

        if node.parent?
            return CLASS.new.byParentRef(node)

        if options?
            if options.getChildren?
                return CLASS.new.byChildRef(node, options)
            if options.getParent?
                return CLASS.new.byParentRef(node, options)

        if DEBUG
            console.warn "No recursive structure found! Use correct options."

        return null

    ###*
    * @method new.byChildRef
    * @static
    * @param node {Object}
    * @param options {Object}
    * Optional. Any given key will override the default. Here are the keys:
    * adjustLevels: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to false if you're doing the aftermath later!!
    * afterInstantiate: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    * getChildren: Function that specifies how to retrieve the children from the node object.
    * instantiate: Function that specifies how to create an instance from the node object. Parameter is the node object.
    *###
    @new.byChildRef = (node, options) ->
        defaultOptions =
            getChildren: (nodeData) ->
                return nodeData.children
            instantiate: (nodeData) ->
                return new CLASS(nodeData)
            afterInstantiate: (nodeData, node) ->
                return false
            adjustLevels: true
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

    ###*
    * @method new.byParentRef
    * @static
    * @param node {Object}
    * @param options {Object}
    * Optional. Any given key will override the default. Here are the keys:
    * adjustLevels: Boolean value that indicates whether the tree is supposed to do its aftermath. Only set this to false if you're doing the aftermath later!!
    * afterInstantiate: Function to modify the node and/or the instance. Parameters are (1st) the node object and (2nd) the instance.
    * getParent: Function that specifies how to retrieve the parent from the node object.
    * instantiate: Function that specifies how to create an instance from the node object. Parameter is the node object.
    *###
    # TODO !!!
    @new.byParentRef = (node, getParent) ->
        tree = new CLASS()

    @fromRecursive = @new

    ##################################################################################################
    ##################################################################################################
    # CONSTRUCTOR
    constructor: (node) ->
        self = @

        @children = []
        @parent = null
        @descendants = []
        @orderMode = "postorder"

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
    _cacheDescendants: () ->
        res = []
        for child in @children
            child._cacheDescendants()
            res = res.concat child.descendants

        @descendants = @children.concat res
        return @

    _adjustLevels: (startLevel = 0) ->
        @_cacheDescendants().each (n, l, i) ->
            n._level = startLevel + l
            return true
        return @

    ##################################################################################################
    # INFORMATION ABOUT THE TREE
    equals: (tree, compareLeaves = (a, b) -> a is b) ->
        if @children.length > 0
            if @children.length isnt tree.children.length or @descendants.length isnt tree.descendants.length
                return false

            # create list for comparing (it will be modified)
            # TODO remove array proto dependency
            otherChildren = tree.children.clone()

            for myChild in @children
                match = false
                for otherChild, idx in otherChildren when myChild.equals(otherChild)
                    match = true
                    break

                if not match
                    return false

                # else: found equal otherChild => remove equal children from both lists
                otherChildren.splice(idx, 1)
            return true
        # else: no children => leaf => compare differently
        if compareLeaves instanceof Function
            return compareLeaves(@, tree)
        return true

    hasNode: (node) ->
        return @ is node or node in @descendants

    ###*
    * Find (first occurence of) a node
    * @method findNode
    * @param equalsFunction {Function}
    *###
    findNode: (filter) ->
        return @findNodes(filter)?.first or null

    findDescendant: () ->
        return @findNode.apply(@, arguments)

    ###*
    * Find all occurences of a node.
    * @method findNodes
    * @param equalsFunction {JSUtils.Tree}
    *###
    findNodes: (param) ->
        res = []
        # find by match criterea function
        if param instanceof Function
            res.push node for node in @descendants when param(node)
        # not found
        return res

    findDescendants: () ->
        return @findNodes.apply(@, arguments)

    getDepth: () ->
        if @children.length > 0
            maxLevel = null
            for descendant in @descendants when not maxLevel? or descendant.level > maxLevel
                maxLevel = descendant.level
            return maxLevel - @level
        return 0

    ###*
    * Get number of nodes in (sub)tree
    *###
    getSize: () ->
        return @descendants.length + 1

    getLevel: () ->
        return @_level

    getRoot: () ->
        if not (root = @parent)?
            return @

        while root.parent?
            root = root.parent

        return root

    getLeaves: () ->
        leaves = []
        for child in @children
            if child.children.length > 0
                leaves = leaves.concat child.getLeaves()
            else
                leaves.push child
        return leaves

    isLeaf: () ->
        return @children.length is 0

    ###*
    * Serialize the tree to a plain object.
    *###
    # doneNodes is carried along to prevent serializing circles
    serialize: (format, doneNodes = []) ->
        serializedChildren = []
        for child in @children when child not in doneNodes
            doneNodes.push child
            serializedChildren.push child.serialize(format, doneNodes)

        if not format?
            res = @data.serialize?() or JSON.parse(JSON.stringify(@data))
            res.children = serializedChildren
            return res
        return format(@, serializedChildren, @data.serialize?() or JSON.parse(JSON.stringify(@data)))

    deserialize: (data) ->
        tree = @constructor.new(data)
        @setChildren tree.children

        for key, val of data when key isnt "children"
            @[key] = val

        return @

    toObject: () ->
        return @serialize.apply(@, arguments)


    ##################################################################################################
    # NODE RELATIONS
    getSiblings: () ->
        # TODO remove array proto dependency
        return @parent?.children.except(@) or []

    getLevelSiblings: () ->
        self = @
        siblings = @getRoot().findNodes (node) ->
            return node.level is self.level and node isnt self
        return siblings or []

    getParent: () ->
        return @parent

    getChildren: () ->
        return @children

    pathToRoot: () ->
        res = [@]
        parent = @parent
        while parent?
            res.push parent
            parent = parent.parent
        return res

    pathFromRoot: () ->
        res = @pathToRoot()
        res.reverse()
        return res

    ##################################################################################################
    # MODIFYING THE TREE
    # this can also move nodes within the tree or between trees
    addChild: (node, index, adjustLevels = true) ->
        # if node not instanceof JSUtils.Tree and not node.__instanceof__?(JSUtils.Tree)
        if not isTree(node)
            node = new CLASS(node)

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

        # @descendants.push(node) is done in adjustLevels()
        if adjustLevels
            node._adjustLevels @level + 1

        return @

    appendChild: () ->
        return @addChild.apply(@, arguments)

    addChildren: (nodes, index, adjustLevels = true) ->
        # inverse for correct indices
        for node in nodes by -1 when node?
            @addChild node, index, false
        if adjustLevels
            @_adjustLevels @level
        return @

    appendChildren: () ->
        return @addChildren.apply(@, arguments)

    setChildren: (nodes, clone = false, adjustLevels = true) ->
        @children = []

        if clone
            nodes = (node?.clone() for node in nodes)

        for node in nodes
            @addChild node

        if adjustLevels
            @_adjustLevels @level
        return @

    moveTo: (targetParent, index, adjustLevels = true) ->
        @remove(false)
        targetParent.addChild @, index, adjustLevels
        return @

    appendTo: () ->
        return @moveTo.apply(@, arguments)

    remove: (adjustLevels = true) ->
        if @parent?
            # TODO remove array proto dependency
            @parent.children = @parent.children.except @
            @parent.descendants = @parent.descendants.except(@descendants.and(@))
            @parent = null
            if adjustLevels
                @_adjustLevels()
        return @

    removeChild: (param) ->
        if typeof param is "number" or param instanceof Number
            node = @children[param]
        else
            node = param
        if node in @children
            node.remove()
        return @


    ##################################################################################################
    # TRAVERSING THE TREE
    ###*
    * @method _traverse
    * @param callback {Function}
    * Gets the current node, the current level relative to the root of the current traversal, and iteration index as parameters.
    * @param orderMode {String}
    * Optional. Default is "postorder". Possible are "postorder", "preorder", "inorder", "levelorder".
    * @param searchMode {String}
    * Optional. Default is "depthFirst". Posible are "depthFirst", "breadthFirst".
    *###
    _traverse: (callback, orderMode = @orderMode or "postorder", info = {idx: 0, ctx: @}) ->
        return @[orderMode](callback, null, info)

    each: () ->
        return @_traverse.apply(@, arguments)

    postorder: (callback, level = 0, info = {idx: 0, ctx: @}) ->
        for child in @children
            child.postorder(callback, level + 1, info)
            info.idx++

        if callback.call(info.ctx, @, level, info.idx) is false
            return @
        return @

    preorder: (callback, level = 0, info = {idx: 0, ctx: @}) ->
        if callback.call(info.ctx, @, level, info.idx) is false
            return @

        for child in @children
            child.preorder(callback, level + 1, info)
            info.idx++

        return @

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

    levelorder: (callback, level = 0, info = {idx: 0, ctx: @, levelIdx: 0}) ->
        list = [@]

        startLevel = @level
        prevLevel = 0

        while list.length > 0
            # remove 1st elem from list
            el = list.shift()

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
