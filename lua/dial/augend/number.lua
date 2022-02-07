local common = require"dial.augend.common"

-- ---@alias AugendNumberConfig { radix: integer, prefix: string, natural: boolean }
---@alias AugendNumberConfig {}

---@class AugendNumber
---@implement Augend
---@field config AugendNumberConfig
local AugendNumber = {}

local M = {}

-- ---@param config { radix?: integer, prefix?: string, natural?: boolean }
---@param config {}
---@return Augend
function M.new(config)
    -- vim.validate{
    --     radix = {config.radix, "number", true},
    --     prefix = {config.prefix, "string", true},
    --     natural = {config.natural, "boolean", true},
    -- }
    -- config.radix = config.radix or 10
    -- config.prefix = config.prefix or ""
    -- config.natural = config.natural or true

    return setmetatable({config = config}, {__index = AugendNumber})
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendNumber:find(line, cursor)
    return common.find_pattern("%d+")(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
function AugendNumber:add(text, addend, cursor)
    local n = tonumber(text)
    local n_string_digit = text:len()
    local n_actual_digit = tostring(n):len()
    n = n + addend
    if n < 0 then
        n = 0
    end
    if n_string_digit == n_actual_digit then
        -- 増減前の数字が0か0始まりでない数字だったら
        text = ("%d"):format(n)
    else
        -- 増減前の数字が0始まりの正の数だったら
        text = ("%0" .. n_string_digit .. "d"):format(n)
    end
    cursor = #text
    return {text = text, cursor = cursor}
end

return M
