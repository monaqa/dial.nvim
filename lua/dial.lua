local util = require("./util")
local Span = require("./augend").Span
local Augend = require("./augend").Augend
local number = require("./augend/number")
local augends = {
    number.DecimalInteger, number.DecimalNaturalNumber, number.HexNumber
}

-- インクリメントする。
local function increment(addend)

    -- 現在のカーソル位置、カーソルのある行の取得
    local curpos = vim.call('getcurpos')
    local cursor = curpos[3]
    local line = vim.fn.getline('.')

    -- 数字の検索、加算後のテキストの作成
    if addend == nil then
        local addend = 1
    end
    local idxlst = util.filter_map(function(x) return Augend.match(x, line, cursor) end, augends)
    -- TODO: sort っていうか min でよくね？
    table.sort(idxlst, Span.comp_with_corsor(cursor))
    -- 最優先の span を取ってくる
    local span = idxlst[1]
    if span == nil then
        return
    else
        local s, e = span:get_range()
        local rel_cursor = cursor - s + 1
        local text, newcol = span.augend:add(rel_cursor, addend)
        local newline = string.sub(line, 1, s - 1) .. text .. string.sub(line, e + 1)
        newcol = newcol + s - 1

        -- 行編集、カーソル位置のアップデート
        vim.fn.setline('.', newline)
        vim.fn.setpos('.', {curpos[1], curpos[2], newcol, curpos[4], curpos[5]})
    end
end

return {
    increment = increment
}
