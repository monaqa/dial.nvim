local util = require"dial.util"
local common = require"dial.augend.common"

---@alias dateptn { regex: string, capture: datekind[] }
---@alias datekind '"year"' | '"month"' | '"day"' | '"hour"' | '"minute"' | '"second"'
---@alias datefmt { pattern: dateptn, format: string, judge_datekind: judge_datekind, calc_curpos: calc_curpos, only_valid: boolean }
---@alias judge_datekind fun(text: string, curpos?: integer) -> datekind
---@alias calc_curpos fun(text: string, kind: datekind) -> integer?
-- parse: 日付の検出に用いられる正規表現
-- format: 日付を文字列に変換するときに用いられる正規表現

---@type datefmt[]
local DICT_FORMAT = {}

DICT_FORMAT["yyyy-MM-dd"] = {
    pattern = {
        regex = [[(\d{4})-(\d{2})-(\d{2})]],
        capture = { "year", "month", "day" }
    },
    format = "%Y-%m-%d",
    only_valid = false,

    ---テキストとカーソル位置から増減対象の datekind を判断する。
    ---@param text string
    ---@param curpos? integer  # 1-based
    ---@return datekind
    judge_datekind = function (text, curpos)
        if curpos == nil or curpos <= 0 or curpos >= 8 then
            return "day"
        elseif curpos <= 4 then
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
        if kind == "year" then
            return 4
        elseif kind == "month" then
            return 7
        else
            return 10
        end

    end,
}

---@class AugendDate
---@implement Augend
---@field datefmt datefmt
---@field kind datekind
local AugendDate = {}

---@param config { format_name: string }
---@return Augend
function AugendDate.new(config)
    vim.validate{
        format_name = {config.format_name, "string"},
    }

    local datefmt = DICT_FORMAT[config.format_name]

    return setmetatable({ datefmt = datefmt, kind = "day" }, {__index = AugendDate})
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

    return range
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDate:find_stateful(line, cursor)
    local range = common.find_pattern_regex([[\v]] .. self.datefmt.pattern.regex)(line, cursor)
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
    -- return self.config.add(text, addend, cursor)
    local matchlist = vim.fn.matchlist(text, [[\v]] .. self.datefmt.pattern.regex)

    ---@type {year?: integer, month?: integer, day?: integer, hour?: integer, minute?: integer, second?: integer}
    local dt_info = {}
    for i, kind in ipairs(self.datefmt.pattern.capture) do
        dt_info[kind] = tonumber(matchlist[i + 1])
    end

    if self.kind == "year" then
        dt_info.year = dt_info.year + addend
    elseif self.kind == "month" then
        dt_info.month = dt_info.month + addend
    elseif self.kind == "day" then
        dt_info.day = dt_info.day + addend
    elseif self.kind == "hour" then
        dt_info.hour = dt_info.hour + addend
    elseif self.kind == "minute" then
        dt_info.minute = dt_info.minute + addend
    elseif self.kind == "second" then
        dt_info.second = dt_info.second + addend
    end

    local datetime = os.time(dt_info)
    text = os.date(self.datefmt.format, datetime)
    cursor = self.datefmt.calc_curpos(text, self.kind)
    return {text = text, cursor = cursor}
end

return AugendDate
