local common = require "dial.augend.common"

local function cast_u8(n)
    if n <= 0 then
        return 0
    end
    if n >= 255 then
        return 255
    end
    return n
end

---@alias colorcase '"upper"' | '"lower"' | '"prefer_upper"' | '"prefer_lower"'
---@alias colorkind '"r"' | '"g"' | '"b"' | '"all"'

---@class AugendHexColor
---@implement Augend
---@field config { case: colorcase }
---@field kind colorkind
local AugendHexColor = {}

local M = {}

---@param config? { case: colorcase }
---@return Augend
function M.new(config)
    config = config or { case = "prefer_lower" }

    if
        config.case ~= "upper"
        and config.case ~= "lower"
        and config.case ~= "prefer_upper"
        and config.case ~= "prefer_lower"
    then
        error("invalid case: " .. config.case)
    end

    return setmetatable({
        config = config,
        kind = "all",
    }, { __index = AugendHexColor }) --[[@as Augend]]
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendHexColor:find(line, cursor)
    return common.find_pattern "#%x%x%x%x%x%x"(line, cursor)
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendHexColor:find_stateful(line, cursor)
    local range = common.find_pattern "#%x%x%x%x%x%x"(line, cursor)
    if range == nil then
        return
    end
    local relcurpos = cursor - range.from + 1
    if relcurpos <= 1 then
        self.kind = "all"
    elseif relcurpos <= 3 then
        self.kind = "r"
    elseif relcurpos <= 5 then
        self.kind = "g"
    else
        self.kind = "b"
    end
    return range
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendHexColor:add(text, addend, cursor)
    local r = tonumber(text:sub(2, 3), 16)
    local g = tonumber(text:sub(4, 5), 16)
    local b = tonumber(text:sub(6, 7), 16)

    if cursor == nil then
        cursor = 1
    end

    -- default: all
    if self.kind == "all" then
        -- increment all
        r = cast_u8(r + addend)
        g = cast_u8(g + addend)
        b = cast_u8(b + addend)
        cursor = 1
    elseif self.kind == "r" then
        r = cast_u8(r + addend)
        cursor = 3
    elseif self.kind == "g" then
        g = cast_u8(g + addend)
        cursor = 5
    else
        b = cast_u8(b + addend)
        cursor = 7
    end

    local has_upper = text:match "[A-F]" ~= nil
    local has_lower = text:match "[a-f]" ~= nil
    local is_mixed_case = has_upper and has_lower

    text = "#" .. string.format("%02x", r) .. string.format("%02x", g) .. string.format("%02x", b)

    if self.config.case == "upper" then
        text = text:upper()
    elseif self.config.case == "lower" then
        text = text:lower()
    elseif self.config.case == "prefer_upper" then
        if not has_lower or is_mixed_case then
            text = text:upper()
        end
    elseif self.config.case == "prefer_lower" then
        if has_upper and not has_lower then
            text = text:upper()
        else
            text = text:lower()
        end
    end

    return { text = text, cursor = cursor }
end

return M
