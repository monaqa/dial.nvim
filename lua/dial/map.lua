local M = {}

---@param direction direction
---@param mode mode
---@param group_name? string|fun():string
---@return fun():nil
local function _cmd_sequence(direction, mode, group_name)
  return function()
    local name
    if type(group_name) == "function" then
      name = group_name()
    else
      name = group_name
    end

    local selector =  require("dial.command")["select_augend_" .. mode]
    selector(name)

    vim.go.opfunc = ("dial#operator#%s_%s"):format(direction, mode)

    vim.api.nvim_feedkeys('g@l', 'n', false)

    if mode == "normal" then
      require("dial.command").textobj()
    end

  end
end

---@param group_name? string|fun():string
---@return fun():nil
function M.inc_normal(group_name)
    return _cmd_sequence("increment", "normal", group_name)
end

---@param group_name? string|fun():string
---@return fun():nil
function M.dec_normal(group_name)
    return _cmd_sequence("decrement", "normal", group_name)
end

---@param group_name? string|fun():string
---@return fun():nil
function M.inc_visual(group_name)
    return _cmd_sequence("increment", "visual", group_name)
end

---@param group_name? string|fun():string
---@return fun():nil
function M.dec_visual(group_name)
    return _cmd_sequence("decrement", "visual", group_name)
end

---@param group_name? string|fun():string
---@return fun():nil
function M.inc_gvisual(group_name)
    return _cmd_sequence("increment", "gvisual", group_name)
end

---@param group_name? string|fun():string
---@return fun():nil
function M.dec_gvisual(group_name)
    return _cmd_sequence("decrement", "gvisual", group_name)
end

return M
