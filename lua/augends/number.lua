local common = require("./augends/common")
local util = require("./util")

local M = {}

local function tostring_with_base(n, b, wid, pad)
    n = math.floor(n)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    local t = {}
    if n < 0 then
        -- be positive
        n = -n
    end
    repeat
        local d = (n % b) + 1
        n = math.floor(n / b)
        table.insert(t, 1, digits:sub(d,d))
    until n == 0
    text = table.concat(t,"")
    if wid then
        if #text < wid then
            if pad == nil then
                pad = " "
            end
            padding = pad:rep(wid - #text)
            return padding .. text
        end
    end
    return text
end

-- 十進整数。
-- -2, -1, 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M.decimal_integer = {
    name = "number.decimal_integer",
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

-- 十進の非負整数。
-- 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M.decimal = {
    name = "number.decimal",
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

-- 固定された桁の十進非負整数。
-- 桁は0埋めする。
M.decimal_fixeddigit_zero = {
    name = "number.decimal_fixeddigit_zero",
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

-- 固定された桁の十進非負整数。
-- 桁は半角空白で埋める。
M.decimal_fixeddigit_space = {
    name = "number.decimal_fixeddigit_space",
    desc = "fixed-digit decimal natural number (e.g. ␣0, ␣1, ␣2, ..., 97, 98, 99)",

    find = common.find_pattern(" *%d+"),

    add = function(cusror, text, addend)
        local n_digit = #text
        local n = tonumber(text)
        n = n + addend
        if n < 0 then n = 0 end
        if n > (10 ^ n_digit) - 1 then n = (10 ^ n_digit) - 1 end
        text = ("%" .. n_digit .. "d"):format(n)
        cursor = n_digit
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
        text = "0x" .. ("%x"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 八進の非負整数。
M.octal = {
    name = "number.octal",
    desc = "octal number (e.g. 037)",

    find = common.find_pattern("0[0-7]+"),

    add = function(cusror, text, addend)
        local wid = #text
        local n = tonumber(text, 8)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0" .. tostring_with_base(n, 8, wid - 1, "0")
        cursor = #text
        return cursor, text
    end,
}

-- バイナリの非負整数。
M.binary = {
    name = "number.binary",
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

return M
