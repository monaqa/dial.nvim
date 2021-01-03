local common = require("./augends/common")
local util = require("./util")

local M = {}

M.alph_small = common.enum_sequence(
    "char.alph_small",
    { "a", "b", "c", "d", "e", "f", "g",
        "h", "i", "j", "k", "l", "m", "n",
        "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", }
    )

M.alph_capital = common.enum_sequence(
    "char.alph_capital",
    { "A", "B", "C", "D", "E", "F", "G",
        "H", "I", "J", "K", "L", "M", "N",
        "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", }
    )

return M
