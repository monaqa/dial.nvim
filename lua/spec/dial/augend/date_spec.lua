local date = require("dial.augend").date

describe([[Test of date with format "%Y-%m-%d":]], function()
    local augend = date.alias["%Y-%m-%d"]

    describe("find function", function()
        it("can find dates in a given format", function()
            assert.are.same(augend:find("2022-10-16", 1), { from = 1, to = 10 })
        end)
        it("cannot find dates in unspecified format", function()
            assert.are.same(augend:find("2022/10/16", 1), nil)
        end)
        it("can find dates in a given format but not exist", function()
            assert.are.same(augend:find("2022-10-32", 1), { from = 1, to = 10 })
        end)
    end)

    describe("add function", function()
        it("can inc/dec days", function()
            augend.kind = "day"
            assert.are.same(augend:add("2022-10-16", 1), { text = "2022-10-17", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", 1, 1), { text = "2022-10-17", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", 1, 7), { text = "2022-10-17", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", 1, 10), { text = "2022-10-17", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", 5), { text = "2022-10-21", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", 21), { text = "2022-11-06", cursor = 10 })
            assert.are.same(augend:add("2022-10-16", -21), { text = "2022-09-25", cursor = 10 })
            assert.are.same(augend:add("2022-12-16", 21), { text = "2023-01-06", cursor = 10 })
        end)

        it("can inc/dec months", function()
            augend.kind = "month"
            assert.are.same(augend:add("2022-10-16", 1), { text = "2022-11-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", 1, 1), { text = "2022-11-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", 1, 7), { text = "2022-11-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", 1, 10), { text = "2022-11-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", 2), { text = "2022-12-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", 5), { text = "2023-03-16", cursor = 7 })
            assert.are.same(augend:add("2022-10-16", -5), { text = "2022-05-16", cursor = 7 })
            assert.are.same(augend:add("2022-01-31", 1), { text = "2022-03-03", cursor = 7 })
        end)

        it("can inc/dec years", function()
            augend.kind = "year"
            assert.are.same(augend:add("2022-10-16", 1), { text = "2023-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", 1, 1), { text = "2023-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", 1, 7), { text = "2023-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", 1, 10), { text = "2023-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", 2), { text = "2024-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", 5), { text = "2027-10-16", cursor = 4 })
            assert.are.same(augend:add("2022-10-16", -5), { text = "2017-10-16", cursor = 4 })
            assert.are.same(augend:add("2020-02-29", 1), { text = "2021-03-01", cursor = 4 })
        end)

        it("correct date and increment days", function()
            augend.kind = "day"
            assert.are.same(augend:add("2022-10-32", 1), { text = "2022-11-02", cursor = 10 })
        end)
    end)
end)
