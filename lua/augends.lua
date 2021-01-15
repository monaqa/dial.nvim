local util = require("./util")
local common = require("./common")

local M = {}

-- 十進整数。
-- -2, -1, 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M['number#decimal'] = {
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

-- 十進の非負整数。
-- 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M['number#decimal#int'] = {
    desc = "decimal integer including negative (0, 192, -3, etc.)",

    find = common.find_pattern("-?%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n + addend
        text = tostring(n)
        cursor = #text
        return cursor, text
    end,
}

-- 固定された桁の十進非負整数。
-- 桁は0埋めする。
M['number#decimal#fixed#zero'] = {
    desc = "fixed-digit decimal natural number (e.g. 00, 01, 02, ..., 97, 98, 99)",

    find = common.find_pattern("%d+"),

    add = function(cusror, text, addend)
        local n_digit = #text
        local n = tonumber(text)
        n = n + addend
        if n < 0 then n = 0 end
        if n > (10 ^ n_digit) - 1 then n = (10 ^ n_digit) - 1 end
        text = ("%0" .. n_digit .. "d"):format(n)
        cursor = n_digit
        return cursor, text
    end,
}

-- 十六進の非負整数。
-- 0x0, 0x01, 0x1f1f などにマッチする。
M['number#hex'] = {
    desc = "hex number (e.g. 0x3f)",

    find = common.find_pattern("0x[0-9a-fA-F]+"),

    add = function(cusror, text, addend)
        local n = tonumber(text, 16)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0x" .. ("%x"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 八進の非負整数。
M['number#octal'] = {
    desc = "octal number (e.g. 037)",

    find = common.find_pattern("0[0-7]+"),

    add = function(cusror, text, addend)
        local wid = #text
        local n = tonumber(text, 8)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0" .. util.tostring_with_base(n, 8, wid - 1, "0")
        cursor = #text
        return cursor, text
    end,
}

-- バイナリの非負整数。
M['number#binary'] = {
    desc = "binary number (e.g. 0b00110101)",

    find = common.find_pattern("0b[01]+"),

    add = function(cusror, text, addend)
        local wid = #text
        local n = tonumber(text:sub(3), 2)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0b" .. tostring_with_base(n, 2, wid - 2, "0")
        cursor = #text
        return cursor, text
    end,
}

M['date#[%ja]'] = common.enum_cyclic{
    name = "date['%ja']",
    strlist = {"日", "月", "火", "水", "木", "金", "土"},
}

M['date#[%jA]'] = common.enum_cyclic{
    name = "date['%jA']",
    strlist = { '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日', },
    ptn_format = "\\C\\M\\(%s\\)",
}


return M
