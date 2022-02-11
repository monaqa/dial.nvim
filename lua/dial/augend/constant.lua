local util = require"dial.util"
local common = require"dial.augend.common"

---@alias AugendConstantConfig { elements: string[], cyclic: boolean, pattern_regexp: string }

---@class AugendConstant
---@implement Augend
---@field config AugendConstantConfig
local AugendConstant = {}

local M = {}

---@param config { elements: string[], word?: boolean, cyclic?: boolean, pattern_regexp?: string }
---@return Augend
function M.new(config)
    util.validate_list("config.elements", config.elements, "string")

    vim.validate{
        word = {config.word, "boolean", true},
        cyclic = {config.cyclic, "boolean", true},
        pattern_regexp = {config.pattern_regexp, "string", true}
    }
    if config.pattern_regexp == nil then
        if config.word == false then
            config.pattern_regexp = [[\C\V\(%s\)]]
        else
            config.pattern_regexp = [[\C\V\<\(%s\)\>]]
        end
    end
    if config.cyclic == nil then
        config.cyclic = false
    end
    return setmetatable({config = config}, {__index = AugendConstant})
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendConstant:find(line, cursor)
    local escaped_elements = vim.tbl_map(
        function (e)
            return vim.fn.escape(e, [[/\]])
        end,
        self.config.elements
    )
    local vim_regex_ptn = self.config.pattern_regexp:format(table.concat(escaped_elements, [[\|]]))
    return common.find_pattern_regex(vim_regex_ptn)(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendConstant:add(text, addend, cursor)
    local elements = self.config.elements
    local n_patterns = #elements
    local n = 1
    for i, elem in ipairs(elements) do
        if text == elem then
            n = i
        end
    end
    n = (n + addend - 1) % n_patterns + 1
    text = elements[n]
    cursor = #text
    return { text = text, cursor = cursor }
end

return M
