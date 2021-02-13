-- デフォルトの設定値をまとめたもの。

local augends = require("dial/augends")

local M = {}

M.searchlist = {}

M.searchlist.normal = {
    "number#decimal",
    "number#hex",
    "number#binary",
    "date#[%Y/%m/%d]",
    "date#[%m/%d]",
    "date#[%Y-%m-%d]",
    "date#[%H:%M]",
    "date#[%jA]",
    "color#hex",
}

M.searchlist.visual = {
    "number#decimal",
    "number#hex",
    "number#binary",
    "date#[%Y/%m/%d]",
    "date#[%m/%d]",
    "date#[%Y-%m-%d]",
    "date#[%H:%M]",
    "color#hex",
    "char#alph#small#word",
    "char#alph#capital#word",
}

return M
