# This class is like {JSUtils.Tree} but with more constraints.
# The constraints are enforced by throwing errors on some inherited methods.
# E.g. there must be no children.
class JSUtils.Leaf extends JSUtils.Tree

    # Construct a new {JSUtils.Leaf} instance.
    # Since a leaf is not recursive there are neither `JSUtils.Leaf.new.byChildRef` nor `JSUtils.Leaf.new.byParentRef` methods.
    # @param node [mixed] A {JSUtils.Tree} instance or data object (like in the constructor)
    # @return [JSUtils.Leaf] This instance.
    @new = (node) ->
        return new @(node)


    ##################################################################################################
    # CONSTRUCTOR

    # See {JSUtils.Tree#constructor} for details.
    # @param node [mixed] A tree node or data object.
    # @return [JSUtils.Leaf] This new instance.
    constructor: (node) ->
        super(node)
        delete @children
        Object.defineProperty @, "children", {
            get: () ->
                return []
            set: () ->
                return @
        }


    ##################################################################################################
    # INTERNAL

    # This method does nothing since there are no descendants.
    # @private
    # @return [JSUtils.Leaf] This instance.
    _cacheDescendants: () ->
        return @


    ##################################################################################################
    # INFORMATION ABOUT THE TREE

    # See {JSUtils.Tree#findNodes} for details. Always `nulin this case.
    # @return [null] null.
    findNodes: (param) ->
        return null

    # See {JSUtils.Tree#getDepth} for details. Always `0` in this case.
    # @return [Number] 0.
    getDepth: () ->
        return 0

    # See {JSUtils.Tree#getSize} for details. Always `0` in this case.
    # @return [Number] 0.
    getSize: () ->
        return 0

    # See {JSUtils.Tree#getLevel} for details.
    # @return [Number] The level.
    getLevel: () ->
        return @_level

    # See {JSUtils.Tree#getLeaves} for details. Always `[]` in this case.
    # @return [Number] The leaves.
    getLeaves: () ->
        return []

    # See {JSUtils.Tree#isLeaf} for details. Always `true` in this case.
    # @return [Boolean] `true`.
    isLeaf: () ->
        return true

    # See {JSUtils.Tree#deserialize} for details.
    # @param format [Function] The postprocessing function.
    # @return [Object] The serialized tree.
    serialize: (format) ->
        if not format?
            return {
                children: []
                data: @data.serialize?() or JSON.parse(JSON.stringify(@data))
            }
        return format(@, [], @data.serialize?() or JSON.parse(JSON.stringify(@data)))

    # See {JSUtils.Tree#deserialize} for details.
    # @param data [Object] The data object.
    # @return [JSUtils.Leaf] This instance.
    deserialize: (data) ->
        @data = data
        return @


    ##################################################################################################
    # NODE RELATIONS

    # See {JSUtils.Tree#getChildren} for details. Always `[]` in this case.
    # @return [Array] `[]`.
    getChildren: () ->
        return []


    ##################################################################################################
    # MODIFYING THE TREE

    # Children can't be added to leaves.
    # @throw [Error] Cannot add a child to a leaf!
    addChild: () ->
        throw new Error("JSUtils.Leaf::addChild: Cannot add a child to a leaf!")

    # Children can't be added to leaves.
    # @throw [Error] Cannot add children to a leaf!
    addChildren: () ->
        throw new Error("JSUtils.Leaf::addChildren: Cannot add children to a leaf!")

    # Children can't be added to leaves.
    # @throw [Error] Cannot set children of a leaf!
    setChildren: () ->
        throw new Error("JSUtils.Leaf::setChildren: Cannot set children of a leaf!")

    # Children can't be removed from leaves.
    # @throw [Error] Cannot remove children from a leaf!
    removeChild: () ->
        throw new Error("JSUtils.Leaf::removeChild: Cannot remove children from a leaf!")

    # See {JSUtils.Tree#getChildren} for details.
    # @return [JSUtils.Leaf] This instance.
    adjustLevels: () ->
        return @
