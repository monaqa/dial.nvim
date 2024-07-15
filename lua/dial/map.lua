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
---@param count? integer
local function _cmd_sequence(direction, mode, group_name, count)
    local select
    if group_name == nil then
        select = cmdcr([[lua require"dial.command".select_augend_]] .. mode .. "()")
    else
        select =
            cmdcr([[lua require"dial.command".select_augend_]] .. mode .. [[(]] .. vim.fn.string(group_name) .. [[)]])
    end
    -- command.select_augend_normal(vim.v.count, group_name)
    local setopfunc = cmdcr([[let &opfunc="dial#operator#]] .. direction .. "_" .. mode .. [["]])
    local textobj =
        util.if_expr(mode == "normal" or mode == "gnormal", cmdcr [[lua require("dial.command").textobj()]], "")

    if count ~= nil then
        if type(count) ~= "number" then
            error "count must be a integer."
        end
        return count .. select .. setopfunc .. "g@" .. textobj
    end
    return select .. setopfunc .. "g@" .. textobj
end

---Functional interface
---@param direction direction
---@param mode mode
---@param group_name? string
---@param count? integer
function M.manipulate(direction, mode, group_name, count)
    if count == nil then
        count = vim.v.count1
    end
    vim.cmd.normal {
        vim.api.nvim_replace_termcodes(_cmd_sequence(direction, mode, group_name, count), true, true, true),
        bang = true,
    }
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
function M.inc_gnormal(group_name)
    return _cmd_sequence("increment", "gnormal", group_name)
end

---@param group_name? string
---@return string
function M.dec_gnormal(group_name)
    return _cmd_sequence("decrement", "gnormal", group_name)
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
