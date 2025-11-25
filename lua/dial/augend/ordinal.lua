local common = require "dial.augend.common"
local util = require "dial.util"

---@alias ordinalSuffix { default: string, special?: string[] }

---@alias AugendOrdinalConfig { natural?: boolean, suffix?: ordinalSuffix }

---@class AugendOrdinal: Augend
---@field natural boolean
---@field suffix ordinalSuffix
---@field query string
---@field check_query? string
local AugendOrdinal = {}

---@param line string
---@param cursor? integer
---@return textrange?
function AugendOrdinal:find(line, cursor)
    return common.find_pattern_regex(self.query, false, self.check_query)(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return addresult
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

        text = cardinal .. suffix
    end

    cursor = 1

    return { text = text, cursor = cursor }
end

local M = {}

---@param config AugendOrdinalConfig
---@return Augend
function M.new(config)
    vim.validate("natural", config.natural, "boolean", true)
    vim.validate("suffix", config.suffix, "table", true)

    local natural = util.unwrap_or(config.natural, true)

    local suffix = util.unwrap_or(config.suffix, {
        default = "th",
        special = {
            "st",
            "nd",
            "rd",
        },
    })

    -- WARN: the following queries only work for the english language
    local query = ([[\V%s\d\+\a\{1,2}]]):format(util.if_expr(natural, "", [[-\?]]))
    local check_query = ([[\V%s\d\+\a\+]]):format(util.if_expr(natural, "", [[-\?]]))

    return setmetatable({
        natural = natural,
        suffix = suffix,
        query = query,
        check_query = check_query,
    }, { __index = AugendOrdinal })
end

M.alias = {
    en = M.new {},
    en_neg = M.new { natural = false },
}

return M
