local date = require("dial.augend").date

describe([[Test of date with format "%Y-%m-%d":]], function()
    local augend = date.alias["%Y-%m-%d"]

    describe("find function", function()
        it("can find dates in a given format", function()
            assert.are.same(augend:find_stateful("date: 2022-10-16", 1), { from = 7, to = 16 })
            assert.are.same(augend.kind, "day")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 6), { from = 7, to = 16 })
            assert.are.same(augend.kind, "day")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 7), { from = 7, to = 16 })
            assert.are.same(augend.kind, "year")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 10), { from = 7, to = 16 })
            assert.are.same(augend.kind, "year")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 11), { from = 7, to = 16 })
            assert.are.same(augend.kind, "month")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 13), { from = 7, to = 16 })
            assert.are.same(augend.kind, "month")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 14), { from = 7, to = 16 })
            assert.are.same(augend.kind, "day")
            assert.are.same(augend:find_stateful("date: 2022-10-16", 16), { from = 7, to = 16 })
            assert.are.same(augend.kind, "day")
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

describe([[Test of date with format "%-m/%-d":]], function()
    local augend = date.alias["%-m/%-d"]

    describe("find function", function()
        it("can find dates in a given format", function()
            assert.are.same(augend:find("10/16", 1), { from = 1, to = 5 })
        end)
        it("cannot find dates in unspecified format", function()
            assert.are.same(augend:find("10-16", 1), nil)
        end)
        it("can find dates in a given format but not exist", function()
            assert.are.same(augend:find("10/32", 1), nil)
        end)
    end)

    describe("add function", function()
        it("can inc/dec days", function()
            augend.kind = "day"
            assert.are.same(augend:add("10/16", 1), { text = "10/17", cursor = 5 })
            assert.are.same(augend:add("10/16", 1, 1), { text = "10/17", cursor = 5 })
            assert.are.same(augend:add("10/16", 1, 5), { text = "10/17", cursor = 5 })
            assert.are.same(augend:add("10/16", 5), { text = "10/21", cursor = 5 })
            assert.are.same(augend:add("10/16", 21), { text = "11/6", cursor = 4 })
            assert.are.same(augend:add("10/16", -21), { text = "9/25", cursor = 4 })
            assert.are.same(augend:add("12/16", 21), { text = "1/6", cursor = 3 })
        end)

        it("can inc/dec months", function()
            augend.kind = "month"
            assert.are.same(augend:add("10/16", 1), { text = "11/16", cursor = 2 })
            assert.are.same(augend:add("10/16", 1, 1), { text = "11/16", cursor = 2 })
            assert.are.same(augend:add("10/16", 1, 5), { text = "11/16", cursor = 2 })
            assert.are.same(augend:add("10/16", 2), { text = "12/16", cursor = 2 })
            assert.are.same(augend:add("10/16", 5), { text = "3/16", cursor = 1 })
            assert.are.same(augend:add("10/16", -5), { text = "5/16", cursor = 1 })
        end)
    end)
end)

describe([[Test of date with format "%Y年%-m月%-d日(%ja)":]], function()
    local augend = date.alias["%Y年%-m月%-d日(%ja)"]

    describe("find function", function()
        it("can find dates in a given format", function()
            assert.are.same(augend:find("2022年10月16日(日)", 1), { from = 1, to = 22 })
        end)
        it("cannot find dates in unspecified format", function()
            assert.are.same(augend:find("2022/10/16", 1), nil)
        end)
        it("can find dates in a given format but not exist", function()
            assert.are.same(augend:find("2022年10月16日(金)", 1), { from = 1, to = 22 })
            assert.are.same(augend:find("2022年10月32日(火)", 1), { from = 1, to = 22 })
        end)
    end)

    describe("add function", function()
        it("can inc/dec days", function()
            augend.kind = "day"
            assert.are.same(augend:add("2022年10月16日(日)", 1), { text = "2022年10月17日(月)", cursor = 14 })
            assert.are.same(
                augend:add("2022年10月16日(日)", 1, 1),
                { text = "2022年10月17日(月)", cursor = 14 }
            )
            assert.are.same(
                augend:add("2022年10月16日(日)", 1, 7),
                { text = "2022年10月17日(月)", cursor = 14 }
            )
            assert.are.same(
                augend:add("2022年10月16日(日)", 1, 10),
                { text = "2022年10月17日(月)", cursor = 14 }
            )
            assert.are.same(augend:add("2022年10月16日(日)", 5), { text = "2022年10月21日(金)", cursor = 14 })
            assert.are.same(augend:add("2022年10月16日(日)", 21), { text = "2022年11月6日(日)", cursor = 13 })
            assert.are.same(augend:add("2022年10月16日(日)", -21), { text = "2022年9月25日(日)", cursor = 13 })
            assert.are.same(augend:add("2022年12月16日(金)", 21), { text = "2023年1月6日(金)", cursor = 12 })
        end)

        it("correct date and increment days", function()
            augend.kind = "day"
            assert.are.same(augend:add("2022年10月32日(日)", 1), { text = "2022年11月2日(水)", cursor = 13 })
        end)
    end)
end)

describe([[Test of date with format %H:%M:]], function()
    local augend = date.alias["%H:%M"]
    describe("find function", function()
        it("can find dates in a given format with Time Zones", function()
            assert.are.same(augend:find_stateful("date: 11:50", 1), { from = 7, to = 11 })
            assert.are.same(augend.kind, "min")
            assert.are.same(augend:find_stateful("date: 11:50", 6), { from = 7, to = 11 })
            assert.are.same(augend.kind, "min")
            assert.are.same(augend:find_stateful("date: 11:50", 7), { from = 7, to = 11 })
            assert.are.same(augend.kind, "hour")
            assert.are.same(augend:find_stateful("date: 11:50", 10), { from = 7, to = 11 })
            assert.are.same(augend.kind, "min")
        end)
    end)
end)

describe([[Test of clamp & end_sensitive option:]], function()
    describe("{clamp = false and end_sensitive = false}", function()
        local augend = date.new {
            pattern = "%Y/%m/%d",
            default_kind = "day",
            clamp = false,
            end_sensitive = false,
        }
        it("does not clamp day or treat last days of month specially", function()
            augend.kind = "month"
            assert.are.same(augend:add("2022/01/28", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/29", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/01/30", 1), { text = "2022/03/02", cursor = 7 })
            assert.are.same(augend:add("2022/01/31", 1), { text = "2022/03/03", cursor = 7 })
            assert.are.same(augend:add("2022/02/01", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", 1), { text = "2022/03/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", 1), { text = "2022/03/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", 1), { text = "2022/05/01", cursor = 7 })
            assert.are.same(augend:add("2021/12/31", 2), { text = "2022/03/03", cursor = 7 })

            assert.are.same(augend:add("2022/03/28", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/29", -1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", -1), { text = "2022/03/02", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", -1), { text = "2022/03/03", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", -1), { text = "2022/01/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", -1), { text = "2022/01/28", cursor = 7 })
            assert.are.same(augend:add("2022/12/31", -1), { text = "2022/12/01", cursor = 7 })

            augend.kind = "year"
            assert.are.same(augend:add("2024/02/29", 1), { text = "2025/03/01", cursor = 4 })
            assert.are.same(augend:add("2025/02/28", -1), { text = "2024/02/28", cursor = 4 })
        end)
    end)

    describe("{clamp = true and end_sensitive = false}", function()
        local augend = date.new {
            pattern = "%Y/%m/%d",
            default_kind = "day",
            clamp = true,
            end_sensitive = false,
        }
        it("clamps day but does not treat last days of month specially", function()
            augend.kind = "month"
            assert.are.same(augend:add("2022/01/28", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/29", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/30", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/31", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/01", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", 1), { text = "2022/03/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", 1), { text = "2022/03/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2021/12/31", 2), { text = "2022/02/28", cursor = 7 })

            assert.are.same(augend:add("2022/03/28", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/29", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", -1), { text = "2022/01/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", -1), { text = "2022/01/28", cursor = 7 })
            assert.are.same(augend:add("2022/12/31", -1), { text = "2022/11/30", cursor = 7 })

            augend.kind = "year"
            assert.are.same(augend:add("2024/02/29", 1), { text = "2025/02/28", cursor = 4 })
            assert.are.same(augend:add("2025/02/28", -1), { text = "2024/02/28", cursor = 4 })
        end)
    end)

    describe("{clamp = false and end_sensitive = true}", function()
        local augend = date.new {
            pattern = "%Y/%m/%d",
            default_kind = "day",
            clamp = false,
            end_sensitive = true,
        }
        it("does not clamp day but treat last days of month specially", function()
            augend.kind = "month"
            assert.are.same(augend:add("2022/01/28", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/29", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/01/30", 1), { text = "2022/03/02", cursor = 7 })
            assert.are.same(augend:add("2022/01/31", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/01", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", 1), { text = "2022/03/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", 1), { text = "2022/03/31", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2021/12/31", 2), { text = "2022/02/28", cursor = 7 })

            assert.are.same(augend:add("2022/03/28", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/29", -1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", -1), { text = "2022/03/02", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", -1), { text = "2022/01/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", -1), { text = "2022/01/31", cursor = 7 })
            assert.are.same(augend:add("2022/12/31", -1), { text = "2022/11/30", cursor = 7 })

            augend.kind = "year"
            assert.are.same(augend:add("2024/02/29", 1), { text = "2025/02/28", cursor = 4 })
            assert.are.same(augend:add("2025/02/28", -1), { text = "2024/02/29", cursor = 4 })
        end)
    end)

    describe("{clamp = true and end_sensitive = true}", function()
        local augend = date.new {
            pattern = "%Y/%m/%d",
            default_kind = "day",
            clamp = true,
            end_sensitive = true,
        }
        it("clamp day and treat last days of month specially", function()
            augend.kind = "month"
            assert.are.same(augend:add("2022/01/28", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/29", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/30", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/01/31", 1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/01", 1), { text = "2022/03/01", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", 1), { text = "2022/03/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", 1), { text = "2022/03/31", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", 1), { text = "2022/04/30", cursor = 7 })
            assert.are.same(augend:add("2021/12/31", 2), { text = "2022/02/28", cursor = 7 })

            assert.are.same(augend:add("2022/03/28", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/29", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/30", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/03/31", -1), { text = "2022/02/28", cursor = 7 })
            assert.are.same(augend:add("2022/02/27", -1), { text = "2022/01/27", cursor = 7 })
            assert.are.same(augend:add("2022/02/28", -1), { text = "2022/01/31", cursor = 7 })
            assert.are.same(augend:add("2022/12/31", -1), { text = "2022/11/30", cursor = 7 })

            augend.kind = "year"
            assert.are.same(augend:add("2024/02/29", 1), { text = "2025/02/28", cursor = 4 })
            assert.are.same(augend:add("2025/02/28", -1), { text = "2024/02/29", cursor = 4 })
        end)
    end)
end)
