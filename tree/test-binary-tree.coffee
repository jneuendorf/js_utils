    describe "BinaryTree", () ->

        describe "creating a binary tree", () ->
            it "BinaryTree.new (== BinaryTree.fromRecursive), defaults to BinaryTree.newByChildRef", () ->
                tree = JSUtils.BinaryTree.new(
                    {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    {
                                        n: 3
                                    }
                                ]
                            }
                            {
                                n: 15
                            }
                        ]
                    }
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

                #    10
                #    / \
                #   1  15
                #  /\
                # -  3

                arr = []
                tree.inorder (node) ->
                    arr.push node.n
                    true

                expect tree.left.n
                    .toBe 1
                expect tree.left.left
                    .toEqual null
                expect tree.left.right.n
                    .toBe 3
                expect tree.right.n
                    .toBe 15

        describe "modifying a tree", () ->
            beforeEach () ->
                @tree = JSUtils.BinaryTree.new(
                    {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    {
                                        n: 3
                                    }
                                ]
                            }
                            {
                                n: 15
                            }
                        ]
                    }
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

            it "addChild (== appendChild)", () ->
                @tree.addChild {
                    n: 12
                }
                expect @tree.right.left.n
                    .toBe 12

            it "addChildren (== appendChildren)", () ->
                @tree.addChildren [{n: 12}, {n: 8}]
                expect @tree.right.left.n
                    .toBe 12
                expect @tree.left.right.right.n
                    .toBe 8

            it "setChildren", () ->
                expect @tree.setChildren
                    .toThrowError(/children.*cannot.*be.*set/i)

            it "moveTo (== appendTo)", () ->
                expect @tree.moveTo
                    .toThrowError(/cannot.*move.*node/i)
                expect @tree.appendTo
                    .toThrowError(/cannot.*move.*node/i)

            it "remove", () ->
                @tree.left.right.remove()
                expect @tree.left.right
                    .toBe null

            it "removeChild", () ->
                @tree.removeChild (node) ->
                    return node.n is 1
                expect @tree.left
                    .toBe null

        describe "traversing a tree", () ->
            beforeEach () ->
                @tree = JSUtils.BinaryTree.new(
                    {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    {
                                        n: 3
                                    }
                                ]
                            }
                            {
                                n: 15
                            }
                        ]
                    }
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

            it "postorder (== each)", () ->
                result = []
                @tree.postorder (node, relativeLevel, index) ->
                    result.push node.n
                expect result
                    .toEqual [3, 1, 15, 10]
                result = []
                @tree.each (node, relativeLevel, index) ->
                    result.push node.n
                expect result
                    .toEqual [3, 1, 15, 10]

            it "preorder", () ->
                result = []
                @tree.preorder (node, relativeLevel, index) ->
                    result.push node.n
                expect result
                    .toEqual [10, 1, 3, 15]

            it "inorder", () ->
                result = []
                @tree.inorder (node, relativeLevel, index) ->
                    result.push node.n
                expect result
                    .toEqual [1, 3, 10, 15]

            it "levelorder", () ->
                result = []
                @tree.levelorder (node, relativeLevel, index) ->
                    result.push node.n
                expect result
                    .toEqual [10, 1, 15, 3]

        describe "getting information about a tree", () ->
            beforeEach () ->
                @tree = JSUtils.BinaryTree.new(
                    {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    {
                                        n: 3
                                    }
                                ]
                            }
                            {
                                n: 15
                            }
                        ]
                    }
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

            it "depth & getDepth()", () ->
                expect @tree.depth
                    .toBe 2

            it "size & getSize()", () ->
                expect @tree.size
                    .toBe 4

            it "level & getLevel()", () ->
                expect @tree.level
                    .toBe 0
                expect @tree.left.level
                    .toBe 1
                expect @tree.left.right.level
                    .toBe 2

            it "root & getRoot()", () ->
                expect @tree.root
                    .toBe @tree
                expect @tree.left.root
                    .toBe @tree
                expect @tree.left.right.root
                    .toBe @tree

            it "hasNode", () ->
                expect @tree.hasNode(@tree)
                    .toBe true
                expect @tree.hasNode(@tree.left)
                    .toBe true
                expect @tree.hasNode(@tree.right)
                    .toBe true

                expect @tree.hasNode(JSUtils.BinaryTree.new({n: 42}, (a, b) -> return a - b))
                    .toBe false

            it "findNode (== findDescendant)", () ->
                expect @tree.findNode (node) -> node.n is 3
                    .toBe @tree.left.right

            it "findNodes (== findDescendants)", () ->
                nodes = @tree.findNodes (node) ->
                    return node.n > 2
                vals = (node.n for node in nodes)
                vals.sort (a, b) ->
                    return a - b
                expect vals
                    .toEqual [3, 15]

            it "getLeaves", () ->
                expect (leaf.n for leaf in @tree.getLeaves())
                    .toEqual [3, 15]

            it "isLeaf", () ->
                leaves = @tree.getLeaves()
                for leaf in leaves
                    expect leaf.isLeaf()
                        .toBe true

                expect @tree.left.isLeaf()
                    .toBe false

            it "getSiblings", () ->
                expect @tree.left.getSiblings()[0].n
                    .toBe 15
                expect @tree.getSiblings()
                    .toEqual []

            it "getLevelSiblings", () ->
                @tree.addChild {n: 42}
                expect @tree.left.right.getLevelSiblings()[0].n
                    .toBe 42

            it "getParent", () ->
                expect @tree.left.getParent()
                    .toBe @tree.left.parent

            it "getChildren", () ->
                expect @tree.getChildren()
                    .toBe @tree.children

            it "pathToRoot", () ->
                expect (node.n for node in @tree.pathToRoot())
                    .toEqual [10]
                expect (node.n for node in @tree.left.pathToRoot())
                    .toEqual [1, 10]
                expect (node.n for node in @tree.left.right.pathToRoot())
                    .toEqual [3, 1, 10]

            it "pathFromRoot", () ->
                expect (node.n for node in @tree.pathFromRoot())
                    .toEqual [10]
                expect (node.n for node in @tree.left.pathFromRoot())
                    .toEqual [10, 1]
                expect (node.n for node in @tree.left.right.pathFromRoot())
                    .toEqual [10, 1, 3]

        describe "converting a tree", () ->
            beforeEach () ->
                @tree = JSUtils.BinaryTree.new(
                    {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    {
                                        n: 3
                                    }
                                ]
                            }
                            {
                                n: 15
                            }
                        ]
                    }
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

            it "serialize (== toObject)", () ->
                expect @tree.serialize (node, children) -> $.extend({}, node.data, {children})
                    .toEqual {
                        n: 10
                        children: [
                            {
                                n: 1
                                children: [
                                    null
                                    {n: 3, children: []}
                                ]
                            }
                            {n: 15, children: []}
                        ]
                    }

            it "deserialize (a.k.a. in-place constructing)", () ->
                @tree.deserialize {
                    n: 11
                    children: [
                        {
                            n: 2
                            children: [
                                {
                                    n: 4
                                }
                            ]
                        }
                        {
                            n: 16
                        }
                    ]
                }

                expect @tree.n
                    .toBe 11
                expect @tree.left.n
                    .toBe 2
                expect @tree.left.right.n
                    .toBe 4
                expect @tree.right.n
                    .toBe 16

        describe "balancing a tree", () ->

            it "balance", () ->
                tree = JSUtils.BinaryTree.new(
                    {n: 100}
                    {
                        compareNodes: (currentNode, newNode) ->
                            return newNode.n - currentNode.n
                    }
                )

                tree.addChild {n: 90}
                tree.addChild {n: 80}
                tree.addChild {n: 70}
                tree.addChild {n: 60}
                tree.addChild {n: 50}
                tree.addChild {n: 40}
                tree.addChild {n: 30}
                tree.addChild {n: 20}
                tree.addChild {n: 10}

                expect tree.depth
                    .toBe 9
                expect tree.left.left.left.left.left.left.left.left.left.n
                    .toBe 10

                tree.balance()
                expect tree.serialize (node, children) -> $.extend({}, node.data, {children})
                    .toEqual {
                        n: 60
                        children: [
                            {
                                n: 40
                                children: [
                                    {
                                        n: 20
                                        children: [
                                            {n: 10, children: []}
                                            {n: 30, children: []}
                                        ]
                                    }
                                    {n: 50, children: []}
                                ]
                            }
                            {
                                n: 90
                                children: [
                                    {n: 80, children: []}
                                    {n: 100, children: []}
                                ]
                            }
                        ]
                    }
                expect tree.level
                    .toBe 0

                # 40
                expect tree.left.level
                    .toBe 1
                # 20
                expect tree.left.left.level
                    .toBe 2
                # 50
                expect tree.left.right.level
                    .toBe 2

                # 10
                expect tree.left.left.left.level
                    .toBe 3
                # 30
                expect tree.left.left.right.level
                    .toBe 3

                # 90
                expect tree.right.level
                    .toBe 1
                # 80
                expect tree.right.left.level
                    .toBe 2
                # 100
                expect tree.right.right.level
                    .toBe 2
