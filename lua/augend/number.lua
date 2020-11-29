local Augend = require("../augend").Augend
local Span = require("../augend").Span

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

return {
    DecimalInteger = DecimalInteger,
    DecimalNaturalNumber = DecimalNaturalNumber,
    HexNumber = HexNumber,
}
