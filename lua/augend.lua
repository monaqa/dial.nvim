-- Augend

-- augend 型は以下のような構造になっている。
-- {
--     -- 行を受け取り、カーソル以降にあるパターンを探す。あればその範囲を返す。
--     find : Fn(cursor: int, line: str) -> {from: int, to: int}
--     -- パターン文字列を受け取り、加算して返す。 cursor 位置に変更がないときは cursor に nil を返す。
--     add : Fn(cursor: int, text: str, addend: int) -> cursor: int, text: str
-- }

-- find field を簡単に実装する。
function find_pattern(ptn)
    function f(cursor, line)
        local idx_start = 1
        while idx_start < #line do
            local s, e = string.find(line, ptn, idx_start)
            if s then
                -- 検索結果があったら
                if (cursor <= e) then
                    -- cursor が終了文字より後ろにあったら終了
                    text = string.sub(line, s, e)
                    return {from = s, to = e}
                else
                    -- 終了文字の後ろから探し始める
                    idx_start = e + 1
                end
            else
                -- 検索結果がなければそこで終了
                break
            end
        end
        return nil
    end
    return f
end

return {
    find_pattern = find_pattern,
}
