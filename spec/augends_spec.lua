local augends = require 'dial/augends'

describe("Test of augend 'number#decimal':", function()
    local augend = augends['number#decimal']

    describe("find method in 'number#decimal'", function()
        test("can find a number", function()
            assert.are.same(augend.find(1, "123"), {from = 1, to = 3})
            assert.are.same(augend.find(1, "0000"), {from = 1, to = 4})
            assert.are.same(augend.find(4, "aaa123"), {from = 4, to = 6})
        end)

        test("does not match for negative numbers", function()
            assert.are.same(augend.find(1, "-123"), {from = 2, to = 4})
            assert.are.same(augend.find(4, "-123"), {from = 2, to = 4})
        end)

        test("can ignore a number before the cursor", function()
            assert.is_nil(augend.find(7, "aaa123bbb"))
        end)
    end)

    describe("add method in 'number#decimal'", function()
        test("can increment/decrement properly", function()
            assert.are.same({augend.add(1, "123", 1)}, {3, "124"})
            assert.are.same({augend.add(2, "123", 1)}, {3, "124"})
            assert.are.same({augend.add(1, "123", -1)}, {3, "122"})
            assert.are.same({augend.add(1, "999", 1)}, {4, "1000"})
            assert.are.same({augend.add(1, "1000", -1)}, {3, "999"})
            assert.are.same({augend.add(4, "1000", -1)}, {3, "999"})
            assert.are.same({augend.add(1, "1000", -910)}, {2, "90"})
        end)

        test("does not to be an negative number", function()
            assert.are.same({augend.add(1, "1", -1)}, {1, "0"})
            assert.are.same({augend.add(1, "1", -2)}, {1, "0"})
            assert.are.same({augend.add(4, "9999", -10000)}, {1, "0"})
        end)

        test("can increment/decrement a number starting with 0", function()
            assert.are.same({augend.add(1, "01", 1)}, {2, "02"})
            assert.are.same({augend.add(1, "09", 1)}, {2, "10"})
            assert.are.same({augend.add(1, "09", 92)}, {3, "101"})
        end)
    end)
end)
