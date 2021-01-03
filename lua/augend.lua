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

function get_range(span)
    return span.from, span.to
end

function status(span, cursor)
    -- cursor 入力が与えられたとき、
    -- 自らのスパンが cursor に対してどのような並びになっているか出力する。
    -- span が cursor を含んでいるときは0、
    -- span が cursor より前方にあるときは 1、
    -- span が cursor より後方にあるときは 2 を出力する。
    -- この数字は採用する際の優先順位に相当する。
    local s, e = get_range(span)
    if cursor < s then
        return 1
    elseif cursor > e then
        return 2
    else
        return 0
    end
end

function comp_with_corsor(cursor)
    -- カーソル位置が与えられた下での範囲の優先順位を定める comp 関数を返す。
    -- ルールは以下。
    -- c が s と e の間にあるものが最優先。
    -- c が s と e の手前にあるものが次。
    -- c が s と e の後ろにあるものは最も低め。
    -- その上で、 s が手前にあるものを優先、
    -- e が後ろにあるものを優先する。
    local function comp(span1, span2)
        if span1:status(cursor) ~= span2:status(cursor) then
            return span1:status(cursor) < span2:status(cursor)
        else
            local s1, e1 = get_range(span1)
            local s2, e2 = get_range(span2)
            if s1 ~= s2 then
                return s1 < s2
            else
                return e1 > e2
            end
        end
    end
    return comp
end

return {
    find_pattern = find_pattern,
    comp_with_corsor = comp_with_corsor,
}
