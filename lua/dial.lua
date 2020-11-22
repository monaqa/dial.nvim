local function dbg(...)
    print(vim.inspect(...))
end

-- cursor 上にあるか、もしくは cursor の後にある数字を検索する。
local function search_decimal(line, cursor)
    local idx_start = 1
    local s, e
    while idx_start < #line do
        s, e = line:find("-?%d+", idx_start)
        dbg({s, e, line, cursor, idx_start})
        if s then
            -- 検索結果が見つかれば
            if (cursor <= e) then  -- cursor が終了文字より手前にあればそれが答え
                return s, e, string.sub(line, s, e)
            else
                idx_start = e + 1
            end
        else
            -- 検索結果がなければ nil を return
            break
        end
    end
    return nil
end

-- インクリメントする。
local function increment(addend)

    -- 現在のカーソル位置、カーソルのある行の取得
    local curpos = vim.call('getcurpos')
    local col_cursor = curpos[3]
    local line = vim.fn.getline('.')

    -- 数字の検索、加算後のテキストの作成
    local s, e, text = search_decimal(line, col_cursor)
    if s == nil then
        return
    end
    local num = tonumber(text)
    local newnum = num + addend
    local newtext = tostring(newnum)
    local newline = string.sub(line, 1, s - 1) .. newtext .. string.sub(line, e + 1)
    local newcol = s - 1 + #newtext  -- newtext の末尾に持ってくる

    -- 行編集、カーソル位置のアップデート
    vim.fn.setline('.', newline)
    vim.fn.setpos('.', {curpos[1], curpos[2], newcol, curpos[4], curpos[5]})
end

return {
    increment = increment
}
