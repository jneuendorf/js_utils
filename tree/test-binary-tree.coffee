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
                #  /
                # 3

                expect tree.left.n
                    .toBe 1
                expect tree.left.left
                    .toEqual null
                expect tree.left.right.n
                    .toBe 3
                expect tree.right.n
                    .toBe 15

        describe "modifying a tree", () ->
            # beforeEach () ->
            #     @tree = JSUtils.Tree.new {
            #         a: 10
            #         b: 20
            #         name: "root"
            #         children: [
            #             {
            #                 a: 1
            #                 b: 2
            #                 name: "child1"
            #             }
            #             {
            #                 a: 3
            #                 b: 4
            #                 name: "child2"
            #                 children: [
            #                     {
            #                         a: 0
            #                         b: 0
            #                         name: "child2-child"
            #                     }
            #                 ]
            #             }
            #             {
            #                 a: 5
            #                 b: 6
            #                 name: "child3"
            #             }
            #         ]
            #     }
            #
            # it "addChild (== appendChild)", () ->
            #     expect @tree.children.length
            #         .toBe 3
            #     @tree.addChild {
            #         newNode: true
            #     }
            #     expect @tree.children.length
            #         .toBe 4
            #     expect @tree.children[3].newNode
            #         .toBe true
            #
            #     @tree.addChild {prop: "asdf"}, 1
            #     expect @tree.children.length
            #         .toBe 5
            #     expect @tree.children[1].prop
            #         .toBe "asdf"
            #     expect @tree.children[4].newNode
            #         .toBe true
            #
            # it "addChildren (== appendChildren)", () ->
            #     expect @tree.children.length
            #         .toBe 3
