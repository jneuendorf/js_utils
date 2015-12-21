describe "Tree", () ->

    describe "Tree", () ->

        describe "creating a tree", () ->
            it "Tree.new (== Tree.fromRecursive), defaults to Tree.newByChildRef", () ->
                tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                        {
                            a: 3
                            b: 4
                            name: "child2"
                            children: [
                                {
                                    a: 0
                                    b: 0
                                    name: "child2-child"
                                }
                            ]
                        }
                        {
                            a: 5
                            b: 6
                            name: "child3"
                        }
                    ]
                }

                expect tree.data.name
                    .toBe "root"
                expect tree.children.length
                    .toBe 3
                expect (node.data.name for node in tree.children)
                    .toEqual ["child1", "child2", "child3"]
                expect tree.children[0].data.a
                    .toBe 1
                expect tree.children[1].children[0].data.name
                    .toBe "child2-child"

            xit "Tree.newByParentRef", () ->

            it "magically access properties on the data object (attached to a node)", () ->
                tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                    ]
                }
                expect tree.data.name
                    .toBe tree.name
                expect tree.data.a
                    .toBe tree.a
                expect tree.children[0].data.name
                    .toBe tree.children[0].name


        describe "modifying a tree", () ->
            beforeEach () ->
                @tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                        {
                            a: 3
                            b: 4
                            name: "child2"
                            children: [
                                {
                                    a: 0
                                    b: 0
                                    name: "child2-child"
                                }
                            ]
                        }
                        {
                            a: 5
                            b: 6
                            name: "child3"
                        }
                    ]
                }

            it "addChild (== appendChild)", () ->
                expect @tree.children.length
                    .toBe 3
                @tree.addChild {
                    newNode: true
                }
                expect @tree.children.length
                    .toBe 4
                expect @tree.children[3].newNode
                    .toBe true

                @tree.addChild {prop: "asdf"}, 1
                expect @tree.children.length
                    .toBe 5
                expect @tree.children[1].prop
                    .toBe "asdf"
                expect @tree.children[4].newNode
                    .toBe true

            it "addChildren (== appendChildren)", () ->
                expect @tree.children.length
                    .toBe 3

                @tree.addChildren(
                    [
                        {
                            name: "new node 1"
                        }
                        {
                            name: "new node 2"
                        }
                    ]
                    1
                )
                expect @tree.children.length
                    .toBe 5
                expect @tree.children[1].name
                    .toBe "new node 1"
                expect @tree.children[2].name
                    .toBe "new node 2"
                expect @tree.children[3].name
                    .toBe "child2"
                expect @tree.children[4].name
                    .toBe "child3"

            it "setChildren", () ->
                expect @tree.children.length
                    .toBe 3
                @tree.setChildren [
                    {
                        name: "new child 1"
                    }
                    {
                        name: "new child 2"
                    }
                ]
                expect @tree.children.length
                    .toBe 2
                expect @tree.children[0].name
                    .toBe "new child 1"
                expect @tree.children[1].name
                    .toBe "new child 2"

            it "moveTo (== appendTo)", () ->
                @tree.children[1].children[0].moveTo @tree, 0
                expect @tree.children[0].name
                    .toBe "child2-child"
                expect @tree.children[1].children.length
                    .toBe 0
                expect @tree.children.length
                    .toBe 4

            it "remove", () ->
                removed = @tree.children[1].remove()

                expect @tree.children.length
                    .toBe 2
                expect @tree.children[1].name
                    .toBe "child3"
                expect removed.children[0].name
                    .toBe "child2-child"

            it "removeChild", () ->
                @tree.removeChild 1
                expect @tree.children.length
                    .toBe 2
                expect @tree.children[1].name
                    .toBe "child3"

                @tree.removeChild @tree.children[0]
                expect @tree.children.length
                    .toBe 1
                expect @tree.children[0].name
                    .toBe "child3"


        describe "traversing a tree", () ->
            beforeEach () ->
                @tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                        {
                            a: 3
                            b: 4
                            name: "child2"
                            children: [
                                {
                                    a: 0
                                    b: 0
                                    name: "child2-child"
                                }
                            ]
                        }
                        {
                            a: 5
                            b: 6
                            name: "child3"
                        }
                    ]
                }

            it "postorder (== each)", () ->
                result = []
                @tree.postorder (node, relativeLevel, index) ->
                    result.push node.name
                expect result
                    .toEqual ["child1", "child2-child", "child2", "child3", "root"]
                result = []
                @tree.each (node, relativeLevel, index) ->
                    result.push node.name
                expect result
                    .toEqual ["child1", "child2-child", "child2", "child3", "root"]

            it "preorder", () ->
                result = []
                @tree.preorder (node, relativeLevel, index) ->
                    result.push node.name
                expect result
                    .toEqual ["root", "child1", "child2", "child2-child", "child3"]

            it "inorder", () ->
                result = []
                @tree.inorder (node, relativeLevel, index) ->
                    result.push node.name
                expect result
                    .toEqual ["child1", "root", "child2-child", "child2", "child3"]

            it "levelorder", () ->
                result = []
                @tree.levelorder (node, relativeLevel, index) ->
                    result.push node.name
                expect result
                    .toEqual ["root", "child1", "child2", "child3", "child2-child"]


        describe "getting information about a tree", () ->
            beforeEach () ->
                @tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                        {
                            a: 3
                            b: 4
                            name: "child2"
                            children: [
                                {
                                    a: 0
                                    b: 0
                                    name: "child2-child"
                                }
                            ]
                        }
                        {
                            a: 5
                            b: 6
                            name: "child3"
                        }
                    ]
                }

            it "depth & getDepth()", () ->
                expect @tree.depth
                    .toBe 2
                @tree.children[1].children[0].remove()
                expect @tree.depth
                    .toBe 1

            it "size & getSize()", () ->
                expect @tree.size
                    .toBe 5

            it "level & getLevel()", () ->
                expect @tree.level
                    .toBe 0
                expect @tree.children[1].level
                    .toBe 1
                expect @tree.children[1].children[0].level
                    .toBe 2

                @tree.children[1].children[0].addChild {
                    name: "child2-child-child"
                }
                expect @tree.children[1].children[0].children[0].level
                    .toBe 3

            it "root & getRoot()", () ->
                expect @tree.root
                    .toBe @tree
                expect @tree.children[1].root
                    .toBe @tree
                expect @tree.children[1].children[0].root
                    .toBe @tree

            it "hasNode", () ->
                expect @tree.hasNode(@tree)
                    .toBe true
                expect @tree.hasNode(@tree.children[0])
                    .toBe true
                expect @tree.hasNode(@tree.children[1])
                    .toBe true
                expect @tree.hasNode(@tree.children[1].children[0])
                    .toBe true
                expect @tree.hasNode(@tree.children[2])
                    .toBe true

                expect @tree.hasNode(JSUtils.Tree.new())
                    .toBe false

            it "findNode (== findDescendant)", () ->
                expect @tree.findNode (node) -> node.name is "child2"
                    .toBe @tree.children[1]

            it "findNodes (== findDescendants)", () ->
                nodes = @tree.findNodes (node) ->
                    return node.name.length > 4
                nodes.sort (a, b) ->
                    return a - b
                names = (node.name for node in nodes)
                expect names
                    .toEqual ["child1", "child2", "child3", "child2-child"]

            it "getLeaves", () ->
                expect (leaf.name for leaf in @tree.getLeaves())
                    .toEqual ["child1", "child2-child", "child3"]

            it "isLeaf", () ->
                leaves = @tree.getLeaves()
                for leaf in leaves
                    expect leaf.isLeaf()
                        .toBe true

                expect @tree.children[1].isLeaf()
                    .toBe false

            it "getSiblings", () ->
                @tree.children[1].addChild {name: "child2-child2"}
                expect @tree.children[1].children[0].getSiblings()[0].name
                    .toBe "child2-child2"

                expect (node.name for node in @tree.children[1].getSiblings())
                    .toEqual ["child1", "child3"]

                expect @tree.getSiblings()
                    .toEqual []

            it "getLevelSiblings", () ->
                # subset -> siblings with same parent
                expect (node.name for node in @tree.children[1].getLevelSiblings())
                    .toEqual ["child1", "child3"]

                # siblings with different parents
                @tree.children[0].addChild {name: "child1-child"}
                expect @tree.children[0].children[0].getLevelSiblings()[0].name
                    .toBe "child2-child"

            it "getParent", () ->
                expect @tree.children[0].getParent()
                    .toBe @tree.children[0].parent

            it "getChildren", () ->
                expect @tree.getChildren()
                    .toBe @tree.children

            it "pathToRoot", () ->
                expect (node.name for node in @tree.pathToRoot())
                    .toEqual ["root"]
                expect (node.name for node in @tree.children[0].pathToRoot())
                    .toEqual ["child1", "root"]
                expect (node.name for node in @tree.children[1].children[0].pathToRoot())
                    .toEqual ["child2-child", "child2", "root"]

            it "pathFromRoot", () ->
                expect (node.name for node in @tree.pathFromRoot())
                    .toEqual ["root"]
                expect (node.name for node in @tree.children[0].pathFromRoot())
                    .toEqual ["root", "child1"]
                expect (node.name for node in @tree.children[1].children[0].pathFromRoot())
                    .toEqual ["root", "child2", "child2-child"]

            it "equals", () ->

        describe "converting a tree", () ->
            beforeEach () ->
                @tree = JSUtils.Tree.new {
                    a: 10
                    b: 20
                    name: "root"
                    children: [
                        {
                            a: 1
                            b: 2
                            name: "child1"
                        }
                        {
                            a: 3
                            b: 4
                            name: "child2"
                            children: [
                                {
                                    a: 0
                                    b: 0
                                    name: "child2-child"
                                }
                            ]
                        }
                        {
                            a: 5
                            b: 6
                            name: "child3"
                        }
                    ]
                }

            it "serialize (== toObject)", () ->
                expect @tree.serialize()
                    .toEqual {
                        a: 10
                        b: 20
                        name: "root"
                        children: [
                            {
                                a: 1
                                b: 2
                                name: "child1"
                                children: []
                            }
                            {
                                a: 3
                                b: 4
                                name: "child2"
                                children: [
                                    {
                                        a: 0
                                        b: 0
                                        name: "child2-child"
                                        children: []
                                    }
                                ]
                            }
                            {
                                a: 5
                                b: 6
                                name: "child3"
                                children: []
                            }
                        ]
                    }

            it "deserialize (a.k.a. in-place constructing)", () ->
                @tree.deserialize {
                    a: 10
                    name: "new root"
                    children: [
                        {
                            a: 1
                            name: "new child1"
                            children: []
                        }
                        {
                            name: "new child2"
                            children: [
                                {
                                    name: "new child2-child"
                                    children: []
                                }
                            ]
                        }
                    ]
                }

                expect @tree.name
                    .toBe "new root"
                for child, idx in @tree.children
                    expect child.name
                        .toBe "new child#{idx + 1}"
                    expect child.parent
                        .toBe @tree
                expect @tree.children[1].children[0].name
                    .toBe "new child2-child"
                expect @tree.children[1].children[0].parent
                    .toBe @tree.children[1]
