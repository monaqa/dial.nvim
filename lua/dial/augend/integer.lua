local common = require "dial.augend.common"
local util = require "dial.util"

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

---@class BigInt
---@field sign 1|-1
---@field digits table<integer>
---@field radix integer
---@field plus fun(self:BigInt, value:BigInt, natural:boolean):BigInt `value` must be positive
---@field minus fun(self:BigInt, value:BigInt, natural:boolean):BigInt `value` must be positive
---@field to_string fun(self:BigInt, case:'"upper"'|'"lower"'):string
local BigInt = {}

---@param n string|integer
---@param radix integer
---@return BigInt
function BigInt.new(n, radix)
    local self = {
        sign = 1,
        digits = {},
        radix = radix,
    }

    local base_len = 8
    local base = self.radix ^ base_len

    local remove_top_0 = function(digits)
        for i = #digits, 2, -1 do
            if digits[i] == 0 then
                digits[i] = nil
            else
                return
            end
        end
    end

    if type(n) == "string" then
        if n:sub(1, 1) == "-" then
            self.sign = -1
            n = n:sub(2)
        end
        local n_length = n:len()
        for i = n_length, 1, -base_len do
            local splited = n:sub(math.max(1, i - base_len + 1), i)
            table.insert(self.digits, tonumber(splited, radix))
        end
        remove_top_0(self.digits)
    else
        if n < 0 then
            self.sign = -1
            n = -n
        end
        repeat
            table.insert(self.digits, n % base)
            n = math.floor(n / base)
        until n == 0
    end

    -- Define methods

    ---@param value BigInt must be positive
    ---@param natural boolean
    ---@return BigInt
    function self:plus(value, natural)
        if self.sign == -1 then
            -- -self + value = value - self
            self.sign = 1
            return value:minus(self, natural)
        end

        -- For now, self and value is positive
        -- Calculate self + value

        local max_digits
        if #self.digits < #value.digits then
            max_digits = #value.digits
            self, value = value, self
        else
            max_digits = #self.digits
        end

        local carry = 0
        for i = 1, max_digits, 1 do
            local sum = (self.digits[i] or 0) + (value.digits[i] or 0) + carry
            if sum >= base then
                carry = 1
                sum = sum - base
            else
                carry = 0
            end
            self.digits[i] = sum
        end
        if carry == 1 then
            table.insert(self.digits, 1)
        end

        return self
    end

    ---@param value BigInt must be positive
    ---@param natural boolean
    ---@return BigInt
    function self:minus(value, natural)
        if self.sign == -1 then
            -- -self - value = -(self + value)
            self.sign = 1
            self = self:plus(value, natural)
            self.sign = -1
            return self
        end

        -- For now, self and value is positive
        -- Calculate self - value

        local value_is_large = (
            #self.digits < #value.digits
            or (#self.digits == #value.digits and self.digits[#self.digits] < value.digits[#value.digits])
        )
        if natural and value_is_large then
            self.digits = { 0 }
            return self
        end

        local max_digits
        if value_is_large then
            max_digits = #value.digits
            self, value = value, self
            self.sign = -1
        else
            max_digits = #self.digits
        end

        local borrow = 0
        for i = 1, max_digits, 1 do
            local diff = (self.digits[i] or 0) - (value.digits[i] or 0) - borrow
            if diff < 0 then
                borrow = 1
                diff = diff + base
            else
                borrow = 0
            end
            self.digits[i] = diff
        end
        if borrow == 1 then
            self.digits[#self.digits] = self.digits[#self.digits] - 1
        end

        remove_top_0(self.digits)
        return self
    end

    ---@param case '"upper"' | '"lower"'
    ---@return string
    function self:to_string(case)
        local digits
        if case == "upper" then
            digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        else
            digits = "0123456789abcdefghijklmnopqrstuvwxyz"
        end

        local ret = ""
        if self.sign == -1 then
            ret = "-"
        end

        local d = self.digits[#self.digits]
        local s = ""
        repeat
            local r = d % self.radix
            d = math.floor(d / self.radix)
            s = digits:sub(r + 1, r + 1) .. s
        until d == 0
        ret = ret .. s
        for i = #self.digits - 1, 1, -1 do
            d = self.digits[i]
            s = ""
            for _ = 1, base_len, 1 do
                local r = d % self.radix
                d = math.floor(d / self.radix)
                s = digits:sub(r + 1, r + 1) .. s
            end
            ret = ret .. s
        end

        return ret
    end

    return self
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
    vim.validate {
        radix = { config.radix, "number", true },
        prefix = { config.prefix, "string", true },
        natural = { config.natural, "boolean", true },
        case = { config.case, "string", true },
        delimiter = { config.delimiter, "string", true },
        delimiter_digits = { config.delimiter_digits, "number", true },
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

    return setmetatable({
        radix = radix,
        prefix = prefix,
        natural = natural,
        query = query,
        case = case,
        delimiter = delimiter,
        delimiter_digits = delimiter_digits,
    }, { __index = AugendInteger })
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
        subtext = subtext:gsub(ptn, "")
    end

    local n = BigInt.new(subtext, self.radix)
    local n_string_digit = subtext:len()
    local n_actual_digit = n:to_string(self.case):len()
    if addend >= 0 then
        n = n:plus(BigInt.new(addend, self.radix), self.natural)
    else
        n = n:minus(BigInt.new(-addend, self.radix), self.natural)
    end

    local digits
    if n_string_digit == n_actual_digit then
        -- 増減前の数字が0か0始まりでない数字だったら
        -- text = ("%d"):format(n)
        digits = n:to_string(self.case)
    else
        -- 増減前の数字が0始まりの正の数だったら
        -- text = ("%0" .. n_string_digit .. "d"):format(n)
        local num_string = n:to_string(self.case)
        local pad = ("0"):rep(math.max(n_string_digit - num_string:len(), 0))
        digits = pad .. num_string
    end
    if self.delimiter ~= "" then
        digits = add_delimiter(digits, self.delimiter, self.delimiter_digits)
    end

    text = self.prefix .. digits
    cursor = #text
    return { text = text, cursor = cursor }
end

M.alias = {
    decimal = M.new {},
    decimal_int = M.new { natural = false },
    binary = M.new { radix = 2, prefix = "0b", natural = true },
    octal = M.new { radix = 8, prefix = "0o", natural = true },
    hex = M.new { radix = 16, prefix = "0x", natural = true },
}

return M
