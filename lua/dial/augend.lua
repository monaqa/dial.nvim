local case = require "dial.augend.case"
local constant = require "dial.augend.constant"
local date = require "dial.augend.date"
local decimal_fraction = require "dial.augend.decimal_fraction"
local hexcolor = require "dial.augend.hexcolor"
local integer = require "dial.augend.integer"
local semver = require "dial.augend.semver"
local user = require "dial.augend.user"
local paren = require "dial.augend.paren"
local misc = require "dial.augend.misc"

return {
    case = case,
    constant = constant,
    date = date,
    decimal_fraction = decimal_fraction,
    hexcolor = hexcolor,
    integer = integer,
    semver = semver,
    user = user,
    paren = paren,
    misc = misc,
}
