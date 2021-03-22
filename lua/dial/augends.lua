local util = require("dial/util")
local common = require("dial/common")

local M = {}

-- 十進の非負整数。
-- 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M['number#decimal'] = {
    desc = "decimal natural number (0, 1, 2, ..., 9, 10, 11, ...)",

    find = common.find_pattern("%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        local n_string_digit = text:len()
        local n_actual_digit = tostring(n):len()
        n = n + addend
        if n < 0 then
            n = 0
        end
        if n_string_digit == n_actual_digit then
            -- 増減前の数字が0か0始まりでない数字だったら
            text = ("%d"):format(n)
        else
            -- 増減前の数字が0始まりの正の数だったら
            text = ("%0" .. n_string_digit .. "d"):format(n)
        end
        cursor = #text
        return cursor, text
    end,
}

-- 十進整数。
-- -2, -1, 0, 1, 2, ..., 9, 10, 11, ...  にマッチする。
M['number#decimal#int'] = {
    desc = "decimal integer including negative (0, 192, -3, etc.)",

    find = common.find_pattern("-?%d+"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n + addend
        text = tostring(n)
        cursor = #text
        return cursor, text
    end,
}

-- 固定された桁の十進非負整数。
-- 桁は0埋めする。
M['number#decimal#fixed#zero'] = {
    desc = "fixed-digit decimal natural number (e.g. 00, 01, 02, ..., 97, 98, 99)",

    find = common.find_pattern("%d+"),

    add = function(cusror, text, addend)
        local n_digit = #text
        local n = tonumber(text)
        n = n + addend
        if n < 0 then n = 0 end
        if n > (10 ^ n_digit) - 1 then n = (10 ^ n_digit) - 1 end
        text = ("%0" .. n_digit .. "d"):format(n)
        cursor = n_digit
        return cursor, text
    end,
}

-- 固定された桁の十進非負整数。
-- 桁は0埋めする。
M['number#decimal#fixed#space'] = {
    desc = "fixed-digit decimal natural number (e.g. ␣0, ␣1, ␣2, ..., 97, 98, 99)",

    find = common.find_pattern(" *%d+"),

    add = function(cusror, text, addend)
        local n_digit = #text
        local n = tonumber(text)
        n = n + addend
        if n < 0 then n = 0 end
        if n > (10 ^ n_digit) - 1 then n = (10 ^ n_digit) - 1 end
        text = ("%" .. n_digit .. "d"):format(n)
        cursor = n_digit
        return cursor, text
    end,
}

-- 小数。
M['number#decimal#multi#smart'] = {
    desc = "smart multiply (same basic, but <C-a> becomes 10 times)",

    find = common.find_pattern("%d+%.?%d*"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        if addend == 0 then  -- ありえないけど
            addend = 1
        end
        if addend == 1 then  -- 引数がないときは 10 として扱う
            addend = 10
        elseif addend == -1 then
            addend = 0.1
        end
        if addend < 0 then
            addend = -1 / addend
        end
        n = n * addend
        text = ("%g"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 小数。
M['number#decimal#multi#basic'] = {
    desc = "basic multiply (multiply by 'addend')",

    find = common.find_pattern("%d+%.?%d*"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        if addend == 0 then  -- ありえないけど
            addend = 1
        end
        if addend < 0 then
            addend = -1 / addend
        end
        n = n * addend
        text = ("%g"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 小数。
M['number#decimal#multi#power10'] = {
    desc = "multiply by 10",

    find = common.find_pattern("%d+%.?%d*"),

    add = function(cusror, text, addend)
        local n = tonumber(text)
        n = n * (10 ^ addend)
        text = ("%g"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 十六進の非負整数。
-- 0x0, 0x01, 0x1f1f などにマッチする。
M['number#hex'] = {
    desc = "hex number (e.g. 0x3f)",

    find = common.find_pattern("0x[0-9a-fA-F]+"),

    add = function(cusror, text, addend)
        local n = tonumber(text, 16)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0x" .. ("%x"):format(n)
        cursor = #text
        return cursor, text
    end,
}

-- 八進の非負整数。
M['number#octal'] = {
    desc = "octal number (e.g. 037)",

    find = common.find_pattern("0[0-7]+"),

    add = function(cusror, text, addend)
        local wid = #text
        local n = tonumber(text, 8)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0" .. util.tostring_with_base(n, 8, wid - 1, "0")
        cursor = #text
        return cursor, text
    end,
}

-- バイナリの非負整数。
M['number#binary'] = {
    desc = "binary number (e.g. 0b00110101)",

    find = common.find_pattern("0b[01]+"),

    add = function(cusror, text, addend)
        local wid = #text
        local n = tonumber(text:sub(3), 2)
        n = n + addend
        if n < 0 then
            n = 0
        end
        text = "0b" .. util.tostring_with_base(n, 2, wid - 2, "0")
        cursor = #text
        return cursor, text
    end,
}

M['date#[%Y/%m/%d]'] = {
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

M['date#[%m/%d]'] = {
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

M['date#[%-m/%-d]'] = {
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

M['date#[%Y-%m-%d]'] = {
    desc = "standard date %Y-%m-%d",

    find = common.find_pattern("%d%d%d%d%-%d%d%-%d%d"),
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

M['date#[%Y年%-m月%-d日]'] = {
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

M['date#[%Y年%-m月%-d日(%ja)]'] = {
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

M['date#[%H:%M:%S]'] = {
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

M['date#[%H:%M]'] = {
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

M['date#[%ja]'] = common.enum_cyclic{
    strlist = {"日", "月", "火", "水", "木", "金", "土"},
}

M['date#[%jA]'] = common.enum_cyclic{
    strlist = { '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日', },
    ptn_format = "\\C\\M\\(%s\\)",
}

M['char#alph#small#word'] = common.enum_sequence{
    strlist = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
}}

M['char#alph#capital#word'] = common.enum_sequence{
    strlist = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
}}

M['char#alph#small#str'] = common.enum_sequence{
    strlist = {
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    },
    ptn_format = "\\C\\M\\(%s\\)",
}

M['char#alph#capital#str'] = common.enum_sequence{
    strlist = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    },
    ptn_format = "\\C\\M\\(%s\\)",
}

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
M['color#hex'] = {
    desc = "HTML color (e.g. #12ab0f)",

    find = common.find_pattern("#%x%x%x%x%x%x"),

    add = function(cursor, text, addend)
        local r = tonumber(text:sub(2, 3), 16)
        local g = tonumber(text:sub(4, 5), 16)
        local b = tonumber(text:sub(6, 7), 16)
        if cursor == nil then cursor = 1 end  -- default: all
        if cursor <= 1 then
            -- increment all
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
        else  -- (if cursor == 6 or cursor == 7 then)
            b = cast_u8(b + addend)
            cursor = 7
        end
        text = "#" .. string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)
        return cursor, text
    end,
}

M['markup#markdown#header'] = {
    desc = "Markdown Header (# Title)",

    find = function(cursor, line)
        header_mark_s, header_mark_e = line:find("^#+")
        if header_mark_s == nil or header_mark_e > 7 then
            return nil
        end
        return {from = header_mark_s, to = header_mark_e}
    end,

    add = function(cursor, text, addend)
        n = #text
        n = n + addend
        if n < 1 then n = 1 end
        if n > 6 then n = 6 end
        text = ("#"):rep(n)
        cursor = 1
        return cursor, text
    end
}

return M
