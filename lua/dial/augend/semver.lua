local util = require "dial.util"
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

---@class AugendSemver
---@implement Augend
---@field kind '"major"' | '"minor"' | '"patch"'
local AugendSemver = {}

local M = {}

---@param config {}
---@return Augend
function M.new(config)
    vim.validate {}

    return setmetatable({ kind = "patch" }, { __index = AugendSemver })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendSemver:find(line, cursor)
    return common.find_pattern "%d+%.%d+%.%d+"(line, cursor)
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendSemver:find_stateful(line, cursor)
    local range = common.find_pattern "%d+%.%d+%.%d+"(line, cursor)
    if range == nil then
        return
    end

    if cursor == nil then
        -- always increments patch version in VISUAL mode
        self.kind = "patch"
        return range
    end
    local relcurpos = cursor - range.from + 1
    local text = line:sub(range.from, range.to)
    local iterator = text:gmatch "%d+"
    local major = iterator()
    local minor = iterator()

    if relcurpos <= 0 then
        self.kind = "patch"
    elseif relcurpos <= #major then
        self.kind = "major"
    elseif relcurpos <= #major + #minor + 1 then
        self.kind = "minor"
    else
        self.kind = "patch"
    end
    return range
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendSemver:add(text, addend, cursor)
    local iterator = text:gmatch "%d+"
    local major = tonumber(iterator())
    local minor = tonumber(iterator())
    local patch = tonumber(iterator())

    if cursor == nil then
        cursor = 0
    end -- default: all

    if self.kind == "major" then
        major = major + addend
        if addend > 0 then
            minor = 0
            patch = 0
        end
        cursor = #tostring(major)
    elseif self.kind == "minor" then
        minor = minor + addend
        if addend > 0 then
            patch = 0
        end
        cursor = #tostring(major) + 1 + #tostring(minor)
    else -- (if cursor == 6 or cursor == 7 then)
        patch = patch + addend
        cursor = #tostring(major) + 1 + #tostring(minor) + 1 + #tostring(patch)
    end
    text = ("%d.%d.%d"):format(major, minor, patch)
    return { text = text, cursor = cursor }
end

M.alias = {
    semver = M.new {},
}

return M
