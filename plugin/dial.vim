if exists('g:loaded_dial') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

lua << EOF
vim.keymap.set("n", "<Plug>(dial-increment)", require("dial.map").inc_normal())
vim.keymap.set("n", "<Plug>(dial-decrement)", require("dial.map").dec_normal())
vim.keymap.set("n", "g<Plug>(dial-increment)", require("dial.map").inc_gnormal())
vim.keymap.set("n", "g<Plug>(dial-decrement)", require("dial.map").dec_gnormal())
vim.keymap.set("v", "<Plug>(dial-increment)", require("dial.map").inc_visual() .. "gv")
vim.keymap.set("v", "<Plug>(dial-decrement)", require("dial.map").dec_visual() .. "gv")
vim.keymap.set("v", "g<Plug>(dial-increment)", require("dial.map").inc_gvisual() .. "gv")
vim.keymap.set("v", "g<Plug>(dial-decrement)", require("dial.map").dec_gvisual() .. "gv")
EOF

command! -range -nargs=? DialIncrement lua require"dial.command".command("increment", {from = <line1>, to = <line2>}, {<f-args>})
command! -range -nargs=? DialDecrement lua require"dial.command".command("decrement", {from = <line1>, to = <line2>}, {<f-args>})

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_dial = 1
