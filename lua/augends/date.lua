local common = require("./augends/common")
local util = require("./util")

local M = {}

M.weekday_ja = common.enum_cyclic("date.weekday_ja", {"日", "月", "火", "水", "木", "金", "土"})

M.date = {
    name = "date.date",
    desc = "standard date %Y/%m/%d",

    find = common.find_pattern("%d%d%d%d/%d%d/%d%d"),
    add = function(cursor, text, addend)
        local year = tonumber(text:sub(1, 4))
        local month = tonumber(text:sub(6, 7))
        local day = tonumber(text:sub(9, 10))
        if cursor >= 1 and cursor <= 4 then
            year = year + addend
            cursor = 4
        elseif cursor >= 5 and cursor <= 7 then
            month = month + addend
            cursor = 7
        else
            day = day + addend
            cursor = 10
        end
        local date = os.time{year=year, month=month, day=day}
        text = os.date("%Y/%m/%d", date)
        return cursor, text
    end
}

return M
