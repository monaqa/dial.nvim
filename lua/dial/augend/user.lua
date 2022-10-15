local util = require "dial.util"
local common = require "dial.augend.common"

---@alias AugendUserConfig { find: findf, add: addf }

---@class AugendUser
---@implement Augend
---@field config AugendUserConfig
local AugendUser = {}

---@param config AugendUserConfig
---@return Augend
function AugendUser.new(config)
    vim.validate {
        find = { config.find, "function" },
        add = { config.add, "function" },
    }

    return setmetatable({ config = config }, { __index = AugendUser })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendUser:find(line, cursor)
    return self.config.find(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendUser:add(text, addend, cursor)
    return self.config.add(text, addend, cursor)
end

return AugendUser
