local common = require("./augends/common")

local M = {}

-- 十進整数。
-- -2, -1, 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M.decimal = {
    name = "number.decimal",
    desc = "decimal number (0, 192, -3, etc.)",

    find = common.find_pattern("-?%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n + addend
        text = tostring(n)
        cursor = #text
        return cursor, text
    end,
}

-- 十進の非負整数。
-- 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M.decimal_natural = {
    name = "number.decimal_natural",
    desc = "decimal natural number (0, 1, 2, ..., 9, 10, 11, ...)",

    find = common.find_pattern("%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = tostring(n)
        cursor = #text
        return cursor, text
    end,
}

-- 十六進の非負整数。
-- 0x0, 0x01, 0x1f1f などにマッチする。
M.hex = {
    name = "number.hex",
    desc = "hex number (e.g. 0x3f)",

    find = common.find_pattern("0x[0-9a-fA-F]+"),

    add = function(cusror, text, addend)
        local n = tonumber(text, 16)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0x" .. string.format("%x", n)
        cursor = #text
        return cursor, text
    end,
}

return M
