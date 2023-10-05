local common = require "dial.augend.common"
local util = require "dial.util"

---@class AugendDecimalFraction
---@implement Augend
---@field signed boolean
---@field point_char string
local AugendDecimalFraction = {}

local M = {}

---@param config { signed?: boolean, point_char?: string }
---@return Augend
function M.new(config)
    vim.validate {
        signed = { config.signed, "boolean", true },
        point_char = { config.point_char, "string", true },
    }

    local signed = util.unwrap_or(config.signed, false)
    local point_char = util.unwrap_or(config.point_char, ".")
    local digits_to_add = 0

    return setmetatable({
        signed = signed,
        point_char = point_char,
        digits_to_add = digits_to_add,
    }, { __index = AugendDecimalFraction })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDecimalFraction:find(line, cursor)
    local idx = 1
    local integer_pattern
    if self.signed then
        integer_pattern = "%-?%d+"
    else
        integer_pattern = "%d+"
    end
    while idx <= #line do
        local idx_integer_start, idx_integer_end = line:find(integer_pattern, idx)
        if idx_integer_start == nil then
            break
        end

        local result = (function()
            idx = idx_integer_end + 1
            -- invalid decimal fraction format
            if line:sub(idx, idx) ~= self.point_char then
                return -- continue while loop
            end
            idx = idx + 1
            local idx_frac_start, idx_frac_end = line:find("^%d+", idx)
            -- invalid decimal fraction format
            if idx_frac_start == nil then
                return -- continue while loop
            end
            idx = idx_frac_end + 1
            -- decimal fraction before the cursor
            if cursor ~= nil and idx_frac_end < cursor then
                return -- continue while loop
            end

            -- negative lookahead
            if line:sub(idx, idx) == self.point_char then
                return -- continue while loop
            end
            -- break loop and return value
            return { from = idx_integer_start, to = idx_frac_end }
        end)()

        if result ~= nil then
            return result
        end
    end
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendDecimalFraction:find_stateful(line, cursor)
    local result = self:find(line, cursor)
    if result == nil then
        return nil
    end

    local point_pos = line:find(self.point_char, result.from, true)
    if cursor < point_pos then
        -- increment integer part
        self.digits_to_add = 0
    else
        -- increment decimal part
        self.digits_to_add = result.to - point_pos
    end
    return result
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendDecimalFraction:add(text, addend, cursor)
    local point_pos = text:find(self.point_char, 1, true)

    local int_part = text:sub(1, point_pos - 1)
    local frac_part = text:sub(point_pos + 1)

    -- 桁数調整。元の数字が 12.3 なのに 0.01 を足したいとき、 12.31 になるようにする
    if #frac_part < self.digits_to_add then
        frac_part = frac_part .. ("0"):rep(self.digits_to_add - #frac_part)
    end

    local num = tonumber(int_part .. frac_part)
    local add_num = addend * math.floor(10 ^ (#frac_part - self.digits_to_add))
    num = num + add_num
    if not self.signed and num < 0 then
        num = 0
    end
    local str_num = tostring(num)

    if num < 0 then
        if #str_num - 1 <= #frac_part then
            str_num = "-" .. ("0"):rep(#frac_part + 2 - #str_num) .. str_num:sub(2)
        end
    else
        if #str_num <= #frac_part then
            str_num = ("0"):rep(#frac_part + 1 - #str_num) .. str_num
        end
    end

    -- pad as necessary
    local new_int_part = str_num:sub(1, #str_num - #frac_part)
    local new_dec_part = str_num:sub(#str_num - #frac_part + 1)

    text = new_int_part .. "." .. new_dec_part
    if self.digits_to_add == 0 then
        -- incremented integer part
        cursor = #new_int_part
    else
        cursor = #text
    end

    return { text = text, cursor = cursor }
end

M.alias = {}

return M
