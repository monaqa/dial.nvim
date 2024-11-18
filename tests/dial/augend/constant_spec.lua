local constant = require("dial.augend").constant

describe("Test of constant between two words", function()
    local augend = constant.new { elements = { "true", "false" } }

    describe("find function", function()
        it("can find a completely matching word", function()
            assert.are.same(augend:find("enable = true", 1), { from = 10, to = 13 })
            assert.are.same(augend:find("enable = false", 1), { from = 10, to = 14 })
        end)
        it("does not find a word including element words", function()
            assert.are.same(augend:find("mistakenly construed", 1), nil)
        end)
        it("does not find a word before the cursor when match_before_cursor = false", function()
            assert.are.same(augend:find("true negative", 5), nil)
        end)
    end)

    augend = constant.new { elements = { "true", "false" }, match_before_cursor = true }

    describe("find function", function()
        it("does find a word before the cursor when match_before_cursor = true", function()
            assert.are.same(augend:find("true positive", 5), { from = 1, to = 4 })
        end)
    end)
end)
