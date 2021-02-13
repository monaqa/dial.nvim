local util = require("dial/util")
local default = require("dial/default")
local augends = require("dial/augends")

local M = {}

-- 完全一致を条件としたインクリメント。
local function get_incremented_text_fullmatch(cursor, text, addend, search_augends)
    -- signature
    vim.validate{
        -- カーソル位置（行頭にある文字が1）。
        cursor = {cursor, "number"},
        -- 行の内容。
        text = {text, "string"},
        -- 加数。
        addend = {addend, "number"},
        -- 対象とする被加数の種類のリスト (optional)。
        search_augends = {search_augends, "table", true},
    }
    util.validate_list("search_augends", search_augends, util.has_augend_field, "is augend")

    local augendlst = util.filter_map(
        function(aug)
            span = aug.find(cursor, text)
            -- 完全一致以外は認めない
            if span == nil or span.from ~= 1 or span.to ~= #text then
                return nil
            end
            return {augend = aug, from = span.from, to = span.to}
        end,
        search_augends
    )

    -- 優先順位が最も高い augend を選択
    local elem = M.pickup_augend(augendlst, cursor)
    if elem == nil then
        return
    end

    -- 加算後のテキストの作成
    local aug = elem.augend
    local s = elem.from
    local e = elem.to
    local rel_cursor = cursor - s + 1
    local subtext = string.sub(text, s, e)
    local rel_cursor, subtext = aug.add(rel_cursor, subtext, addend)
    local text = string.sub(text, 1, s - 1) .. subtext .. string.sub(text, e + 1)
    cursor = rel_cursor + s - 1

    return cursor, text
end

local function get_incremented_text(cursor, text, addend, search_augends)
    -- signature
    vim.validate{
        -- カーソル位置（行頭にある文字が1）。
        cursor = {cursor, "number"},
        -- 行の内容。
        text = {text, "string"},
        -- 加数。
        addend = {addend, "number"},
        -- 対象とする被加数の種類のリスト (optional)。
        search_augends = {search_augends, "table", true},
    }
    util.validate_list("search_augends", search_augends, util.has_augend_field, "is augend")

    local augendlst = util.filter_map(
        function(aug)
            span = aug.find(cursor, text)
            if span == nil then
                return nil
            end
            return {augend = aug, from = span.from, to = span.to}
        end,
        search_augends
    )

    -- 優先順位が最も高い augend を選択
    local elem = M.pickup_augend(augendlst, cursor)
    if elem == nil then
        return
    end

    -- 加算後のテキストの作成
    local aug = elem.augend
    local s = elem.from
    local e = elem.to
    local rel_cursor = cursor - s + 1
    local subtext = string.sub(text, s, e)
    local rel_cursor, subtext = aug.add(rel_cursor, subtext, addend)
    local text = string.sub(text, 1, s - 1) .. subtext .. string.sub(text, e + 1)
    cursor = rel_cursor + s - 1

    return cursor, text
end

function M.increment_normal(addend, override_searchlist)
    -- signature
    vim.validate{
        -- 加数。
        addend = {addend, "number"},
        -- 対象とする被加数の種類のリスト (optional)。
        override_searchlist = {override_searchlist, "table", true},
    }
    if override_searchlist ~= nil then
        util.validate_list("override searchlist", override_searchlist, "string")
    end

    -- 対象の searchlist 文字列に対応する augends のリストを取得
    if override_searchlist then
        searchlist = override_searchlist
    else
        searchlist = default.searchlist.normal
    end
    local search_augends = assert(util.try_get_keys(augends, searchlist))

    -- 現在のカーソル位置、行内容を取得
    local curpos = vim.call('getcurpos')
    local cursor = curpos[3]
    local line = vim.fn.getline('.')

    -- 更新後の行内容、新たなカーソル位置を取得
    cursor, line = get_incremented_text(cursor, line, addend, search_augends)

    -- 対象行の内容及びカーソル位置を更新
    if line ~= nil then
        vim.fn.setline('.', line)
    end
    if cursor ~=nil then
        vim.fn.setpos('.', {curpos[1], curpos[2], cursor, curpos[4], curpos[5]})
    end

end

-- Increment/Decrement function in visual (not visual-line or visual-block) mode.
-- This edits the current buffer.
local function increment_visual_normal(addend, override_searchlist)
    -- searchlist 取得
    if override_searchlist then
        searchlist = override_searchlist
    else
        searchlist = default.searchlist.visual
    end
    local search_augends = assert(util.try_get_keys(augends, searchlist))

    -- 選択範囲の取得
    local pos_s = vim.fn.getpos("'<")
    local pos_e = vim.fn.getpos("'>")
    if pos_s[2] ~= pos_e[2] then
        -- 行が違う場合はパターンに合致しない
        return
    end
    local line = vim.fn.getline(pos_s[2])
    -- TODO: マルチバイト文字への対応
    local col_s = pos_s[3]
    local col_e = pos_e[3]
    if col_e < col_s then
        col_s, col_e = col_e, col_s
    end
    local text = line:sub(col_s, col_e)

    local _, text = get_incremented_text_fullmatch(1, text, addend, search_augends)

    -- 対象行の内容及びカーソル位置を更新
    if text ~= nil then
        local line = string.sub(line, 1, col_s - 1) .. text .. string.sub(line, col_e + 1)
        vim.fn.setline('.', line)
        vim.fn.setpos("'<", {pos_s[1], pos_s[2], pos_s[3], pos_s[4]})
        vim.fn.setpos("'>", {pos_s[1], pos_s[2], pos_s[3] + #text - 1, pos_s[4]})
    end
end

local function increment_visual_block(addend, override_searchlist, is_additional)

    if override_searchlist then
        searchlist = override_searchlist
    else
        searchlist = default.searchlist.visual
    end
    local search_augends = assert(util.try_get_keys(augends, searchlist))

    -- 選択範囲の取得
    local pos_s = vim.fn.getpos("'<")
    local pos_e = vim.fn.getpos("'>")
    local row_s, row_e, col_s, col_e
    if pos_s[2] < pos_e[2] then
        row_s = pos_s[2]
        row_e = pos_e[2]
    else
        row_s = pos_e[2]
        row_e = pos_s[2]
    end
    if pos_s[3] < pos_e[3] then
        col_s = pos_s[3]
        col_e = pos_e[3]
    else
        col_s = pos_e[3]
        col_e = pos_s[3]
    end

    if addend == nil then
        addend = 1
    end

    local cursor = col_s

    for row=row_s,row_e do
        local line = vim.fn.getline(row)
        local text = line:sub(col_s, col_e)

        if is_additional then
            actual_addend = addend * (row - row_s + 1)
        else
            actual_addend = addend
        end

        local _, text = get_incremented_text(1, text, actual_addend, search_augends)
        local line = string.sub(line, 1, col_s - 1) .. text .. string.sub(line, col_e + 1)

        -- 行編集、カーソル位置のアップデート
        vim.fn.setline(row, line)
    end
end


function M.increment_visual(addend, override_searchlist, is_additional)
    vim.validate{
        -- 加数。
        addend = {addend, "number"},
        -- 対象とする被加数の種類のリスト (optional)。
        override_searchlist = {override_searchlist, "table", true},
        -- 複数行に渡るインクリメントの場合、加数を
        -- 1行目は1、2行目は2、3行目は3、…と増やしていくかどうか。
        -- default は false。
        is_additional = {is_additional, "boolean", true},
    }
    if override_searchlist ~= nil then
        util.validate_list("override searchlist", override_searchlist, "string")
    end

    -- 対象の searchlist 文字列に対応する augends のリストを取得
    if override_searchlist then
        searchlist = override_searchlist
    else
        searchlist = default.searchlist.visual
    end
    local search_augends = assert(util.try_get_keys(augends, searchlist))

    -- VISUAL mode の種類により場合分け
    local mode = vim.fn.visualmode()
    if mode == "v" then
        increment_visual_normal(addend, override_searchlist)
    elseif mode == "V" then
        -- 選択範囲の取得
        local row_s = vim.fn.line("'<")
        local row_e = vim.fn.line("'>")
        M.increment_range(addend, {from = row_s, to = row_e}, override_searchlist, is_additional)
    elseif mode == "" then
        increment_visual_block(addend, override_searchlist, is_additional)
    end

end

function M.increment_range(addend, range, override_searchlist, is_additional)
    -- signature
    vim.validate{
        -- 加数。
        addend = {addend, "number"},
        -- テキストの範囲を表すテーブル。
        -- {from = m, to = n } で "m行目からn行目まで（両端含む）" を表す。
        range = {range, "table"},
        ["range.from"] = {range.from, "number"},
        ["range.to"] = {range.to, "number"},
        -- 対象とする被加数の種類のリスト (optional)。
        override_searchlist = {override_searchlist, "table", true},
    }
    if override_searchlist ~= nil then
        util.validate_list("override searchlist", override_searchlist, "string")
    end

    -- 対象の searchlist 文字列に対応する augends のリストを取得
    if override_searchlist then
        searchlist = override_searchlist
    else
        searchlist = default.searchlist.normal
    end
    local search_augends = assert(util.try_get_keys(augends, searchlist))

    for row=range.from,range.to do
        local f = function()
            -- 対象となる行の内容を取得
            local line = vim.fn.getline(row)
            if line == "" then
                return  -- continue
            end

            -- addend の計算
            if is_additional then
                actual_addend = addend * (row - range.from + 1)
            else
                actual_addend = addend
            end

            -- 更新後のそれぞれの行内容を取得
            local _, line = get_incremented_text(1, line, actual_addend, search_augends)

            -- 対象行の内容を更新
            if line ~= nil then
                vim.fn.setline(row, line)
            end
        end
        f()
    end
end


-- cursor 入力が与えられたとき、
-- 自らのスパンが cursor に対してどのような並びになっているか出力する。
-- span が cursor を含んでいるときは0、
-- span が cursor より前方にあるときは 1、
-- span が cursor より後方にあるときは 2 を出力する。
-- この数字は採用する際の優先順位に相当する。
local function status(span, cursor)
    -- type check
    vim.validate{
        span = {span, "table"},
        ["span.from"] = {span.from, "number"},
        ["span.to"] = {span.to, "number"},
        cursor = {cursor, "number"},
    }

    local s, e = span.from, span.to
    if cursor < s then
        return 1
    elseif cursor > e then
        return 2
    else
        return 0
    end
end

-- 現在の cursor 位置をもとに、
-- span: {augend: augend, from: int, to:int} を要素に持つ配列 lst から
-- 適切な augend を一つ取り出す。
function M.pickup_augend(lst, cursor)
    -- type check
    vim.validate{
        lst = {lst, "table"},
        cursor = {cursor, "number"},
    }

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
    vim.validate{
        ["span.from"] = {span.from, "number"},
        ["span.to"] = {span.to, "number"},
    }

    for _, s in ipairs(lst) do
        vim.validate{
            ["s.from"] = {s.from, "number"},
            ["s.to"] = {s.to, "number"},
        }
        if comp(s, span) then
            span = s
        end
    end
    return span
end

local function get_augend_info_line(name, augend, max_name_len)
    local normal_mark, visual_mark
    if vim.tbl_contains(default.searchlist.normal, name) then
        normal_mark = 'o'
    else
        normal_mark = ' '
    end
    if vim.tbl_contains(default.searchlist.visual, name) then
        visual_mark = 'o'
    else
        visual_mark = ' '
    end

    local name_length = vim.fn.strdisplaywidth(name)
    local name_with_padding = name .. (" "):rep(max_name_len - name_length)

    return ("| %s | %s | %s | %s"):format(name_with_padding, normal_mark, visual_mark, augend.desc)
end

-- searchlist のキー名とその説明を表示する。
function M.show_searchlist_info()
    local augend_name_header = "Augend name"
    local augend_names = vim.tbl_keys(augends)
    local name_lengths = vim.tbl_map(
        function(name)
            return vim.fn.strdisplaywidth(name)
        end,
        augend_names
        )

    local max_name_len = vim.fn.max(name_lengths)
    if max_name_len < augend_name_header:len() then
        max_name_len = augend_name_header:len()
    end

    print(("| %-" .. max_name_len .. "s | n | v | desc"):format(augend_name_header))
    print(("-"):rep(100))  -- 適当
    table.sort(augend_names)
    for _, name in ipairs(augend_names) do
        print(get_augend_info_line(name, augends[name], max_name_len))
    end
end

return M
