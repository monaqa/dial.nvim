local util = require("./util")

local M = {}

M.augends = {
    common = require("./augends/common"),
    number = require("./augends/number"),
    color = require("./augends/color"),
    date = require("./augends/date"),
    char = require("./augends/char"),
}

-- default の augends 候補。
M.searchlist = {
    M.augends.number.hex,
    M.augends.number.decimal,
}

local function status(span, cursor)
    -- cursor 入力が与えられたとき、
    -- 自らのスパンが cursor に対してどのような並びになっているか出力する。
    -- span が cursor を含んでいるときは0、
    -- span が cursor より前方にあるときは 1、
    -- span が cursor より後方にあるときは 2 を出力する。
    -- この数字は採用する際の優先順位に相当する。
    local s, e = span.from, span.to
    if cursor < s then
        return 1
    elseif cursor > e then
        return 2
    else
        return 0
    end
end

function M.pickup_augend(lst, cursor)
    -- 現在の cursor 位置をもとに、
    -- span: {augend: augend, from: int, to:int} を要素に持つ配列 lst から
    -- 適切な augend を一つ取り出す。
    local function comp(span1, span2)
        -- span1 の優先順位が span2 よりも高いかどうか。
        -- まずは status（カーソルとspanの位置関係）に従って優先順位を決定する。
        -- 両者の status が等しいときは、開始位置がより手前にあるものを選択する。
        -- 開始位置も等しいときは、終了位置がより奥にあるものを選択する。
        if status(span1, cursor) ~= status(span2, cursor) then
            return status(span1, cursor) < status(span2, cursor)
        else
            local s1, e1 = span1.from, span1.to
            local s2, e2 = span2.from, span2.to
            if s1 ~= s2 then
                return s1 < s2
            else
                return e1 > e2
            end
        end
    end

    local span = lst[1]
    if span == nil then
        return nil
    end

    for _, s in pairs(lst) do
        if comp(s, span) then
            span = s
        end
    end
    return span
end

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
    local auglst = util.filter_map(
        function(aug)
            span = aug.find(cursor, line)
            if span == nil then
                return nil
            end
            return {augend = aug, from = span.from, to = span.to}
        end,
        M.searchlist
    )
    -- TODO: 最優先の span を取ってこれるようにする
    -- TODO: sort っていうか min でよくね？
    --     table.sort(auglst, comp_with_corsor(cursor))
    -- ひとまず今は一番手前のやつをとる
    local elem = M.pickup_augend(auglst, cursor)
    if elem == nil then
        return
    else
        local aug = elem.augend
        local s = elem.from
        local e = elem.to
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

function M.print_searchlist()
    for _, aug in pairs(M.searchlist) do
        print(aug.name, ":", aug.desc)
    end
end

return M
