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
    local select
    if group_name == nil then
        select = cmdcr([[lua require"dial.command".select_augend_]] .. mode .. "()")
    else
        select = cmdcr([[lua require"dial.command".select_augend_]] .. mode .. [[("]] .. group_name .. [[")]])
    end
    -- command.select_augend_normal(vim.v.count, group_name)
    local setopfunc = cmdcr([[let &opfunc="dial#operator#]] .. direction .. "_" .. mode .. [["]])
    local textobj = util.if_expr(mode == "normal", cmdcr [[lua require("dial.command").textobj()]], "")
    return select .. setopfunc .. "g@" .. textobj
end

---@param v string | nil | fun(): string | nil
---@return string | nil
local function apply_if_function(v)
    if type(v) == "function" then
        return v()
    else
        return v
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.inc_normal(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("increment", "normal", group_name), true, true, true)
        )
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.dec_normal(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("decrement", "normal", group_name), true, true, true)
        )
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.inc_visual(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.pretty_print { _cmd_sequence("increment", "visual", group_name) }
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("increment", "visual", group_name), true, true, true)
        )
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.dec_visual(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("decrement", "visual", group_name), true, true, true)
        )
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.inc_gvisual(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("increment", "gvisual", group_name), true, true, true)
        )
    end
end

---@param group_name_or_fn? string | nil | fun(): string | nil
---@return fun(): nil
function M.dec_gvisual(group_name_or_fn)
    return function()
        local group_name = apply_if_function(group_name_or_fn)
        vim.cmd.normal(
            vim.api.nvim_replace_termcodes(_cmd_sequence("decrement", "gvisual", group_name), true, true, true)
        )
    end
end

return M
