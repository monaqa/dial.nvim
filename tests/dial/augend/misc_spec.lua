local misc = require("dial.augend").misc

describe("Test of misc.alias.markdown_header:", function()
    local augend = misc.alias.markdown_header

    describe("find function", function()
        it("can find a markdown header", function()
            assert.are.same(augend:find("# Header 1", 1), { from = 1, to = 1 })
            assert.are.same(augend:find("## Header 2", 1), { from = 1, to = 2 })
            assert.are.same(augend:find("###### Header 6", 1), { from = 1, to = 6 })
            assert.are.same(augend:find("#Header 1", 1), { from = 1, to = 1 })
            assert.are.same(augend:find("# Header 1", 3), { from = 1, to = 1 })
        end)
        it("ignores non-header elements", function()
            assert.are.same(augend:find("foo # bar", 1), nil)
            assert.are.same(augend:find("####### Header 7?", 1), nil)
        end)
    end)

    describe("add function", function()
        it("can increment header level", function()
            assert.are.same(augend:add("#", 1, 1), { text = "##", cursor = 1 })
            assert.are.same(augend:add("##", 3, 1), { text = "#####", cursor = 1 })
            assert.are.same(augend:add("#", 7, 1), { text = "######", cursor = 1 })
            assert.are.same(augend:add("##", -4, 1), { text = "#", cursor = 1 })
            assert.are.same(augend:add("####", -1, 6), { text = "###", cursor = 1 })
        end)
    end)
end)
