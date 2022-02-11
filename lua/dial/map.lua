local M = {}

local command = require"dial.command"

---入力文字列を <Cmd> 及び <CR> で挟む。
---@param body string
local function cmd(body)
    local cmd_sequences = string.char(128, 253, 104)
    return cmd_sequences .. body .. "\n"
end

---dial 操作を提供するコマンド列を出力する。
---@param direction direction
---@param mode mode
---@param augends? Augend[]
local function _cmd_sequence(direction, mode, augends)
    -- local select = cmd([[lua require"dial.command".select_augend_]] .. mode .. "()")
    command.select_augend_normal(vim.v.count, augends)
    local setopfunc = cmd([[let &opfunc="dial#operator#]] .. direction .. "_" .. mode .. [["]])
    local textobj = cmd[[lua require("dial.command").textobj(vim.v.count)]]
    return setopfunc .. "g@" .. textobj
end

---@param augends? Augend[]
---@return string
function M.inc_normal(augends)
    return _cmd_sequence("increment", "normal", augends)
end

---@param augends? Augend[]
---@return string
function M.dec_normal(augends)
    return _cmd_sequence("decrement", "normal", augends)
end

return M
