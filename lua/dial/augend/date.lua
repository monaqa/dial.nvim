local util = require "dial.util"
local common = require "dial.augend.common"

local M = {}

---@alias dateptn { regex: string, capture: datefmtptn[] }
---@alias datefmtptn '"%Y"' | '"%y"' | '"%m"' | '"%d"' | '"%H"' | '"%M"' | '"%S"'
---@alias datekind '"year"' | '"month"' | '"day"' | '"hour"' | '"min"' | '"sec"'
---@alias datefmt { pattern: dateptn, format: string | function, judge_datekind: judge_datekind, calc_curpos: calc_curpos, only_valid?: boolean }
---@alias judge_datekind fun(text: string, curpos?: integer) -> datekind
---@alias calc_curpos fun(text: string, kind: datekind) -> integer?
-- parse: 日付の検出に用いられる正規表現
-- format: 日付を文字列に変換するときに用いられるパターン文字列または関数

---@param datekind datekind | nil
---@return fun(string): dttable
local function simple_parser(datekind)
    if datekind == nil then
        return function(_)
            return {}
        end
    end
    return function(text)
        return { [datekind] = tonumber(text) }
    end
end

---@alias dttable table<datekind, integer>
---@alias dateparser fun(string): dttable
---@alias dateformatter fun(osdate): string

---@type table<string, {kind: datekind, regex: string, parse: dateparser, format: dateformatter}>
local date_elements = {
    ["Y"] = {
        kind = "year",
        regex = [[\d\d\d\d]],
        parse = simple_parser "year",
        format = function(dt_info)
            return ("%04d"):format(dt_info.year)
        end,
    },
    ["m"] = {
        kind = "month",
        regex = [[\d\d]],
        parse = simple_parser "month",
        format = function(dt_info)
            return ("%02d"):format(dt_info.month)
        end,
    },
    ["d"] = {
        kind = "day",
        regex = [[\d\d]],
        parse = simple_parser "day",
        format = function(dt_info)
            return ("%02d"):format(dt_info.day)
        end,
    },
}

local date_elements_keys = vim.tbl_keys(date_elements) --[[@as string[] ]]

---@class DateFormat
---@field sequences string[]
---@field default_kind? datekind
local DateFormat = {}

---Parse date pattern string and create new DateFormat.
---@param pattern string
---@param default_kind? datekind
---@return DateFormat
function DateFormat.new(pattern, default_kind)
    local sequences = {}

    ---@type string
    local stack = ""

    for c in util.chars(pattern) do
        if stack == "%" then
            if c == "-" then
                stack = "%-"
            elseif c == "%" then
                table.insert(sequences, "%%")
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

    return setmetatable({ sequences = sequences, default_kind = default_kind }, { __index = DateFormat })
end

---returns the regex.
---@return string
function DateFormat:regex()
    local regexes = vim.tbl_map(
        ---@param s string
        ---@return string
        function(s)
            if s == "%%" then
                return "%%"
            elseif s:sub(1, 1) == "%" then
                return [[\(]] .. date_elements[s:sub(2)].regex .. [[\)]]
            else
                return [[\(]] .. vim.fn.escape(s, [[\]]) .. [[\)]]
            end
        end,
        self.sequences
    ) --[[ @as string[] ]]
    return [[\V\C]] .. table.concat(regexes, "")
end

---@param line string
---@param cursor? integer
---@return {range: textrange, dt_info: osdate, kind: datekind} | nil
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
    local scan_cursor = range.from
    local cursor_overtaken = scan_cursor >= cursor
    local dt_info = os.date("*t", os.time()) --[[@as osdate]]
    local datekind = self.default_kind

    for i, pattern in ipairs(self.sequences) do
        ---@type string
        local substr = matchlist[i + 1]
        scan_cursor = scan_cursor + #substr

        vim.pretty_print {
            pattern = pattern,
            substr = substr,
            scan_cursor = scan_cursor,
            cursor_overtaken = cursor_overtaken,
        }

        if pattern:sub(1, 1) == "%" and pattern ~= "%%" then
            local date_element = date_elements[pattern:sub(2)]
            local dttable = date_element.parse(substr)
            for key, value in pairs(dttable) do
                dt_info[key] = value
            end
            if not cursor_overtaken then
                datekind = date_element.kind
            end
        end

        if scan_cursor >= cursor then
            cursor_overtaken = true
        end
    end
    return { range = range, dt_info = dt_info, kind = datekind }
end

---@param dt_info osdate
---@param datekind datekind
---@return addresult
function DateFormat:strftime(dt_info, datekind)
    local text = ""
    local cursor
    for i, pattern in ipairs(self.sequences) do
        if pattern:sub(1, 1) == "%" and pattern ~= "%%" then
            local date_element = date_elements[pattern:sub(2)]
            text = text .. date_element.format(dt_info)
            if date_element.kind == datekind then
                cursor = #text
            end
        else
            text = text .. pattern
        end
    end
    return { text = text, cursor = cursor }
end

M.DateFormat = DateFormat

local JA_WEEKDAYS = { "日", "月", "火", "水", "木", "金", "土" }

---テキストから日付情報を抽出する。
---@param text string
---@param regex string
---@param capture datefmtptn[]
---@return dict<datekind, integer>
local function get_dt_info(text, regex, capture)
    local matchlist = vim.fn.matchlist(text, [[\v]] .. regex)
    local dt_info = {}
    for i, fmtptn in ipairs(capture) do
        local value = tonumber(matchlist[i + 1])
        if fmtptn == "%Y" then
            dt_info["year"] = value
        elseif fmtptn == "%y" then
            dt_info["year"] = value + 2000
        elseif fmtptn == "%m" then
            dt_info["month"] = value
        elseif fmtptn == "%d" then
            dt_info["day"] = value
        elseif fmtptn == "%H" then
            dt_info["hour"] = value
        elseif fmtptn == "%M" then
            dt_info["minute"] = value
        elseif fmtptn == "%S" then
            dt_info["second"] = value
        end
    end
    if dt_info.year == nil then
        dt_info.year = os.date("*t", os.time()).year
    end
    if dt_info.month == nil then
        dt_info.month = os.date("*t", os.time()).month
    end
    if dt_info.day == nil then
        dt_info.day = os.date("*t", os.time()).day
    end
    return dt_info
end

---@class AugendDate
---@implement Augend
---@field datefmt datefmt
---@field only_valid boolean
---@field kind datekind
local AugendDate = {}

---@param config datefmt
---@return Augend
function M.new(config)
    vim.validate {
        -- format_name = {config.format_name, "string"},
        pattern_regex = { config.pattern.regex, "string" },
        pattern_capture = { config.pattern.capture, "table" },
        -- format = {config.format, "string"},
        judge_datekind = { config.judge_datekind, "function" },
        calc_curpos = { config.calc_curpos, "function" },
        only_valid = { config.only_valid, "boolean", true },
    }

    local only_valid = util.unwrap_or(config.only_valid, false)

    return setmetatable({ datefmt = config, only_valid = only_valid, kind = "day" }, { __index = AugendDate })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDate:find(line, cursor)
    local range = common.find_pattern_regex([[\v]] .. self.datefmt.pattern.regex)(line, cursor)
    -- if ~self.datefmt.only_valid or range == nil then
    --     -- validity check が要らない or range がそもそもないときはこのまま return
    --     return range
    -- end
    -- self.datefmt.pattern.capture

    if range == nil or not self.only_valid then
        return range
    end

    local text_origin = line:sub(range.from, range.to)
    local dt_info = get_dt_info(text_origin, self.datefmt.pattern.regex, self.datefmt.pattern.capture)
    local datetime = os.time(dt_info)
    local text_generated
    if type(self.datefmt.format) == "string" then
        text_generated = os.date(self.datefmt.format, datetime)
    else
        text_generated = self.datefmt.format(datetime)
    end
    if text_origin == text_generated then
        return range
    end
    return nil
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDate:find_stateful(line, cursor)
    local range = self:find(line, cursor)
    if range == nil then
        return
    end
    local text = line:sub(range.from, range.to)
    if cursor == nil then
        self.kind = self.datefmt.judge_datekind(text, nil)
    else
        self.kind = self.datefmt.judge_datekind(text, cursor - range.from + 1)
    end
    return range
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendDate:add(text, addend, cursor)
    local dt_info = get_dt_info(text, self.datefmt.pattern.regex, self.datefmt.pattern.capture)

    if self.kind == "year" then
        dt_info.year = dt_info.year + addend
    elseif self.kind == "month" then
        dt_info.month = dt_info.month + addend
    elseif self.kind == "day" then
        dt_info.day = dt_info.day + addend
    elseif self.kind == "hour" then
        dt_info.hour = dt_info.hour + addend
    elseif self.kind == "min" then
        dt_info.min = dt_info.min + addend
    elseif self.kind == "sec" then
        dt_info.sec = dt_info.sec + addend
    end

    local datetime = os.time(dt_info)
    if type(self.datefmt.format) == "string" then
        text = os.date(self.datefmt.format, datetime)
    else
        text = self.datefmt.format(datetime)
    end
    cursor = self.datefmt.calc_curpos(text, self.kind)
    return { text = text, cursor = cursor }
end

M.alias = {}

M.alias["%Y/%m/%d"] = M.new {
    pattern = {
        regex = [[(\d{4})/(\d{2})/(\d{2})]],
        capture = { "%Y", "%m", "%d" },
    },
    format = "%Y/%m/%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 or curpos >= 8 then
            return "day"
        elseif curpos <= 4 then
            return "year"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 4
        elseif kind == "month" then
            return 7
        else
            return 10
        end
    end,
}

M.alias["%d/%m/%Y"] = M.new {
    pattern = {
        regex = [[(\d{2})/(\d{2})/(\d{4})]],
        capture = { "%d", "%m", "%Y" },
    },
    only_valid = true,
    format = "%d/%m/%Y",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 then
            return "day"
        elseif curpos <= 2 then
            return "day"
        elseif curpos <= 5 then
            return "month"
        else
            return "year"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 10
        elseif kind == "month" then
            return 5
        else
            return 2
        end
    end,
}

M.alias["%d/%m/%y"] = M.new {
    pattern = {
        regex = [[(\d{2})/(\d{2})/(\d{2})]],
        capture = { "%d", "%m", "%y" },
    },
    only_valid = true,
    format = "%d/%m/%y",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 then
            return "day"
        elseif curpos <= 2 then
            return "day"
        elseif curpos <= 5 then
            return "month"
        else
            return "year"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 8
        elseif kind == "month" then
            return 5
        else
            return 2
        end
    end,
}

M.alias["%m/%d/%Y"] = M.new {
    pattern = {
        regex = [[(\d{2})/(\d{2})/(\d{4})]],
        capture = { "%m", "%d", "%Y" },
    },
    only_valid = true,
    format = "%m/%d/%Y",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 then
            return "day"
        elseif curpos <= 2 then
            return "month"
        elseif curpos <= 5 then
            return "day"
        else
            return "year"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 10
        elseif kind == "month" then
            return 2
        else
            return 5
        end
    end,
}

M.alias["%m/%d/%y"] = M.new {
    pattern = {
        regex = [[(\d{2})/(\d{2})/(\d{2})]],
        capture = { "%m", "%d", "%y" },
    },
    only_valid = true,
    format = "%m/%d/%y",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 then
            return "day"
        elseif curpos <= 2 then
            return "month"
        elseif curpos <= 5 then
            return "day"
        else
            return "year"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 8
        elseif kind == "month" then
            return 2
        else
            return 5
        end
    end,
}

M.alias["%Y-%m-%d"] = M.new {
    pattern = {
        regex = [[(\d{4})-(\d{2})-(\d{2})]],
        capture = { "%Y", "%m", "%d" },
    },
    format = "%Y-%m-%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 or curpos >= 8 then
            return "day"
        elseif curpos <= 4 then
            return "year"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "year" then
            return 4
        elseif kind == "month" then
            return 7
        else
            return 10
        end
    end,
}

M.alias["%m/%d"] = M.new {
    pattern = {
        regex = [[(\d{2})/(\d{2})]],
        capture = { "%m", "%d" },
    },
    format = "%m/%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 or curpos >= 3 then
            return "day"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "month" then
            return 2
        else
            return 5
        end
    end,
}

M.alias["%-m/%-d"] = M.new {
    pattern = {
        regex = [[(\d{1,2})/(\d{1,2})]],
        capture = { "%m", "%d" },
    },
    format = "%-m/%-d",
    only_valid = true,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(text, curpos)
        local idx_slash = text:find "/"
        if curpos == nil or curpos <= 0 or curpos >= idx_slash then
            return "day"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param text string
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(text, kind)
        local idx_slash = text:find "/"
        if kind == "month" then
            return idx_slash - 1
        else
            return #text
        end
    end,
}

M.alias["%Y年%-m月%-d日"] = M.new {
    pattern = {
        regex = [[(\d{4})年(\d{1,2})月(\d{1,2})日]],
        capture = { "%Y", "%m", "%d" },
    },
    format = "%Y年%-m月%-d日",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(text, curpos)
        local _, idx_nen = text:find "年"
        local _, idx_tsuki = text:find "月"
        if curpos == nil or curpos <= 0 or curpos > idx_tsuki then
            return "day"
        elseif curpos <= idx_nen then
            return "year"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param text string
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(text, kind)
        local idx_nen = text:find "年"
        local idx_tsuki = text:find "月"
        local idx_day = text:find "日"
        if kind == "year" then
            return idx_nen - 1
        elseif kind == "month" then
            return idx_tsuki - 1
        else
            return idx_day - 1
        end
    end,
}

M.alias["%Y年%-m月%-d日(%ja)"] = M.new {
    pattern = {
        regex = [[(\d{4})年(\d{1,2})月(\d{1,2})日\((月|火|水|木|金|土|日)\)]],
        capture = { "%Y", "%m", "%d" },
    },
    format = function(datetime)
        local text_date = os.date("%Y年%-m月%-d日", datetime)
        local tbl_date = os.date("*t", datetime)
        local text_weekday = JA_WEEKDAYS[tbl_date.wday]
        return ("%s(%s)"):format(text_date, text_weekday)
    end,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(text, curpos)
        local _, idx_nen = text:find "年"
        local _, idx_tsuki = text:find "月"
        if curpos == nil or curpos <= 0 or curpos > idx_tsuki then
            return "day"
        elseif curpos <= idx_nen then
            return "year"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param text string
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(text, kind)
        local idx_nen = text:find "年"
        local idx_tsuki = text:find "月"
        local idx_hi = text:find "日"
        if kind == "year" then
            return idx_nen - 1
        elseif kind == "month" then
            return idx_tsuki - 1
        else
            return idx_hi - 1
        end
    end,
}

M.alias["%d.%m.%Y"] = M.new {
    pattern = {
        regex = [[(\d{2})\.(\d{2})\.(\d{4})]],
        capture = { "%d", "%m", "%Y" },
    },
    only_valid = true,
    format = "%d.%m.%Y",

    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 2 then
            return "day"
        elseif curpos <= 5 then
            return "month"
        else
            return "year"
        end
    end,

    calc_curpos = function(_, kind)
        if kind == "day" then
            return 2
        elseif kind == "month" then
            return 5
        else
            return 10
        end
    end,
}

M.alias["%d.%m.%y"] = M.new {
    pattern = {
        regex = [[(\d{2})\.(\d{2})\.(\d{2})]],
        capture = { "%d", "%m", "%y" },
    },
    only_valid = true,
    format = "%d.%m.%y",

    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 2 then
            return "day"
        elseif curpos <= 5 then
            return "month"
        else
            return "year"
        end
    end,

    calc_curpos = function(_, kind)
        if kind == "day" then
            return 2
        elseif kind == "month" then
            return 5
        else
            return 8
        end
    end,
}

M.alias["%d.%m."] = M.new {
    pattern = {
        regex = [[(\d{2})\.(\d{2})\.]],
        capture = { "%d", "%m" },
    },
    only_valid = true,
    format = "%d.%m.",

    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 2 then
            return "day"
        else
            return "month"
        end
    end,

    calc_curpos = function(_, kind)
        if kind == "day" then
            return 2
        else
            return 5
        end
    end,
}

M.alias["%-d.%-m."] = M.new {
    pattern = {
        regex = [[(\d{1,2})\.(\d{1,2})\.]],
        capture = { "%d", "%m" },
    },
    only_valid = true,
    format = "%-d.%-m.",

    judge_datekind = function(text, curpos)
        local idx_dot = text:find(".", 1, true)
        if curpos == nil or curpos < idx_dot then
            return "day"
        else
            return "month"
        end
    end,

    calc_curpos = function(text, kind)
        local idx_dot = text:find(".", 1, true)
        if kind == "day" then
            return idx_dot - 1
        else
            return #text
        end
    end,
}

M.alias["%H:%M:%S"] = M.new {
    pattern = {
        regex = [[(\d{2}):(\d{2}):(\d{2})]],
        capture = { "%H", "%M", "%S" },
    },
    format = "%H:%M:%S",
    only_valid = true,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 or curpos > 5 then
            return "sec"
        elseif curpos <= 2 then
            return "hour"
        else
            return "min"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "hour" then
            return 2
        elseif kind == "min" then
            return 5
        else
            return 8
        end
    end,
}

M.alias["%H:%M"] = M.new {
    pattern = {
        regex = [[(\d{2}):(\d{2})]],
        capture = { "%H", "%M" },
    },
    format = "%H:%M",
    only_valid = true,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function(_, curpos)
        if curpos == nil or curpos <= 0 or curpos > 2 then
            return "min"
        else
            return "hour"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function(_, kind)
        if kind == "hour" then
            return 2
        else
            return 5
        end
    end,
}

return M
