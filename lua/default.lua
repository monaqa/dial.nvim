-- デフォルトの設定値をまとめたもの。

local augends = require("./augends")

local M = {}

M.searchlist = {}

M.searchlist.normal = {
    "number#decimal",
    "number#hex",
}

M.searchlist.visual = {
    "number#decimal",
    "number#hex",
}

return M
