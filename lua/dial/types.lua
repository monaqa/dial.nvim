--sumneko lua の type annotation のうち、複数ファイルにまたがるものをここで定義する。

---@alias direction '"increment"' | '"decrement"'
---@alias mode '"normal"' | '"visual"' | '"gvisual"'
---@alias textrange {from: integer, to: integer}
---@alias addresult {text?: string, cursor?: integer}

---@alias findf fun(line: string, cursor?: integer) -> textrange?
---@alias addf fun(text: string, addend: integer, cursor?: integer) -> addresult?

---@alias findmethod fun(self: Augend, line: string, cursor?: integer) -> textrange?
---@alias addmethod fun(self: Augend, text: string, addend: integer, cursor?: integer) -> addresult?

---@class Augend
---@field find findmethod
---@field find_stateful? findmethod
---@field add addmethod
