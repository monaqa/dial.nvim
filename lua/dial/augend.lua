local constant = require("dial.augend.constant").new
local date = require("dial.augend.date").new
local hexcolor = require("dial.augend.hexcolor").new
local integer = require("dial.augend.integer").new

-- local decimal = integer{}

return {
    constant = constant,
    date = date,
    hexcolor = hexcolor,
    integer = integer,
}
