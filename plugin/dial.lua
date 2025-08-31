if vim.fn.exists "g:loaded_dial" == 1 then
    return
end

local cpo = vim.o.cpoptions
vim.cmd [[set cpo&vim]]

vim.keymap.set("n", "<Plug>(dial-increment)", require("dial.map").inc_normal())
vim.keymap.set("n", "<Plug>(dial-decrement)", require("dial.map").dec_normal())
vim.keymap.set("n", "<Plug>(dial-g-increment)", require("dial.map").inc_gnormal())
vim.keymap.set("n", "<Plug>(dial-g-decrement)", require("dial.map").dec_gnormal())
vim.keymap.set("v", "<Plug>(dial-increment)", require("dial.map").inc_visual() .. "gv")
vim.keymap.set("v", "<Plug>(dial-decrement)", require("dial.map").dec_visual() .. "gv")
vim.keymap.set("v", "<Plug>(dial-g-increment)", require("dial.map").inc_gvisual() .. "gv")
vim.keymap.set("v", "<Plug>(dial-g-decrement)", require("dial.map").dec_gvisual() .. "gv")

vim.o.cpoptions = cpo
vim.g.loaded_dial = 1
