local util = require"dial.util"
local common = require"dial.augend.common"

---@alias dateptn { regex: string, capture: datekind[] }
---@alias datekind '"year"' | '"month"' | '"day"' | '"hour"' | '"min"' | '"sec"'
---@alias datefmt { pattern: dateptn, format: string | function, judge_datekind: judge_datekind, calc_curpos: calc_curpos }
---@alias judge_datekind fun(text: string, curpos?: integer) -> datekind
---@alias calc_curpos fun(text: string, kind: datekind) -> integer?
-- parse: 日付の検出に用いられる正規表現
-- format: 日付を文字列に変換するときに用いられるパターン文字列または関数

local JA_WEEKDAYS = { "日", "月", "火", "水", "木", "金", "土" }

---@type datefmt[]
local DICT_FORMAT = {}

DICT_FORMAT["%Y/%m/%d"] = {
    pattern = {
        regex = [[(\d{4})/(\d{2})/(\d{2})]],
        capture = { "year", "month", "day" }
    },
    format = "%Y/%m/%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (_, curpos)
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
    calc_curpos = function (_, kind)
        if kind == "year" then
            return 4
        elseif kind == "month" then
            return 7
        else
            return 10
        end
    end,
}

DICT_FORMAT["%Y-%m-%d"] = {
    pattern = {
        regex = [[(\d{4})-(\d{2})-(\d{2})]],
        capture = { "year", "month", "day" }
    },
    format = "%Y-%m-%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (_, curpos)
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
    calc_curpos = function (_, kind)
        if kind == "year" then
            return 4
        elseif kind == "month" then
            return 7
        else
            return 10
        end
    end,
}

DICT_FORMAT["%m/%d"] = {
    pattern = {
        regex = [[(\d{2})/(\d{2})]],
        capture = { "month", "day" }
    },
    format = "%m/%d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (_, curpos)
        if curpos == nil or curpos <= 0 or curpos >= 3 then
            return "day"
        else
            return "month"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function (_, kind)
        if kind == "month" then
            return 2
        else
            return 5
        end
    end,
}

DICT_FORMAT["%-m/%-d"] = {
    pattern = {
        regex = [[(\d{1,2})/(\d{1,2})]],
        capture = { "month", "day" }
    },
    format = "%-m/%-d",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (text, curpos)
        local idx_slash = text:find("/")
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
    calc_curpos = function (text, kind)
        local idx_slash = text:find("/")
        if kind == "month" then
            return idx_slash - 1
        else
            return #text
        end
    end,
}

DICT_FORMAT["%Y年%-m月%-d日"] = {
    pattern = {
        regex = [[(\d{4})年(\d{1,2})月(\d{1,2})日]],
        capture = { "year", "month", "day" }
    },
    format = "%Y年%-m月%-d日",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (text, curpos)
        local _, idx_nen = text:find("年")
        local _, idx_tsuki = text:find("月")
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
    calc_curpos = function (text, kind)
        local idx_nen = text:find("年")
        local idx_tsuki = text:find("月")
        local idx_day = text:find("日")
        util.dbg{text = text, idx_nen = idx_nen, idx_tsuki = idx_tsuki, kind = kind}
        if kind == "year" then
            return idx_nen - 1
        elseif kind == "month" then
            return idx_tsuki - 1
        else
            return idx_day - 1
        end
    end,
}

DICT_FORMAT["%Y年%-m月%-d日(%ja)"] = {
    pattern = {
        regex = [[(\d{4})年(\d{1,2})月(\d{1,2})日\((月|火|水|木|金|土|日)\)]],
        capture = { "year", "month", "day" }
    },
    format = function (datetime)
        local text_date = os.date("%Y年%-m月%-d日", datetime)
        local tbl_date = os.date("*t", datetime)
        local text_weekday = JA_WEEKDAYS[tbl_date.wday]
        return ("%s(%s)"):format(text_date, text_weekday)
    end,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (text, curpos)
        local _, idx_nen = text:find("年")
        local _, idx_tsuki = text:find("月")
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
    calc_curpos = function (text, kind)
        local idx_nen = text:find("年")
        local idx_tsuki = text:find("月")
        local idx_hi = text:find("日")
        if kind == "year" then
            return idx_nen - 1
        elseif kind == "month" then
            return idx_tsuki - 1
        else
            return idx_hi - 1
        end
    end,
}

DICT_FORMAT["%H:%M:%S"] = {
    pattern = {
        regex = [[(\d{2}):(\d{2}):(\d{2})]],
        capture = { "hour", "min", "sec" }
    },
    format = "%H:%M:%S",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (_, curpos)
        if curpos == nil or curpos <= 0 or curpos > 5 then
            return "sec"
        elseif curpos <= 2 then
            return "hour"
        else
            return "min"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param text string
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function (text, kind)
        if kind == "hour" then
            return 2
        elseif kind == "min" then
            return 5
        else
            return 8
        end
    end,
}

DICT_FORMAT["%H:%M"] = {
    pattern = {
        regex = [[(\d{2}):(\d{2})]],
        capture = { "hour", "min" }
    },
    format = "%H:%M",

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (_, curpos)
        if curpos == nil or curpos <= 0 or curpos > 2 then
            return "min"
        else
            return "hour"
        end
    end,

    ---増減後の text と 元の datekind からカーソル位置を求める。
    ---@param kind datekind
    ---@return integer?  # 1-based
    calc_curpos = function (_, kind)
        if kind == "hour" then
            return 2
        else
            return 5
        end
    end,
}

---テキストから日付情報を抽出する。
---@param text string
---@param regex string
---@param capture datekind[]
---@return dict<datekind, integer>
local function get_dt_info(text, regex, capture)
    local matchlist = vim.fn.matchlist(text, [[\v]] .. regex)
    local dt_info = {}
    for i, kind in ipairs(capture) do
        dt_info[kind] = tonumber(matchlist[i + 1])
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

---@param config { format_name: string }
---@return Augend
function AugendDate.new(config)
    vim.validate{
        format_name = {config.format_name, "string"},
        only_valid = {config.only_valid, "boolean", true},
    }

    local datefmt = DICT_FORMAT[config.format_name]
    local only_valid = util.unwrap_or(config.only_valid, false)

    return setmetatable({ datefmt = datefmt, only_valid = only_valid, kind = "day" }, {__index = AugendDate})
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
    util.dbg{text = text, cursor = cursor}
    self.kind = self.datefmt.judge_datekind(text, cursor - range.from + 1)
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
    return {text = text, cursor = cursor}
end

return AugendDate
