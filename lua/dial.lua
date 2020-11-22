-- utils
local function dbg(obj, text)
    if text ~= nil then
        print("[" .. text .. "]: " .. vim.inspect(obj))
    else
        print(vim.inspect(obj))
    end
end

local function filter_map(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) ~= nil then
            table.insert(a, fn(ary[i]))
        end
    end
    return a
end

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

-- 十進数表示された整数を表すクラスのようなもの。
-- Augend の一種。
local DecimalInteger = {}
setmetatable(DecimalInteger, {__index = Augend})

function DecimalInteger.new(text)
    return setmetatable({
            kind = "number.decimal",
            n = tonumber(text),
            text = text
        }, {__index = DecimalInteger})
end

function DecimalInteger.pattern()
    return "-?%d+"
end

function DecimalInteger:add(cursor, addend)
    -- 現在の cursor （相対位置）と加数 addend を受け取り、
    -- 足した後の text と新たな cursor 位置を返す。
    self.n = self.n + addend
    self.text = tostring(self.n)
    newcursor = #self.text
    return self.text, newcursor
end

-- 十進数表示された非負整数を表すクラスのようなもの。
-- Augend の一種。
local DecimalNaturalNumber = {}
setmetatable(DecimalNaturalNumber, {__index = Augend})

function DecimalNaturalNumber.new(text)
    return setmetatable({
            kind = "number.decimal",
            n = tonumber(text),
            text = text
        }, {__index = DecimalNaturalNumber})
end

function DecimalNaturalNumber.pattern()
    return "%d+"
end

function DecimalNaturalNumber:add(cursor, addend)
    -- 現在の cursor （相対位置）と加数 addend を受け取り、
    -- 足した後の text と新たな cursor 位置を返す。
    self.n = self.n + addend
    if self.n < 0 then
        self.n = 0
    end
    self.text = tostring(self.n)
    newcursor = #self.text
    return self.text, newcursor
end

-- 十六進数表示された数を表すクラスのようなもの。
-- Augend の一種。
local HexNumber = {}
setmetatable(HexNumber, {__index = Augend})

function HexNumber.new(text)
    return setmetatable({
            kind = "number.hex",
            n = tonumber(text, 16),
            text = text
        }, {__index = HexNumber})
end

function HexNumber.pattern()
    return "0x[0-9a-fA-F]+"
end

function HexNumber:add(cursor, addend)
    self.n = self.n + addend
    self.text = "0x" .. string.format("%x", self.n)
    newcursor = #self.text
    return self.text, newcursor
end

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
    local augends = {DecimalInteger, HexNumber}
    local idxlst = filter_map(function(x) return Augend.match(x, line, cursor) end, augends)
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
