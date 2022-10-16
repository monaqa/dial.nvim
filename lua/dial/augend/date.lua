local util = require "dial.util"
local common = require "dial.augend.common"

local M = {}

---@alias datekind '"year"' | '"month"' | '"day"' | '"hour"' | '"min"' | '"sec"'
---@alias dttable table<datekind, integer>
---@alias dateparser fun(string, osdate): osdate
---@alias dateformatter fun(osdate): string

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

---@param elems string[]
local function enum_to_regex(elems)
    return table.concat(elems, [[\|]])
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

---@type table<string, {kind?: datekind, regex: string, update_date: dateparser, format: dateformatter}>
M.date_elements = {
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
    ["-m"] = {
        kind = "month",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "month",
    },
    ["-d"] = {
        kind = "day",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "day",
    },
    ["-H"] = {
        kind = "hour",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "hour",
    },
    ["-M"] = {
        kind = "min",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "min",
    },
    ["-S"] = {
        kind = "sec",
        regex = [[\d\{1,2\}]],
        update_date = simple_updater "sec",
    },

    -- names
    ["a"] = {
        kind = nil,
        regex = enum_to_regex(WEEKDAYS),
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
        regex = enum_to_regex(WEEKDAYS_FULL),
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
        regex = enum_to_regex(MONTHS),
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
        regex = enum_to_regex(MONTHS_FULL),
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
        regex = enum_to_regex { "AM", "PM" },
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
        regex = enum_to_regex(WEEKDAYS_JA),
        update_date = simple_updater(),
        format = function(time)
            local wday = os.date("*t", time).wday --[[ @as integer ]]
            return WEEKDAYS_JA[wday]
        end,
    },
}

---@class DateFormat
---@field sequences string[]
---@field default_kind datekind
---@field word boolean
local DateFormat = {}

---Parse date pattern string and create new DateFormat.
---@param pattern string
---@param default_kind datekind
---@param word? boolean
---@return DateFormat
function DateFormat.new(pattern, default_kind, word)
    local date_elements_keys = vim.tbl_keys(M.date_elements) --[[@as string[] ]]
    word = util.unwrap_or(word, false)

    local sequences = {}

    ---@type string
    local stack = ""

    for c in util.chars(pattern) do
        if stack == "%" then
            if c == "-" then
                stack = "%-"
            elseif c == "%" then
                table.insert(sequences, "%")
                stack = ""
            elseif vim.tbl_contains(date_elements_keys, c) then
                table.insert(sequences, "%" .. c)
                stack = ""
            else
                error("Unsupported special character: %" .. c)
            end
        elseif stack == "%-" then
            if vim.tbl_contains(date_elements_keys, c) then
                table.insert(sequences, "%-" .. c)
                stack = ""
            else
                error("Unsupported special character: %-" .. c)
            end
        else
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
        if vim.startswith(stack, "%") then
            error("Pattern string cannot end with '" .. stack .. "'.")
        else
            table.insert(sequences, stack)
        end
    end

    return setmetatable({ sequences = sequences, default_kind = default_kind, word = word }, { __index = DateFormat })
end

---returns the regex.
---@return string
function DateFormat:regex()
    local regexes = vim.tbl_map(
        ---@param s string
        ---@return string
        function(s)
            if s == "%" then
                return [[\(%\)]]
            elseif s:sub(1, 1) == "%" then
                return [[\(]] .. M.date_elements[s:sub(2)].regex .. [[\)]]
            else
                return [[\(]] .. vim.fn.escape(s, [[\]]) .. [[\)]]
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
    local dt_info = os.date("*t", os.time()) --[[@as osdate]]
    local datekind = self.default_kind

    for i, pattern in ipairs(self.sequences) do
        ---@type string
        local substr = matchlist[i + 1]
        scan_cursor = scan_cursor + #substr

        if pattern:sub(1, 1) == "%" and pattern ~= "%" then
            local date_element = M.date_elements[pattern:sub(2)]
            dt_info = date_element.update_date(substr, dt_info)
            if scan_cursor >= cursor and not flag_set_status and date_element.kind ~= nil then
                datekind = date_element.kind
                flag_set_status = true
            end
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
    for i, pattern in ipairs(self.sequences) do
        if pattern:sub(1, 1) == "%" and pattern ~= "%" then
            local date_element = M.date_elements[pattern:sub(2)]
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
---@field config {pattern: string, default_kind: datekind, only_valid: boolean, word: boolean}
---@field date_format DateFormat
local AugendDate = {}

---@param config {pattern: string, default_kind: datekind, only_valid?: boolean, word?: boolean}
---@return AugendDate
function M.new(config)
    vim.validate {
        pattern = { config.pattern, "string" },
        default_kind = { config.default_kind, "string" },
        only_valid = { config.only_valid, "boolean", true },
        word = { config.word, "boolean", true },
    }

    config.only_valid = util.unwrap_or(config.only_valid, false)
    config.word = util.unwrap_or(config.word, false)

    local date_format = DateFormat.new(config.pattern, config.default_kind, config.word)

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

    dt_info[self.kind] = dt_info[self.kind] + addend
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
    default_kind = "sec",
    only_valid = true,
}

return M
