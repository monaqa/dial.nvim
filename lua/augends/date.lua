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
    ptn_format = "\\C\\M\\(%s\\)",
}

M["%Y/%m/%d"] = {
    name = "date['%Y/%m/%d']",
    desc = "standard date %Y/%m/%d",

    find = common.find_pattern("%d%d%d%d/%d%d/%d%d"),
    add = function(cursor, text, addend)
        local year = tonumber(text:sub(1, 4))
        local month = tonumber(text:sub(6, 7))
        local day = tonumber(text:sub(9, 10))
        if cursor == nil then cursor = 10 end  -- default: day
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

M["%m/%d"] = {
    name = "date['%m/%d']",
    desc = "standard date %m/%d (01/01, 02/28, 12/25, etc.)",

    find = common.find_pattern("%d%d/%d%d"),
    add = function(cursor, text, addend)
        local month = tonumber(text:sub(1, 2))
        local day = tonumber(text:sub(4, 5))
        if cursor == nil then cursor = 5 end  -- default: day
        if cursor >= 1 and cursor <= 2 then
            month = month + addend
            cursor = 2
        else
            day = day + addend
            cursor = 5
        end
        local thisyear = os.date("*t").year
        local date = os.time{year=thisyear, month=month, day=day}
        text = os.date("%m/%d", date)
        return cursor, text
    end
}

M["%-m/%-d"] = {
    name = "date['%-m/%-d']",
    desc = "standard date %-m/%-d (1/1, 2/28, 12/25, etc.)",

    find = function(cursor, line)
        -- 1/4 などに反応させたいが、これは必ずしも日付を表すとは限らない。
        -- 誤反応を減らすため、日付として有効でない数字の組（13/32 など）は棄却する。
        local range = common.find_pattern("%d%d?/%d%d?")(cursor, line)
        if range == nil then
            return nil
        end
        local text = line:sub(range.from, range.to)
        local strips = vim.split(text, "/")
        local month, day = tonumber(strips[1]), tonumber(strips[2])

        -- check whether a valid date or not
        if month == 0 or month > 12 or day == 0 then
            return nil
        end
        local month_day_29 = (month == 2) and day <= 29
        local month_day_30 = vim.tbl_contains({4, 6, 9, 11}, month) and day <= 30
        local month_day_31 = vim.tbl_contains({1, 3, 5, 7, 8, 10, 12}, month) and day <= 31

        if month_day_29 or month_day_30 or month_day_31 then
            return range
        end

        return nil
    end,
    add = function(cursor, text, addend)
        local _, _, month_str, day_str = text:find("(%d%d?)/(%d%d?)")
        local month_s, month_e = 1, #month_str
        local day_s, day_e = #month_str + 2, #text
        local month, day = tonumber(month_str), tonumber(day_str)
        local objective

        if cursor == nil then cursor = day_e end  -- default: day
        if cursor >= month_s and cursor <= month_e then
            objective = "month"
            month = month + addend
        else
            objective = "day"
            day = day + addend
        end
        local thisyear = os.date("*t").year
        local date = os.time{year=thisyear, month=month, day=day}
        text = os.date("%-m/%-d", date)

        -- determine cursor position
        if objective == "month" then
            if tbl_date.month >= 10 then
                cursor = 2
            else
                cursor = 1
            end
        else
            cursor = #text
        end

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
        if cursor == nil then cursor = 10 end  -- default: day
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

M["%Y年%-m月%-d日"] = {
    name = "date['%Y年%-m月%-d日']",
    desc = "standard date %Y年%-m月%-d日",

    find = common.find_pattern("(%d%d%d%d)年(%d%d?)月(%d%d?)日"),
    add = function(cursor, text, addend)
        local _, _, year_str, month_str, day_str = text:find("(%d%d%d%d)年(%d%d?)月(%d%d?)日")
        local year_s, year_e = 1, 7
        local month_s, month_e = 8, #month_str + 10
        local day_s, day_e = #month_str + 11, #text
        local year, month, day = tonumber(year_str), tonumber(month_str), tonumber(day_str)
        local objective

        if cursor == nil then cursor = day_e end  -- default: day
        if cursor >= year_s and cursor <= year_e then
            objective = "year"
            year = year + addend
        elseif cursor >= month_s and cursor <= month_e then
            objective = "month"
            month = month + addend
        else
            objective = "day"
            day = day + addend
        end
        local date = os.time{year=year, month=month, day=day}
        local tbl_date = os.date("*t", date)
        text = os.date("%Y年%-m月%-d日", date)

        -- determine cursor position
        if objective == "year" then
            cursor = 4
        elseif objective == "month" then
            if tbl_date.month >= 10 then
                cursor = 9 -- = %Y(4) + 年(3) + %-m(2)
            else
                cursor = 8 -- = %Y(4) + 年(3) + %-m(1)
            end
        else
            cursor = #text
        end

        return cursor, text
    end
}

M["%Y年%-m月%-d日(%ja)"] = {
    name = "date['%Y年%-m月%-d日(%ja)']",
    desc = "standard date %Y年%-m月%-d日(%ja), e.g. 2021年1月13日(水)",

    find = common.find_pattern_regex([[\v\d{4}年\d{1,2}月\d{1,2}日\((日|月|火|水|木|金|土)\)]]),
    add = function(cursor, text, addend)
        local _, _, year_str, month_str, day_str = text:find("(%d%d%d%d)年(%d%d?)月(%d%d?)日")
        local year_s, year_e = 1, 7
        local month_s, month_e = 8, #month_str + 10
        local day_s, day_e = #month_str + 11, #text
        local year, month, day = tonumber(year_str), tonumber(month_str), tonumber(day_str)
        local objective

        if cursor == nil then cursor = day_e end  -- default: day
        if cursor >= year_s and cursor <= year_e then
            objective = "year"
            year = year + addend
        elseif cursor >= month_s and cursor <= month_e then
            objective = "month"
            month = month + addend
        else
            objective = "day"
            day = day + addend
        end
        local date = os.time{year=year, month=month, day=day}
        local date_str = os.date("%Y年%-m月%-d日", date)
        local tbl_date = os.date("*t", date)
        local weekday = {"日", "月", "火", "水", "木", "金", "土"}
        local weekday_str = weekday[tbl_date.wday]
        text = date_str .. ("(%s)"):format(weekday_str)

        -- determine cursor position
        if objective == "year" then
            cursor = 4
        elseif objective == "month" then
            if tbl_date.month >= 10 then
                cursor = 9 -- = %Y(4) + 年(3) + %-m(2)
            else
                cursor = 8 -- = %Y(4) + 年(3) + %-m(1)
            end
        else
            cursor = #text - 8
        end

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
        if cursor == nil then cursor = 8 end  -- default: second
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
        if cursor == nil then cursor = 5 end  -- default: second
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
