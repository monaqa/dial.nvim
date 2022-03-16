local common = require"dial.augend.common"
local util   = require "dial.util"

---@alias AugendIntegerConfig {}

---@class AugendInteger
---@implement Augend
---@field radix integer
---@field prefix string
---@field natural boolean
---@field query string
---@field case '"upper"' | '"lower"'
---@field delimiter string
---@field delimiter_digits integer
local AugendInteger = {}

local M = {}

---convert integer with given prefix
---@param n integer
---@param radix integer
---@param case '"upper"' | '"lower"'
---@return string
local function tostring_with_radix(n, radix, case)
    local floor,insert = math.floor, table.insert
    n = floor(n)
    if not radix or radix == 10 then return tostring(n) end

    local digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    if case == "upper" then
        digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end

    local t = {}
    local sign = ""
    if n < 0 then
        sign = "-"
    n = -n
    end
    repeat
        local d = (n % radix) + 1
        n = floor(n / radix)
        insert(t, 1, digits:sub(d,d))
    until n == 0
    return sign .. table.concat(t,"")
end

---デリミタを挟んだ数字を出力する。
---@param digits string
---@param delimiter string
---@param delimiter_digits integer
---@return string
local function add_delimiter(digits, delimiter, delimiter_digits)
    local blocks = {}
    if #digits <= delimiter_digits then
        return digits
    end
    for i = 0, #digits - 1, delimiter_digits do
        -- 部分文字列の終端は右から i 桁目
        local e = #digits - i
        -- e から数えて delimiter_digits の数だけ取る
        local s = e - delimiter_digits + 1
        if s < 1 then
            s = 1
        end
        table.insert(blocks, 1, digits:sub(s, e))
    end
    return table.concat(blocks, delimiter)
end

---@param radix integer
---@return string
local function radix_to_query_character(radix)
    if radix < 2 or radix > 36 then
        error(("radix must satisfy 2 <= radix <= 36, got %d"):format(radix))
    end
    if radix <= 10 then
        return "0-" .. tostring(radix - 1)
    end
    return "0-9a-" .. string.char(86 + radix) .. "A-" .. string.char(54 + radix)
end

---@param config { radix?: integer, prefix?: string, natural?: boolean, case?: '"upper"' | '"lower"', delimiter?: string, delimiter_digits?: number }
---@return Augend
function M.new(config)
    vim.validate{
        radix = {config.radix, "number", true},
        prefix = {config.prefix, "string", true},
        natural = {config.natural, "boolean", true},
        case = {config.case, "string", true},
        delimiter = {config.delimiter, "string", true},
        delimiter_digits = {config.delimiter_digits, "number", true},
    }
    local radix = util.unwrap_or(config.radix, 10)
    local prefix = util.unwrap_or(config.prefix, "")
    local natural = util.unwrap_or(config.natural, true)
    local case = util.unwrap_or(config.case, "lower")
    local delimiter = util.unwrap_or(config.delimiter, "")
    local delimiter_digits = util.unwrap_or(config.delimiter_digits, 3)

    -- local query = prefix .. util.if_expr(natural, "", "-?") .. "[" .. radix_to_query_character(radix) .. delimiter .. "]+"
    local query = ([[\V%s%s\(\[%s]\+%s\)\*\[%s]\+]]):format(
        prefix,
        util.if_expr(natural, "", [[-\?]]),
        radix_to_query_character(radix),
        vim.fn.escape(delimiter, [[]\/]]),
        radix_to_query_character(radix)
        )

    return setmetatable(
        {
            radix = radix,
            prefix = prefix,
            natural = natural,
            query = query,
            case = case,
            delimiter = delimiter,
            delimiter_digits = delimiter_digits,
        },
        {__index = AugendInteger}
    )
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendInteger:find(line, cursor)
    return common.find_pattern_regex(self.query)(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendInteger:add(text, addend, cursor)
    local n_prefix = #self.prefix
    local subtext = text:sub(n_prefix + 1)
    if self.delimiter ~= "" then
        local ptn = self.delimiter
        if ptn == "." or ptn == "%" or ptn == "^" or ptn == "$" then
            ptn = "%" .. ptn
        end
        subtext = text:gsub(ptn, "")
    end
    local n = tonumber(subtext, self.radix)
    local n_string_digit = subtext:len()
    -- local n_actual_digit = tostring(n):len()
    local n_actual_digit = tostring_with_radix(n, self.radix, self.case):len()
    n = n + addend
    if self.natural and n < 0 then
        n = 0
    end
    local digits
    if n_string_digit == n_actual_digit then
        -- 増減前の数字が0か0始まりでない数字だったら
        -- text = ("%d"):format(n)
        digits = tostring_with_radix(n, self.radix, self.case)
    else
        -- 増減前の数字が0始まりの正の数だったら
        -- text = ("%0" .. n_string_digit .. "d"):format(n)
        local num_string = tostring_with_radix(n, self.radix, self.case)
        local pad = ("0"):rep(math.max(n_string_digit - num_string:len(), 0))
        digits = pad .. num_string
    end
    if self.delimiter ~= "" then
        digits = add_delimiter(digits, self.delimiter, self.delimiter_digits)
    end
    text = self.prefix .. digits
    cursor = #text
    return {text = text, cursor = cursor}
end

M.alias = {
    decimal = M.new{},
    decimal_int = M.new{ natural = false },
    binary = M.new{ radix = 2, prefix = "0b", natural = true },
    octal = M.new{ radix = 8, prefix = "0o", natural = true },
    hex = M.new{ radix = 16, prefix = "0x", natural = true },
}

return M
