if exists('g:loaded_dial') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
nnoremap <expr> <Plug>(dial-increment) '<Cmd>lua require"dial".increment(' .. v:count1 .. ')<CR>'
nnoremap <expr> <Plug>(dial-decrement) '<Cmd>lua require"dial".increment(' .. -v:count1 .. ')<CR>'

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_dial = 1
