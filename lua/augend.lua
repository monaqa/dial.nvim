-- Augend
-- 行の一部分の範囲を表すもの。
local Span = {}

function Span:get_range()
    return self.s, self.e
end

function Span:status(cursor)
    -- cursor 入力が与えられたとき、
    -- 自らのスパンが cursor に対してどのような並びになっているか出力する。
    -- span が cursor を含んでいるときは0、
    -- span が cursor より前方にあるときは 1、
    -- span が cursor より後方にあるときは 2 を出力する。
    -- この数字は採用する際の優先順位に相当する。
    local s, e = self:get_range()
    if cursor < s then
        return 1
    elseif cursor > e then
        return 2
    else
        return 0
    end
end

function Span.comp_with_corsor(cursor)
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
            local s1, e1 = span1:get_range()
            local s2, e2 = span2:get_range()
            if s1 ~= s2 then
                return s1 < s2
            else
                return e1 > e2
            end
        end
    end
    return comp
end

function Span.new(s, e, augend)
    return setmetatable({s = s, e = e, augend = augend}, {__index = Span})
end

-- 被加数の性質を一般化した抽象クラスのようなもの。
local Augend = {}

function Augend:match(line, cursor)
    -- 文字列 line の中で、カーソル上またはカーソル後にあるパターンを見つけ、
    -- 条件を満たす最初と最後の文字のidxを返す。
    -- この関数を使うには、 pattern という名前のクラスメソッドを定義しておく必要がある。
    local idx_start = 1
    while idx_start < #line do
        local ptn = self.pattern()
        local s, e = string.find(line, ptn, idx_start)
        if s then
            -- 検索結果があったら
            if (cursor <= e) then
                -- cursor が終了文字より後ろにあったら終了
                text = string.sub(line, s, e)
                return Span.new(s, e, self.new(text))
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

return {
    Span = Span,
    Augend = Augend,
}
