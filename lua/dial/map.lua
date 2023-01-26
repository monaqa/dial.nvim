local M = {}

local command = require "dial.command"
local util = require "dial.util"

---Sandwich input string between <Cmd> and <CR>.
---@param body string
local function cmdcr(body)
    local cmd_sequences = "<Cmd>"
    local cr_sequences = "<CR>"
    return cmd_sequences .. body .. cr_sequences
end

---Output command sequence which provides dial operation.
---@param direction direction
---@param mode mode
---@param group_name? string
local function _cmd_sequence(direction, mode, group_name)
    group_name = group_name ~= nil and tostring(group_name) or ""

    local select = cmdcr([[lua require"dial.command".select_augend_]] .. mode .. [[(]] .. group_name .. [[)]])
    -- command.select_augend_normal(vim.v.count, group_name)
    local setopfunc = cmdcr([[let &opfunc="dial#operator#]] .. direction .. "_" .. mode .. [["]])
    local textobj = util.if_expr(mode == "normal", cmdcr [[lua require("dial.command").textobj()]], "")
    return select .. setopfunc .. "g@" .. textobj
end

---@param group_name? string
---@return string
function M.inc_normal(group_name)
    return _cmd_sequence("increment", "normal", group_name)
end

---@param group_name? string
---@return string
function M.dec_normal(group_name)
    return _cmd_sequence("decrement", "normal", group_name)
end

---@param group_name? string
---@return string
function M.inc_visual(group_name)
    return _cmd_sequence("increment", "visual", group_name)
end

---@param group_name? string
---@return string
function M.dec_visual(group_name)
    return _cmd_sequence("decrement", "visual", group_name)
end

---@param group_name? string
---@return string
function M.inc_gvisual(group_name)
    return _cmd_sequence("increment", "gvisual", group_name)
end

---@param group_name? string
---@return string
function M.dec_gvisual(group_name)
    return _cmd_sequence("decrement", "gvisual", group_name)
end

return M
