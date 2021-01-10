local common = require("./augends/common")
local util = require("./util")

local M = {}

M["%ja"] = common.enum_cyclic{
    name = "date['%ja']",
    strlist = {"日", "月", "火", "水", "木", "金", "土"},
}
M["%jA"] = common.enum_cyclic{
    name = "date['%jA']",
    strlist = { '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日', },
}

M["%Y/%m/%d"] = {
    name = "date['%Y/%m/%d']",
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

M["%Y-%m-%d"] = {
    name = "date['%Y-%m-%d']",
    desc = "standard date %Y-%m-%d",

    find = common.find_pattern("%d%d%d%d-%d%d-%d%d"),
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
        text = os.date("%Y-%m-%d", date)
        return cursor, text
    end
}

M["%Y年%m月%d日"] = {
    name = "date['%Y年%m月%d日']",
    desc = "standard date %Y年%m月%d日",

    find = common.find_pattern("(%d%d%d%d)年(%d%d?)月(%d%d?)日"),
    add = function(cursor, text, addend)
        _, _, year_str, month_str, day_str = text:find("(%d%d%d%d)年(%d%d)月(%d%d)日")
        year = tonumber(year_str)
        month = tonumber(month_str)
        day = tonumber(day_str)
        if cursor >= 1 and cursor <= 7 then
            year = year + addend
            cursor = 4
        elseif cursor >= 8 and cursor <= 12 then
            month = month + addend
            cursor = 9
        else
            day = day + addend
            cursor = 14
        end
        local date = os.time{year=year, month=month, day=day}
        text = os.date("%Y年%m月%d日", date)
        return cursor, text
    end
}

M["%H:%M:%S"] = {
    name = "date['%H:%M:%S']",
    desc = "standard time %H:%M:%S",

    find = common.find_pattern("%d%d:%d%d:%d%d"),
    add = function(cursor, text, addend)
        local hour = tonumber(text:sub(1, 2))
        local minute = tonumber(text:sub(4, 5))
        local second = tonumber(text:sub(7, 8))
        if cursor >= 1 and cursor <= 2 then
            hour = hour + addend
            cursor = 2
        elseif cursor >= 3 and cursor <= 5 then
            minute = minute + addend
            cursor = 5
        else
            second = second + addend
            cursor = 8
        end
        local date = os.time{year=2000, month=1, day=1, hour=hour, min=minute, sec=second}
        text = os.date("%H:%M:%S", date)
        return cursor, text
    end
}

M["%H:%M"] = {
    name = "date['%H:%M']",
    desc = "standard time %H:%M",

    find = common.find_pattern("%d%d:%d%d"),
    add = function(cursor, text, addend)
        local hour = tonumber(text:sub(1, 2))
        local minute = tonumber(text:sub(4, 5))
        if cursor >= 1 and cursor <= 2 then
            hour = hour + addend
            cursor = 2
        else
            minute = minute + addend
            cursor = 5
        end
        local date = os.time{year=2000, month=1, day=1, hour=hour, min=minute, sec=second}
        text = os.date("%H:%M", date)
        return cursor, text
    end
}


return M
