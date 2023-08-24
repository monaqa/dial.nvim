local util = require "dial.util"
local common = require "dial.augend.common"

local M = {}

---@alias datekind '"year"' | '"month"' | '"day"' | '"hour"' | '"min"' | '"sec"'
---@alias dttable table<datekind, integer>
---@alias dateparser fun(string, osdate): osdate
---@alias dateformatter fun(osdate): string
---@alias dateelement {kind?: datekind, regex: string, update_date: dateparser, format?: dateformatter}

---@param datekind datekind | nil
---@return fun(string, osdate): osdate
local function simple_updater(datekind)
    if datekind == nil then
        return function(_, date)
            return date
        end
    end
    return function(text, date)
        date[datekind] = tonumber(text)
        return date
    end
end

local WEEKDAYS = {
    "Sun",
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
}
local WEEKDAYS_FULL = {
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
}
local WEEKDAYS_JA = {
    "日",
    "月",
    "火",
    "水",
    "木",
    "金",
    "土",
}
local MONTHS = {
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
}
local MONTHS_FULL = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
}

---@type table<string, dateelement>
local date_elements = {
    ["Y"] = {
        kind = "year",
        regex = [[\d\d\d\d]],
        update_date = simple_updater "year",
    },
    ["y"] = {
        kind = "year",
        regex = [[\d\d]],
        update_date = function(text, date)
            date.year = 2000 + tonumber(text)
            return date
        end,
    },
    ["m"] = {
        kind = "month",
        regex = [[\d\d]],
        update_date = simple_updater "month",
    },
    ["d"] = {
        kind = "day",
        regex = [[\d\d]],
        update_date = simple_updater "day",
    },
    ["H"] = {
        kind = "hour",
        regex = [[\d\d]],
        update_date = simple_updater "hour",
    },
    ["I"] = {
        kind = "hour",
        regex = [[\d\d]],
        update_date = function(text, date)
            local hour = tonumber(text)
            if date.hour < 12 and hour >= 12 then
                date.hour = hour - 12
            elseif date.hour >= 12 and hour < 12 then
                date.hour = hour + 12
            else
                date.hour = hour
            end
            return date
        end,
    },
    ["M"] = {
        kind = "min",
        regex = [[\d\d]],
        update_date = simple_updater "min",
    },
    ["S"] = {
        kind = "sec",
        regex = [[\d\d]],
        update_date = simple_updater "sec",
    },

    -- with hyphen
    ["-y"] = {
        kind = "year",
        regex = [[\d\{1,2\}]],
        update_date = function(text, date)
            date.year = 2000 + tonumber(text)
            return date
        end,
        format = function(time)
            local year = os.date("*t", time).year --[[ @as integer ]]
            return tostring(year % 100)
        end,
    },
    ["-m"] = {
        kind = "month",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "month",
        format = function(time)
            local month = os.date("*t", time).month --[[ @as integer ]]
            return tostring(month)
        end,
    },
    ["-d"] = {
        kind = "day",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "day",
        format = function(time)
            local day = os.date("*t", time).day --[[ @as integer ]]
            return tostring(day)
        end,
    },
    ["-H"] = {
        kind = "hour",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "hour",
        format = function(time)
            local hour = os.date("*t", time).hour --[[ @as integer ]]
            return tostring(hour)
        end,
    },
    ["-I"] = {
        kind = "hour",
        regex = [[\d\{1,2\}]],
        update_date = function(text, date)
            local hour = tonumber(text)
            if date.hour < 12 and hour >= 12 then
                date.hour = hour - 12
            elseif date.hour >= 12 and hour < 12 then
                date.hour = hour + 12
            else
                date.hour = hour
            end
            return date
        end,
        format = function(time)
            local hour = os.date("*t", time).hour --[[ @as integer ]]
            -- 0 -> 12, 1 -> 1, 2 -> 2, ..., 12 -> 12, ...,  23 -> 11
            return tostring((hour + 11) % 12 + 1)
        end,
    },
    ["-M"] = {
        kind = "min",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "min",
        format = function(time)
            local min = os.date("*t", time).min --[[ @as integer ]]
            return tostring(min)
        end,
    },
    ["-S"] = {
        kind = "sec",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "sec",
        format = function(time)
            local sec = os.date("*t", time).sec --[[ @as integer ]]
            return tostring(sec)
        end,
    },

    -- names
    ["a"] = {
        kind = nil,
        regex = common.enum_to_regex(WEEKDAYS),
        update_date = function(_, date)
            return date
        end,
        format = function(time)
            local wday = os.date("*t", time).wday --[[ @as integer ]]
            return WEEKDAYS[wday]
        end,
    },
    ["A"] = {
        kind = nil,
        regex = common.enum_to_regex(WEEKDAYS_FULL),
        update_date = function(_, date)
            return date
        end,
        format = function(time)
            local wday = os.date("*t", time).wday --[[ @as integer ]]
            return WEEKDAYS_FULL[wday]
        end,
    },
    ["b"] = {
        kind = "month",
        regex = common.enum_to_regex(MONTHS),
        update_date = function(text, date)
            for index, value in ipairs(MONTHS) do
                if value == text then
                    date.month = index
                end
            end
            return date
        end,
        format = function(time)
            local month = os.date("*t", time).month --[[ @as integer ]]
            return MONTHS[month]
        end,
    },
    ["B"] = {
        kind = "month",
        regex = common.enum_to_regex(MONTHS_FULL),
        update_date = function(text, date)
            for index, value in ipairs(MONTHS_FULL) do
                if value == text then
                    date.month = index
                end
            end
            return date
        end,
        format = function(time)
            local month = os.date("*t", time).month --[[ @as integer ]]
            return MONTHS_FULL[month]
        end,
    },
    ["p"] = {
        kind = "hour",
        regex = common.enum_to_regex { "AM", "PM" },
        update_date = function(text, date)
            if text == "PM" and date.hour < 12 then
                date.hour = date.hour + 12
            end
            if text == "AM" and date.hour >= 12 then
                date.hour = date.hour - 12
            end
            return date
        end,
        -- format = function(time)
        --     local hour = os.date("*t", time).hour --[[ @as integer ]]
        --     if hour < 12 then
        --         return "am"
        --     end
        --     return "pm"
        -- end,
    },

    -- custom
    ["J"] = {
        kind = nil,
        regex = common.enum_to_regex(WEEKDAYS_JA),
        update_date = simple_updater(),
        format = function(time)
            local wday = os.date("*t", time).wday --[[ @as integer ]]
            return WEEKDAYS_JA[wday]
        end,
    },
}

---@param pattern string
---@return string[]
---@param custom_date_element_keys string[]
local function parse_date_pattern(pattern, custom_date_element_keys)
    local date_elements_keys = vim.tbl_keys(date_elements) --[[@as string[] ]]

    local sequences = {}

    ---@type string
    local stack = ""

    for c in util.chars(pattern) do
        if vim.startswith(stack, "%(") then
            if c == ")" then
                local custom_element_name = stack:sub(3)
                if vim.tbl_contains(custom_date_element_keys, custom_element_name) then
                    table.insert(sequences, stack .. ")")
                    stack = ""
                else
                    error(("Unknown custom elements: %s"):format(custom_element_name))
                end
            else
                stack = stack .. c
            end
        elseif stack == "%-" then
            if vim.tbl_contains(date_elements_keys, c) then
                table.insert(sequences, "%-" .. c)
                stack = ""
            else
                error("Unsupported special character: %-" .. c)
            end
        elseif stack == "%" then
            -- special character
            if c == "-" or c == "(" then
                stack = "%" .. c
            elseif c == "%" then
                table.insert(sequences, "%")
                stack = ""
            elseif vim.tbl_contains(date_elements_keys, c) then
                table.insert(sequences, "%" .. c)
                stack = ""
            else
                error("Unsupported special character: %" .. c)
            end
        else
            -- escape character
            if c == "%" then
                if stack ~= "" then
                    table.insert(sequences, stack)
                end
                stack = "%"
            else
                stack = stack .. c
            end
        end
    end

    if stack ~= "" then
        if vim.startswith(stack, "%(") then
            error("The end of custom date element was not found:'" .. stack .. "'.")
        elseif vim.startswith(stack, "%") then
            error("Pattern string cannot end with '" .. stack .. "'.")
        else
            table.insert(sequences, stack)
            stack = ""
        end
    end

    return sequences
end

---@class DateFormat
---@field sequences string[]
---@field default_kind datekind
---@field word boolean
---@field custom_date_elements table<string, dateelement>
local DateFormat = {}

---Parse date pattern string and create new DateFormat.
---@param pattern string
---@param default_kind datekind
---@param word? boolean
---@param custom_date_elements? table<string, dateelement>
---@return DateFormat
function DateFormat.new(pattern, default_kind, word, custom_date_elements)
    word = util.unwrap_or(word, false)
    custom_date_elements = util.unwrap_or(custom_date_elements, {})

    local custom_date_elements_keys = vim.tbl_keys(custom_date_elements) --[[@as string[] ]]
    local sequences = parse_date_pattern(pattern, custom_date_elements_keys)

    return setmetatable(
        { sequences = sequences, default_kind = default_kind, word = word, custom_date_elements = custom_date_elements },
        { __index = DateFormat }
    )
end

---@param pattern string
---@return dateelement
function DateFormat:get_date_elements(pattern)
    if vim.startswith(pattern, "%(") and vim.endswith(pattern, ")") then
        local custom_element_name = pattern:sub(3, -2)
        return self.custom_date_elements[custom_element_name]
    elseif vim.startswith(pattern, "%") then
        local element_name = pattern:sub(2)
        return date_elements[element_name]
    else
        error(("unknown pattern: '%s'"):format(pattern))
    end
end

---returns the regex.
---@return string
function DateFormat:regex()
    local regexes = vim.tbl_map(
        ---@param s string
        ---@return string
        function(s)
            if s == "%" then
                return [[%]]
            elseif vim.startswith(s, "%") then
                return [[\(]] .. self:get_date_elements(s).regex .. [[\)]]
            else
                return vim.fn.escape(s, [[\]])
            end
        end,
        self.sequences
    ) --[[ @as string[] ]]

    if self.word then
        return [[\V\C\<]] .. table.concat(regexes, "") .. [[\>]]
    else
        return [[\V\C]] .. table.concat(regexes, "")
    end
end

---@param line string
---@param cursor? integer
---@return {range: textrange, dt_info: osdate, kind: datekind}?
function DateFormat:find(line, cursor)
    local range = common.find_pattern_regex(self:regex())(line, cursor)
    if range == nil then
        return nil
    end

    -- cursor が nil になるときはカーソルが最初にあるときとみなして良い
    if cursor == nil then
        cursor = 0
    end

    local matchlist = vim.fn.matchlist(line:sub(range.from, range.to), self:regex())
    local scan_cursor = range.from - 1
    local flag_set_status = scan_cursor >= cursor
    local dt_info = os.date("*t", 0) --[[@as osdate]]

    do
        local now = os.date("*t", os.time()) --[[@as osdate]]
        dt_info.month = now.month
        dt_info.year = now.year
        dt_info.isdst = now.isdst
    end

    local datekind = self.default_kind

    local match_idx = 2
    for _, pattern in ipairs(self.sequences) do
        ---@type string
        if pattern ~= "%" and vim.startswith(pattern, "%") then
            local substr = matchlist[match_idx]
            scan_cursor = scan_cursor + #substr
            local date_element = self:get_date_elements(pattern)
            dt_info = date_element.update_date(substr, dt_info)
            if scan_cursor >= cursor and not flag_set_status and date_element.kind ~= nil then
                datekind = date_element.kind
                flag_set_status = true
            end
            match_idx = match_idx + 1
        else
            scan_cursor = scan_cursor + #pattern
        end
    end
    return { range = range, dt_info = dt_info, kind = datekind }
end

---@param line string
---@param cursor? integer
---@return {range: textrange, dt_info: osdate, kind: datekind}?
function DateFormat:find_with_validity_check(line, cursor)
    local find_result = self:find(line, cursor)
    if find_result == nil then
        return nil
    end
    local text = line:sub(find_result.range.from, find_result.range.to)
    local time = os.time(find_result.dt_info)
    local add_result = self:strftime(time, "day")
    local correct_text = add_result.text
    if correct_text == text then
        return find_result
    else
        return nil
    end
end

---@param time integer
---@param datekind? datekind
---@return addresult
function DateFormat:strftime(time, datekind)
    local text = ""
    local cursor
    for _, pattern in ipairs(self.sequences) do
        if pattern ~= "%" and vim.startswith(pattern, "%") then
            local date_element = self:get_date_elements(pattern)
            if date_element.format ~= nil then
                text = text .. date_element.format(time)
            else
                text = text .. os.date(pattern, time)
            end
            if date_element.kind == datekind then
                cursor = #text
            end
        else
            text = text .. pattern
        end
    end
    if datekind == nil then
        return { text = text }
    else
        return { text = text, cursor = cursor }
    end
end

---@class AugendDate
---@implement Augend
---@field kind datekind
---@field config {pattern: string, default_kind: datekind, only_valid: boolean, word: boolean, clamp: boolean, end_sensitive: boolean, custom_date_elements: dateelement}
---@field date_format DateFormat
local AugendDate = {}

---@param config {pattern: string, default_kind: datekind, only_valid?: boolean, word?: boolean, clamp?: boolean, end_sensitive?: boolean, custom_date_elements?: table<string, dateelement>}
---@return Augend
function M.new(config)
    vim.validate {
        pattern = { config.pattern, "string" },
        default_kind = { config.default_kind, "string" },
        only_valid = { config.only_valid, "boolean", true },
        word = { config.word, "boolean", true },
        clamp = { config.clamp, "boolean", true },
        end_sensitive = { config.end_sensitive, "boolean", true },
        custom_date_elements = { config.custom_date_elements, "table", true },
    }

    config.only_valid = util.unwrap_or(config.only_valid, false)
    config.word = util.unwrap_or(config.word, false)
    config.clamp = util.unwrap_or(config.clamp, false)
    config.end_sensitive = util.unwrap_or(config.end_sensitive, false)

    local date_format = DateFormat.new(config.pattern, config.default_kind, config.word, config.custom_date_elements)

    return setmetatable(
        { config = config, kind = config.default_kind, date_format = date_format },
        { __index = AugendDate }
    )
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDate:find(line, cursor)
    local find_result
    if self.config.only_valid then
        find_result = self.date_format:find_with_validity_check(line, cursor)
    else
        find_result = self.date_format:find(line, cursor)
    end
    if find_result == nil then
        return nil
    end
    return find_result.range
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDate:find_stateful(line, cursor)
    local find_result
    if self.config.only_valid then
        find_result = self.date_format:find_with_validity_check(line, cursor)
    else
        find_result = self.date_format:find(line, cursor)
    end
    if find_result == nil then
        return nil
    end
    self.kind = find_result.kind
    return find_result.range
end

---@param year integer
---@param month integer
---@return integer
local function calc_end_day(year, month)
    if month == 4 or month == 6 or month == 9 or month == 11 then
        return 30
    elseif month == 2 then
        if year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0) then
            return 29
        else
            return 28
        end
    else
        return 31
    end
end

---@param dt_info osdate
---@param kind datekind
---@param addend integer
---@param clamp boolean
---@param end_sensitive boolean
---@return osdate
local function update_dt_info(dt_info, kind, addend, clamp, end_sensitive)
    if kind ~= "year" and kind ~= "month" then
        dt_info[kind] = dt_info[kind] + addend
        return dt_info
    end

    local end_day_before_add = calc_end_day(dt_info.year, dt_info.month)
    local day_before_add = dt_info.day
    dt_info.day = 1
    dt_info[kind] = dt_info[kind] + addend
    -- update date information to existent one
    dt_info = os.date("*t", os.time(dt_info)) --[[@as osdate]]
    local end_day_after_add = calc_end_day(dt_info.year, dt_info.month)

    if end_sensitive and end_day_before_add == day_before_add then
        dt_info.day = end_day_after_add
    elseif clamp and day_before_add > end_day_after_add then
        dt_info.day = end_day_after_add
    else
        dt_info.day = day_before_add
    end
    return dt_info
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendDate:add(text, addend, cursor)
    local find_result = self.date_format:find(text)
    if find_result == nil or self.kind == nil then
        return {}
    end
    local dt_info = find_result.dt_info

    dt_info = update_dt_info(dt_info, self.kind, addend, self.config.clamp, self.config.end_sensitive)
    -- dt_info[self.kind] = dt_info[self.kind] + addend
    local time = os.time(dt_info)

    return self.date_format:strftime(time, self.kind)
end

M.alias = {}

M.alias["%Y/%m/%d"] = M.new {
    pattern = "%Y/%m/%d",
    default_kind = "day",
    only_valid = false,
}

M.alias["%d/%m/%Y"] = M.new {
    pattern = "%d/%m/%Y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%d/%m/%y"] = M.new {
    pattern = "%d/%m/%y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%m/%d/%Y"] = M.new {
    pattern = "%m/%d/%Y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%m/%d/%y"] = M.new {
    pattern = "%m/%d/%y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%m/%d"] = M.new {
    pattern = "%m/%d",
    default_kind = "day",
    only_valid = false,
}

M.alias["%Y-%m-%d"] = M.new {
    pattern = "%Y-%m-%d",
    default_kind = "day",
    only_valid = false,
}

M.alias["%-m/%-d"] = M.new {
    pattern = "%-m/%-d",
    default_kind = "day",
    only_valid = true,
}

M.alias["%Y年%-m月%-d日"] = M.new {
    pattern = "%Y年%-m月%-d日",
    default_kind = "day",
    only_valid = false,
}

M.alias["%Y年%-m月%-d日(%ja)"] = M.new {
    pattern = "%Y年%-m月%-d日(%J)",
    default_kind = "day",
    only_valid = false,
}

M.alias["%d.%m.%Y"] = M.new {
    pattern = "%d.%m.%Y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%d.%m.%y"] = M.new {
    pattern = "%d.%m.%y",
    default_kind = "day",
    only_valid = true,
}

M.alias["%d.%m."] = M.new {
    pattern = "%d.%m.",
    default_kind = "day",
    only_valid = true,
}

M.alias["%-d.%-m."] = M.new {
    pattern = "%-d.%-m.",
    default_kind = "day",
    only_valid = true,
}

M.alias["%H:%M:%S"] = M.new {
    pattern = "%H:%M:%S",
    default_kind = "sec",
    only_valid = true,
}

M.alias["%H:%M"] = M.new {
    pattern = "%H:%M",
    default_kind = "min",
    only_valid = true,
}

return M
