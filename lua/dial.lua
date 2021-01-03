local util = require("./util")
local augend = require("./augend")
local number = require("./augend/number")

local M = { }

M.augend = {
    number = number
}

M.available_augends = {
    number.hex_number,
    number.decimal_integer,
}

-- インクリメントする。
function M.increment(addend)

    -- 現在のカーソル位置、カーソルのある行、加数の取得
    local curpos = vim.call('getcurpos')
    local cursor = curpos[3]
    local line = vim.fn.getline('.')
    if addend == nil then
        addend = 1
    end

    -- 数字の検索、加算後のテキストの作成
    local idxlst = util.filter_map_zip(function(aug) return aug.find(cursor, line) end, M.available_augends)
    -- TODO: 最優先の span を取ってこれるようにする
    -- TODO: sort っていうか min でよくね？
    --     table.sort(idxlst, comp_with_corsor(cursor))
    -- ひとまず今は一番手前のやつをとる
    local elem = idxlst[1]
    if elem == nil then
        return
    else
        local aug = elem[1]
        local span = elem[2]
        local s, e = get_range(span)
        local rel_cursor = cursor - s + 1
        local text = string.sub(line, s, e)
        local newcol, text = aug.add(rel_cursor, text, addend)
        local newline = string.sub(line, 1, s - 1) .. text .. string.sub(line, e + 1)
        newcol = newcol + s - 1

        -- 行編集、カーソル位置のアップデート
        vim.fn.setline('.', newline)
        vim.fn.setpos('.', {curpos[1], curpos[2], newcol, curpos[4], curpos[5]})
    end
end

return M
