local util = require "dial.util"

---@alias AugendOrdinalConfig {}

---@class AugendOrdinal
---@implement Augend
---@field natural boolean
---@field query string
---@field suffix { default: string, special?: string[] }
---@field case '"lower"' | '"upper"' | '"prefer_lower"' | '"prefer_upper"'
local AugendOrdinal = {}

local M = {}

---@param config { natural?: boolean, suffix?: table, case?: '"lower"' | '"upper"' | '"prefer_lower"' | '"prefer_upper"' }
---@return Augend
function M.new(config)
    vim.validate("natural", config.natural, "boolean", true)
    vim.validate("suffix", config.suffix, "table", true)
    vim.validate("case", config.case, "string", true)

    local natural = util.unwrap_or(config.natural, true)
    local case = util.unwrap_or(config.case, "lower")

    local suffix = util.unwrap_or(config.suffix, {
        default = "th",
        special = {
            "st",
            "nd",
            "rd",
        },
    })

    local query = "%d+" .. string.rep("%a", #suffix.default)

    if not natural then
        query = "-?" .. query
    end

    return setmetatable({
        natural = natural,
        query = query,
        suffix = suffix,
        case = case,
    }, { __index = AugendOrdinal })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendOrdinal:find(line, cursor)
    local idx_start = 1

    local check_query = "%d+%a+"

    if not self.natural then
        check_query = "-?" .. check_query
    end

    while idx_start <= #line do
        local mark_start, mark_end = line:find(self.query, idx_start)
        local _, check_end = line:find(check_query, idx_start)

        if mark_start then
            if (cursor == nil or cursor <= mark_end) and check_end == mark_end then
                return { from = mark_start, to = mark_end }
            else
                idx_start = mark_end + 1
            end
        else
            break
        end
    end

    return nil
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendOrdinal:add(text, addend, cursor)
    local ordinal_query = "%d+"

    if not self.natural then
        ordinal_query = "-?" .. ordinal_query
    end

    for ordinal in text:gmatch(ordinal_query) do
        local cardinal = ordinal + addend

        if (cardinal < 0) and self.natural then
            cardinal = 0
        end

        local remainder = math.abs(cardinal) % 100

        -- WARN: the following statement only works for the english language
        local suffix = not vim.tbl_contains({ 11, 12, 13 }, remainder) and self.suffix.special[remainder % 10]
            or self.suffix.default

        -- TODO: make use of `case` to changing final casing of suffix
        text = cardinal .. suffix
    end

    cursor = 1

    return { text = text, cursor = cursor }
end

M.alias = {
    en = M.new {},
    en_neg = M.new { natural = false },
}

return M
