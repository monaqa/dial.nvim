if exists('g:loaded_dial') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
" nnoremap <Plug>(dial-increment) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#increment_normal"<CR>g@<Cmd>lua require"dial".textobj()<CR>
" nnoremap <Plug>(dial-decrement) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#decrement_normal"<CR>g@<Cmd>lua require"dial".textobj()<CR>
" xnoremap <Plug>(dial-increment) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#increment_visual"<CR>g@<Cmd>lua require"dial".textobj()<CR>
" xnoremap <Plug>(dial-decrement) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#decrement_visual"<CR>g@<Cmd>lua require"dial".textobj()<CR>
" xnoremap g<Plug>(dial-increment) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#increment_gvisual"<CR>g@<Cmd>lua require"dial".textobj()<CR>
" xnoremap g<Plug>(dial-decrement) <Cmd>lua require"dial".select()<Cmd>let &opfunc="dial#operator#decrement_gvisual"<CR>g@<Cmd>lua require"dial".textobj()<CR>

" nnoremap <expr> <Plug>(dial-increment) luaeval('require"dial.map".inc_normal()')
" nnoremap <expr> <Plug>(dial-decrement) luaeval('require"dial.map".dec_normal()')

lua << EOF
vim.api.nvim_set_keymap("n", "<Plug>(dial-increment)", require("dial.map").inc_normal(), {noremap = true})
vim.api.nvim_set_keymap("n", "<Plug>(dial-decrement)", require("dial.map").dec_normal(), {noremap = true})
vim.api.nvim_set_keymap("v", "<Plug>(dial-increment)", require("dial.map").inc_visual() .. "gv", {noremap = true})
vim.api.nvim_set_keymap("v", "<Plug>(dial-decrement)", require("dial.map").dec_visual() .. "gv", {noremap = true})
vim.api.nvim_set_keymap("v", "g<Plug>(dial-increment)", require("dial.map").inc_gvisual() .. "gv", {noremap = true})
vim.api.nvim_set_keymap("v", "g<Plug>(dial-decrement)", require("dial.map").dec_gvisual() .. "gv", {noremap = true})
EOF

" xnoremap <expr> <Plug>(dial-increment) luaeval('require"dial.map".inc_visual(vim.g.dial_augends)')
" xnoremap <expr> <Plug>(dial-decrement) luaeval('require"dial.map".dec_visual(vim.g.dial_augends)')
" xnoremap <expr> g<Plug>(dial-increment) luaeval('require"dial".map.inc_gvisual(vim.g.dial_augends)')
" xnoremap <expr> g<Plug>(dial-decrement) luaeval('require"dial".map.dec_gvisual(vim.g.dial_augends)')

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_dial = 1
