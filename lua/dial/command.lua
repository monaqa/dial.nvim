---Neovim とのインターフェースを司る。
---Neovim のバッファの中身を弄ったり、変数を読み込んだりする。
local handler = require("dial.handle").new()
local util = require("dial.util")

local M = {}

---alias を展開する関数。
---TODO: 実装
---@param augend Augend | string
---@return Augend
function M.expand_augend(augend)
    return augend
end

local function is_augend(obj)
    vim.validate{
        find = {obj.find, "function"},
        add = {obj.add, "function"}
    }
end

---comment
---@return Augend[]
local function choose_default_augends()
    -- local buflocal_augends = vim.b.dial_augends
    -- if buflocal_augends ~= nil then
    --     util.validate_list("b:dial_augends", buflocal_augends, is_augend, "require augend list.")
    --     return buflocal_augends
    -- end
    -- 
    -- local global_augends = vim.g.dial_augends
    -- if global_augends ~= nil then
    --     util.validate_list("g:dial_augends", global_augends, is_augend, "require augend list.")
    --     return buflocal_augends
    -- end
    return require("dial.config").augends
end

---comment
---@param count integer
---@param augends? Augend[]
function M.select_augend_normal(count, augends)
    augends = augends or choose_default_augends()

    if count ~= 0 then
        handler:set_count(count)
    else
        handler:set_count(1)
    end
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    handler:select_augend(line, col, augends)
end

---operator が呼ばれたときに走る処理。
---@param direction direction
function M.operator_normal(direction)
    local col = vim.fn.col(".")
    local line_num = vim.fn.line(".")
    local line = vim.fn.getline(".")

    local result = handler:operate(line, col, direction)

    if result.line ~= nil then
        vim.fn.setline(".", result.line)
    end
    if result.cursor ~= nil then
        vim.fn.cursor({line_num, result.cursor})
    end
end

--- text object が指定されたときに走る処理。
--- 現在の行の情報を元に範囲を選択する handler.findTextRange() を呼び出す。
--- また、ドットリピートの際は指定されたカウンタの値を受け取って加数を更新する。
---@param count integer
function M.textobj(count)
    if count ~= 0 then
        handler:set_count(count)
    end
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")

    handler:find_text_range(line, col)
end

return M
