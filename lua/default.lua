-- デフォルトの設定値をまとめたもの。

local augends = require("./augends")

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
    "date#[%jA]",
    "color#hex",
    "char#alph#small",
    "char#alph#capital",
}

return M
