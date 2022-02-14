local M = {}

local command = require"dial.command"
local util    = require "dial.util"

---入力文字列を <Cmd> 及び <CR> で挟む。
---@param body string
local function cmd(body)
    -- local cmd_sequences = string.char(128, 253, 104)
    -- local cr_sequences = string.char(13)
    local cmd_sequences = '<Cmd>'
    local cr_sequences = '<CR>'
    return cmd_sequences .. body .. cr_sequences
    -- return cmd_sequences .. body .. "\n"
end

---dial 操作を提供するコマンド列を出力する。
---@param direction direction
---@param mode mode
---@param group_name? string
local function _cmd_sequence(direction, mode, group_name)
    local select
    if group_name == nil then
        select = cmd(
        [[lua require"dial.command".select_augend_]] .. mode .. "()"
        )
    else
        select = cmd(
        [[lua require"dial.command".select_augend_]] .. mode
        .. [[("]] .. group_name .. [[")]]
        )
    end
    -- command.select_augend_normal(vim.v.count, group_name)
    local setopfunc = cmd([[let &opfunc="dial#operator#]] .. direction .. "_" .. mode .. [["]])
    local textobj = util.if_expr(mode == "normal", cmd[[lua require("dial.command").textobj()]], "")
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
