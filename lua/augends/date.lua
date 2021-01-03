local common = require("./augends/common")
local util = require("./util")

local M = {}

M.weekday_ja = common.enum_cyclic("date.weekday_ja", {"日", "月", "火", "水", "木", "金", "土"})

return M
