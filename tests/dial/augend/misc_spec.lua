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

describe("Test of misc.alias.ordinals:", function()
    local augend = misc.alias.ordinals

    describe("find function", function()
        it("can find ordinals", function()
            assert.are.same(augend:find("1st", 1), { from = 1, to = 3 })
            assert.are.same(augend:find("2nd", 1), { from = 1, to = 3 })
            assert.are.same(augend:find("3rd", 1), { from = 1, to = 3 })
            assert.are.same(augend:find("4th", 1), { from = 1, to = 3 })
            assert.are.same(augend:find("0th", 1), { from = 1, to = 3 })

            assert.are.same(augend:find("10th", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("11th", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("12th", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("13th", 1), { from = 1, to = 4 })

            assert.are.same(augend:find("21st", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("22nd", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("23rd", 1), { from = 1, to = 4 })

            assert.are.same(augend:find("100th", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("1000th", 1), { from = 1, to = 6 })

            assert.are.same(augend:find("-1st", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("-2nd", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("-3rd", 1), { from = 1, to = 4 })
            assert.are.same(augend:find("-4th", 1), { from = 1, to = 4 })

            assert.are.same(augend:find("-10th", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("-11th", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("-12th", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("-13th", 1), { from = 1, to = 5 })

            assert.are.same(augend:find("-21st", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("-22nd", 1), { from = 1, to = 5 })
            assert.are.same(augend:find("-23rd", 1), { from = 1, to = 5 })

            assert.are.same(augend:find("-100th", 1), { from = 1, to = 6 })
            assert.are.same(augend:find("-1000th", 1), { from = 1, to = 7 })
        end)
        it("ignores non-ordinal elements", function()
            assert.are.same(augend:find("1standard", 1), nil)
            assert.are.same(augend:find("3rdev", 1), nil)
            assert.are.same(augend:find("10thousand", 1), nil)
        end)
    end)

    describe("add function", function()
        it("can increment ordinal", function()
            assert.are.same(augend:add("1st", 1, 1), { text = "2nd", cursor = 1 })
            assert.are.same(augend:add("1st", 2, 1), { text = "3rd", cursor = 1 })
            assert.are.same(augend:add("1st", 3, 1), { text = "4th", cursor = 1 })
            assert.are.same(augend:add("1st", 9, 1), { text = "10th", cursor = 1 })

            assert.are.same(augend:add("2nd", 1, 1), { text = "3rd", cursor = 1 })
            assert.are.same(augend:add("3rd", 1, 1), { text = "4th", cursor = 1 })
            assert.are.same(augend:add("9th", 1, 1), { text = "10th", cursor = 1 })

            assert.are.same(augend:add("10th", 1, 1), { text = "11th", cursor = 1 })
            assert.are.same(augend:add("11th", 1, 1), { text = "12th", cursor = 1 })
            assert.are.same(augend:add("12th", 1, 1), { text = "13th", cursor = 1 })

            assert.are.same(augend:add("20th", 1, 1), { text = "21st", cursor = 1 })
            assert.are.same(augend:add("21st", 1, 1), { text = "22nd", cursor = 1 })
            assert.are.same(augend:add("22nd", 1, 1), { text = "23rd", cursor = 1 })

            assert.are.same(augend:add("99th", 1, 1), { text = "100th", cursor = 1 })
            assert.are.same(augend:add("999th", 1, 1), { text = "1000th", cursor = 1 })

            assert.are.same(augend:add("1000th", -1, 1), { text = "999th", cursor = 1 })
            assert.are.same(augend:add("100th", -1, 1), { text = "99th", cursor = 1 })

            assert.are.same(augend:add("24th", -1, 1), { text = "23rd", cursor = 1 })
            assert.are.same(augend:add("23th", -1, 1), { text = "22nd", cursor = 1 })
            assert.are.same(augend:add("22th", -1, 1), { text = "21st", cursor = 1 })
            assert.are.same(augend:add("21th", -1, 1), { text = "20th", cursor = 1 })

            assert.are.same(augend:add("14th", -1, 1), { text = "13th", cursor = 1 })
            assert.are.same(augend:add("13th", -1, 1), { text = "12th", cursor = 1 })
            assert.are.same(augend:add("12th", -1, 1), { text = "11th", cursor = 1 })
            assert.are.same(augend:add("11th", -1, 1), { text = "10th", cursor = 1 })

            assert.are.same(augend:add("10th", -1, 1), { text = "9th", cursor = 1 })
            assert.are.same(augend:add("4th", -1, 1), { text = "3rd", cursor = 1 })
            assert.are.same(augend:add("3rd", -1, 1), { text = "2nd", cursor = 1 })
            assert.are.same(augend:add("2nd", -1, 1), { text = "1st", cursor = 1 })

            assert.are.same(augend:add("1st", -1, 1), { text = "0th", cursor = 1 })
            assert.are.same(augend:add("1st", -2, 1), { text = "-1st", cursor = 1 })
            assert.are.same(augend:add("1st", -3, 1), { text = "-2nd", cursor = 1 })
            assert.are.same(augend:add("1st", -4, 1), { text = "-3rd", cursor = 1 })
            assert.are.same(augend:add("1st", -5, 1), { text = "-4th", cursor = 1 })

            assert.are.same(augend:add("0th", -1, 1), { text = "-1st", cursor = 1 })
            assert.are.same(augend:add("-1st", -1, 1), { text = "-2nd", cursor = 1 })
            assert.are.same(augend:add("-2nd", -1, 1), { text = "-3rd", cursor = 1 })
            assert.are.same(augend:add("-3rd", -1, 1), { text = "-4th", cursor = 1 })
            assert.are.same(augend:add("-9th", -1, 1), { text = "-10th", cursor = 1 })

            assert.are.same(augend:add("-10th", -1, 1), { text = "-11th", cursor = 1 })
            assert.are.same(augend:add("-11th", -1, 1), { text = "-12th", cursor = 1 })
            assert.are.same(augend:add("-12th", -1, 1), { text = "-13th", cursor = 1 })

            assert.are.same(augend:add("-20th", -1, 1), { text = "-21st", cursor = 1 })
            assert.are.same(augend:add("-21st", -1, 1), { text = "-22nd", cursor = 1 })
            assert.are.same(augend:add("-22nd", -1, 1), { text = "-23rd", cursor = 1 })

            assert.are.same(augend:add("-99th", -1, 1), { text = "-100th", cursor = 1 })
            assert.are.same(augend:add("-999th", -1, 1), { text = "-1000th", cursor = 1 })
        end)
    end)
end)
