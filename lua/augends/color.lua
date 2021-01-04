local common = require("./augends/common")
local util = require("./util")

local M = {}

local function cast_u8(n)
    if n <= 0 then
        return 0
    end
    if n >= 255 then
        return 255
    end
    return n
end

-- hex 表示の html color。
M.hex = {
    name = "color.hex",
    desc = "HTML color (e.g. #12ab0f)",

    find = common.find_pattern("#%x%x%x%x%x%x"),

    add = function(cursor, text, addend)
        local r = tonumber(text:sub(2, 3), 16)
        local g = tonumber(text:sub(4, 5), 16)
        local b = tonumber(text:sub(6, 7), 16)
        if cursor <= 1 then
            r = cast_u8(r + addend)
            g = cast_u8(g + addend)
            b = cast_u8(b + addend)
            cursor = 1
        elseif cursor == 2 or cursor == 3 then
            r = cast_u8(r + addend)
            cursor = 3
        elseif cursor == 4 or cursor == 5 then
            g = cast_u8(g + addend)
            cursor = 5
        elseif cursor == 6 or cursor == 7 then
            b = cast_u8(b + addend)
            cursor = 7
        end
        text = "#" .. string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
        return cursor, text
    end,
}

return M
