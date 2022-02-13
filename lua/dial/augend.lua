local constant = require("dial.augend.constant").new
local date = require("dial.augend.date").new
local hexcolor = require("dial.augend.hexcolor").new
local integer = require("dial.augend.integer").new

-- local decimal = integer{}
local alias = {
    decimal = integer{},
    decimal_int = integer{ natural = false },
    binary = integer{ radix = 2, prefix = "0b", natural = true },
    octal = integer{ radix = 8, prefix = "0o", natural = true },
    hex = integer{ radix = 16, prefix = "0x", natural = true },
    bool = constant{ elements = {"true", "false"} },
    alpha = constant{ elements = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    }, cyclic = false},
    Alpha = constant{ elements = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    }, cyclic = false},
}

return {
    constant = constant,
    date = date,
    hexcolor = hexcolor,
    integer = integer,
    alias = alias,
}
