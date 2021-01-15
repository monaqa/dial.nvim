-- デフォルトの設定値をまとめたもの。

local augends = require("./augends")

local M = {}

M.searchlist = {}

M.searchlist.normal = {
    "number#decimal",
    "number#decimal#hex",
}

M.searchlist.visual = {
    "number#decimal",
    "number#decimal#hex",
}

return M
