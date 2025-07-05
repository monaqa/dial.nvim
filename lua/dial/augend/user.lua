---@alias AugendUserConfig { find: findf, add: addf }

---@class AugendUser: Augend
---@field config AugendUserConfig
local AugendUser = {}

---@param config AugendUserConfig
---@return AugendUser
function AugendUser.new(config)
    vim.validate("find", config.find, "function")
    vim.validate("add", config.add, "function")

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
---@return addresult?
function AugendUser:add(text, addend, cursor)
    return self.config.add(text, addend, cursor)
end

return AugendUser
