describe "Tree", () ->

    describe "Tree", () ->

        describe "creating a tree", () ->

            it "Tree.new (== Tree.fromRecursive)", () ->

            it "Tree.newByChildRef", () ->

            xit "Tree.newByParentRef", () ->

            it "magically access properties on the data object (attached to a node)", () ->

        describe "modifying a tree", () ->

            it "addChild (== appendChild)", () ->

            it "addChildren (== appendChildren)", () ->

            it "setChildren", () ->

            it "moveTo", () ->

            it "remove", () ->

            it "removeChild", () ->

            it "removeChildAt", () ->

            it "appendTo", () ->

        describe "traversing a tree", () ->

            it "each", () ->

            it "postorder", () ->

            it "preorder", () ->

            it "inorder", () ->

            it "levelorder", () ->

        describe "getting information about a tree", () ->

            it "depth & getDepth()", () ->

            it "size & getSize()", () ->

            it "level & getLevel()", () ->

            it "rot & getRoot()", () ->

            it "equals", () ->

            it "hasNode", () ->

            it "findNode (== findDescendant)", () ->

            it "findNodes (== findDescendants)", () ->

            it "getDepth", () ->

            it "getSize", () ->

            it "getLeaves", () ->

            it "isLeaf", () ->

            it "getSiblings", () ->

            it "getLevelSiblings", () ->

            it "getParent", () ->

            it "getChildren", () ->

            it "pathToRoot", () ->

        describe "converting a tree", () ->

            it "serialize (== toObject)", () ->

            it "deserialize", () ->
