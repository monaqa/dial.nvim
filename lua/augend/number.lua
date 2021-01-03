local augend = require("../augend")

-- decimal_integer
local decimal_integer = {
    find = augend.find_pattern("-?%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n + addend
        text = tostring(n)
        cursor = #text
        return cursor, text
    end,
}

local decimal_natural_number = {
    find = augend.find_pattern("%d+"),

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

local hex_number = {
    find = augend.find_pattern("0x[0-9a-fA-F]+"),

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

return {
    decimal_integer = decimal_integer,
    decimal_natural_number = decimal_natural_number,
    hex_number = hex_number,
}
