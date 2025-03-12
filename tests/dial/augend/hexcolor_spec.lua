local hexcolor = require("dial.augend").hexcolor

describe("Test of hex colors", function()
    describe("config", function()
        describe("case", function()
            it('"prefer_lower" is the default', function()
                local augend = hexcolor.new()
                assert.are.same(augend.config, { case = "prefer_lower" })
            end)

            it('"upper" is accepted', function()
                local augend = hexcolor.new { case = "upper" }
                assert.are.same(augend.config, { case = "upper" })
            end)

            it('"lower" is accepted', function()
                local augend = hexcolor.new { case = "lower" }
                assert.are.same(augend.config, { case = "lower" })
            end)

            it('"prefer_upper" is accepted', function()
                local augend = hexcolor.new { case = "prefer_upper" }
                assert.are.same(augend.config, { case = "prefer_upper" })
            end)

            it('"prefer_lower" is accepted', function()
                local augend = hexcolor.new { case = "prefer_lower" }
                assert.are.same(augend.config, { case = "prefer_lower" })
            end)

            it("rejects other values", function()
                assert.has_error(function()
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    hexcolor.new { case = "invalid" }
                end)
            end)
        end)
    end)

    describe("find_stateful", function()
        local augend = hexcolor.new()

        it("can find hex colors", function()
            --            123456789012
            local line = "yay: #000000"
            local pos = { from = 6, to = 12 }
            assert.are.same(augend:find_stateful(line, 01), pos)
            assert.are.same(augend:find_stateful(line, 01), pos)
            assert.are.same(augend:find_stateful(line, 01), pos)
            assert.are.same(augend:find_stateful(line, 01), pos)
            assert.are.same(augend:find_stateful(line, 01), pos)
            assert.are.same(augend:find_stateful(line, 02), pos)
            assert.are.same(augend:find_stateful(line, 09), pos)
            assert.are.same(augend:find_stateful(line, 12), pos)
        end)

        it("sets kind based on cursor position", function()
            --            1234567890
            local line = "x: #000000 -- y"
            augend:find_stateful(line, 1)
            assert.are.same(augend.kind, "all")
            augend:find_stateful(line, 4)
            assert.are.same(augend.kind, "all")
            augend:find_stateful(line, 5)
            assert.are.same(augend.kind, "r")
            augend:find_stateful(line, 6)
            assert.are.same(augend.kind, "r")
            augend:find_stateful(line, 7)
            assert.are.same(augend.kind, "g")
            augend:find_stateful(line, 8)
            assert.are.same(augend.kind, "g")
            augend:find_stateful(line, 9)
            assert.are.same(augend.kind, "b")
            augend:find_stateful(line, 10)
            assert.are.same(augend.kind, "b")
        end)

        it("finds the next color after the cursor position", function()
            --                     1         2         3
            --            12345678901234567890123456789012
            local line = "color1: #000000, color2: #c0ffee -- comment"
            local pos1 = { from = 09, to = 15 }
            local pos2 = { from = 26, to = 32 }
            assert.are.same(augend:find_stateful(line, 01), pos1)
            assert.are.same(augend:find_stateful(line, 15), pos1)
            assert.are.same(augend:find_stateful(line, 16), pos2)
            assert.are.same(augend:find_stateful(line, 32), pos2)
            assert.are.same(augend:find_stateful(line, 33), nil)
        end)

        it("does not find false positives", function()
            assert.is_nil(augend:find_stateful("nay", 1))
            assert.is_nil(augend:find_stateful("nay: #01234", 1)) -- too short
            assert.is_nil(augend:find_stateful("#coffee", 1)) -- o instead of 0
            assert.is_nil(augend:find_stateful("234269", 1)) -- no #
        end)
    end)

    describe("add", function()
        describe("case = upper", function()
            local augend = hexcolor.new { case = "upper" }

            it("can increment the red hex value", function()
                augend.kind = "r"
                assert.are.same(augend:add("#000000", 001), { text = "#010000", cursor = 3 })
                assert.are.same(augend:add("#000000", 016), { text = "#100000", cursor = 3 })
                assert.are.same(augend:add("#000000", 255), { text = "#FF0000", cursor = 3 })
                assert.are.same(augend:add("#000000", 256), { text = "#FF0000", cursor = 3 })
            end)

            it("can increment the green hex value", function()
                augend.kind = "g"
                assert.are.same(augend:add("#000000", 001), { text = "#000100", cursor = 5 })
                assert.are.same(augend:add("#000000", 016), { text = "#001000", cursor = 5 })
                assert.are.same(augend:add("#000000", 255), { text = "#00FF00", cursor = 5 })
                assert.are.same(augend:add("#000000", 256), { text = "#00FF00", cursor = 5 })
            end)

            it("can increment the blue hex value", function()
                augend.kind = "b"
                assert.are.same(augend:add("#000000", 001), { text = "#000001", cursor = 7 })
                assert.are.same(augend:add("#000000", 016), { text = "#000010", cursor = 7 })
                assert.are.same(augend:add("#000000", 255), { text = "#0000FF", cursor = 7 })
                assert.are.same(augend:add("#000000", 256), { text = "#0000FF", cursor = 7 })
            end)

            it("can increments all hex values", function()
                augend.kind = "all"
                assert.are.same(augend:add("#000000", 001), { text = "#010101", cursor = 1 })
                assert.are.same(augend:add("#000000", 016), { text = "#101010", cursor = 1 })
                assert.are.same(augend:add("#000000", 255), { text = "#FFFFFF", cursor = 1 })
                assert.are.same(augend:add("#000000", 256), { text = "#FFFFFF", cursor = 1 })
            end)

            it("converts to upper case", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1bff", 1), { text = "#0B1CFF", cursor = 1 })
                assert.are.same(augend:add("#0a1BFf", 1), { text = "#0B1CFF", cursor = 1 })
                assert.are.same(augend:add("#0A1BFF", 1), { text = "#0B1CFF", cursor = 1 })
            end)

            it("uses upper case when initial value has no letter", function()
                augend.kind = "all"
                assert.are.same(augend:add("#059799", 5), { text = "#0A9C9E", cursor = 1 })
            end)
        end)

        describe("case = lower", function()
            local augend = hexcolor.new { case = "lower" }

            it("can increment the red hex value", function()
                augend.kind = "r"
                assert.are.same(augend:add("#000000", 001), { text = "#010000", cursor = 3 })
                assert.are.same(augend:add("#000000", 016), { text = "#100000", cursor = 3 })
                assert.are.same(augend:add("#000000", 255), { text = "#ff0000", cursor = 3 })
                assert.are.same(augend:add("#000000", 256), { text = "#ff0000", cursor = 3 })
            end)

            it("can increment the green hex value", function()
                augend.kind = "g"
                assert.are.same(augend:add("#000000", 001), { text = "#000100", cursor = 5 })
                assert.are.same(augend:add("#000000", 016), { text = "#001000", cursor = 5 })
                assert.are.same(augend:add("#000000", 255), { text = "#00ff00", cursor = 5 })
                assert.are.same(augend:add("#000000", 256), { text = "#00ff00", cursor = 5 })
            end)

            it("can increment the blue hex value", function()
                augend.kind = "b"
                assert.are.same(augend:add("#000000", 001), { text = "#000001", cursor = 7 })
                assert.are.same(augend:add("#000000", 016), { text = "#000010", cursor = 7 })
                assert.are.same(augend:add("#000000", 255), { text = "#0000ff", cursor = 7 })
                assert.are.same(augend:add("#000000", 256), { text = "#0000ff", cursor = 7 })
            end)

            it("can increments all hex values", function()
                augend.kind = "all"
                assert.are.same(augend:add("#000000", 001), { text = "#010101", cursor = 1 })
                assert.are.same(augend:add("#000000", 016), { text = "#101010", cursor = 1 })
                assert.are.same(augend:add("#000000", 255), { text = "#ffffff", cursor = 1 })
                assert.are.same(augend:add("#000000", 256), { text = "#ffffff", cursor = 1 })
            end)

            it("converts to lower case", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1bff", 1), { text = "#0b1cff", cursor = 1 })
                assert.are.same(augend:add("#0a1BFf", 1), { text = "#0b1cff", cursor = 1 })
                assert.are.same(augend:add("#0A1BFF", 1), { text = "#0b1cff", cursor = 1 })
            end)

            it("uses lower case when initial value has no letter", function()
                augend.kind = "all"
                assert.are.same(augend:add("#059799", 5), { text = "#0a9c9e", cursor = 1 })
            end)
        end)

        describe("case = prefer_upper", function()
            local augend = hexcolor.new { case = "prefer_upper" }

            it("can increment the red hex value", function()
                augend.kind = "r"
                assert.are.same(augend:add("#000000", 001), { text = "#010000", cursor = 3 })
                assert.are.same(augend:add("#000000", 016), { text = "#100000", cursor = 3 })
                assert.are.same(augend:add("#000000", 255), { text = "#FF0000", cursor = 3 })
                assert.are.same(augend:add("#000000", 256), { text = "#FF0000", cursor = 3 })
            end)

            it("can increment the green hex value", function()
                augend.kind = "g"
                assert.are.same(augend:add("#000000", 001), { text = "#000100", cursor = 5 })
                assert.are.same(augend:add("#000000", 016), { text = "#001000", cursor = 5 })
                assert.are.same(augend:add("#000000", 255), { text = "#00FF00", cursor = 5 })
                assert.are.same(augend:add("#000000", 256), { text = "#00FF00", cursor = 5 })
            end)

            it("can increment the blue hex value", function()
                augend.kind = "b"
                assert.are.same(augend:add("#000000", 001), { text = "#000001", cursor = 7 })
                assert.are.same(augend:add("#000000", 016), { text = "#000010", cursor = 7 })
                assert.are.same(augend:add("#000000", 255), { text = "#0000FF", cursor = 7 })
                assert.are.same(augend:add("#000000", 256), { text = "#0000FF", cursor = 7 })
            end)

            it("can increments all hex values", function()
                augend.kind = "all"
                assert.are.same(augend:add("#000000", 001), { text = "#010101", cursor = 1 })
                assert.are.same(augend:add("#000000", 016), { text = "#101010", cursor = 1 })
                assert.are.same(augend:add("#000000", 255), { text = "#FFFFFF", cursor = 1 })
                assert.are.same(augend:add("#000000", 256), { text = "#FFFFFF", cursor = 1 })
            end)

            it("keeps lower case if existing color has lower case letters", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1bff", 1), { text = "#0b1cff", cursor = 1 })
            end)

            it("uses upper case when initial value has upper case letters", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0A1BFF", 1), { text = "#0B1CFF", cursor = 1 })
            end)

            it("uses upper case when initial value has no letter", function()
                augend.kind = "all"
                assert.are.same(augend:add("#059799", 1), { text = "#06989A", cursor = 1 })
                assert.are.same(augend:add("#059799", 5), { text = "#0A9C9E", cursor = 1 })
            end)

            it("converts to upper case if existing color has mixed casing", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1BFf", 1), { text = "#0B1CFF", cursor = 1 })
            end)
        end)

        describe("case = prefer_lower", function()
            local augend = hexcolor.new { case = "prefer_lower" }

            it("can increment the red hex value", function()
                augend.kind = "r"
                assert.are.same(augend:add("#000000", 001), { text = "#010000", cursor = 3 })
                assert.are.same(augend:add("#000000", 016), { text = "#100000", cursor = 3 })
                assert.are.same(augend:add("#000000", 255), { text = "#ff0000", cursor = 3 })
                assert.are.same(augend:add("#000000", 256), { text = "#ff0000", cursor = 3 })
            end)

            it("can increment the green hex value", function()
                augend.kind = "g"
                assert.are.same(augend:add("#000000", 001), { text = "#000100", cursor = 5 })
                assert.are.same(augend:add("#000000", 016), { text = "#001000", cursor = 5 })
                assert.are.same(augend:add("#000000", 255), { text = "#00ff00", cursor = 5 })
                assert.are.same(augend:add("#000000", 256), { text = "#00ff00", cursor = 5 })
            end)

            it("can increment the blue hex value", function()
                augend.kind = "b"
                assert.are.same(augend:add("#000000", 001), { text = "#000001", cursor = 7 })
                assert.are.same(augend:add("#000000", 016), { text = "#000010", cursor = 7 })
                assert.are.same(augend:add("#000000", 255), { text = "#0000ff", cursor = 7 })
                assert.are.same(augend:add("#000000", 256), { text = "#0000ff", cursor = 7 })
            end)

            it("can increments all hex values", function()
                augend.kind = "all"
                assert.are.same(augend:add("#000000", 001), { text = "#010101", cursor = 1 })
                assert.are.same(augend:add("#000000", 016), { text = "#101010", cursor = 1 })
                assert.are.same(augend:add("#000000", 255), { text = "#ffffff", cursor = 1 })
                assert.are.same(augend:add("#000000", 256), { text = "#ffffff", cursor = 1 })
            end)

            it("keeps upper case if existing color has upper case letters", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0A1BFF", 1), { text = "#0B1CFF", cursor = 1 })
            end)

            it("uses lower case when initial value has lower case letters", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1bff", 1), { text = "#0b1cff", cursor = 1 })
            end)

            it("uses lower case when initial value has no letter", function()
                augend.kind = "all"
                assert.are.same(augend:add("#059799", 1), { text = "#06989a", cursor = 1 })
                assert.are.same(augend:add("#059799", 5), { text = "#0a9c9e", cursor = 1 })
            end)

            it("converts to lower case if existing color has mixed casing", function()
                augend.kind = "all"
                assert.are.same(augend:add("#0a1BFf", 1), { text = "#0b1cff", cursor = 1 })
            end)
        end)
    end)
end)
