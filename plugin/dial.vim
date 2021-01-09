if exists('g:loaded_dial') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
nnoremap <silent><expr> <Plug>(dial-increment) '<Cmd>lua require"dial".increment(' .. v:count1 .. ')<CR>'
nnoremap <silent><expr> <Plug>(dial-decrement) '<Cmd>lua require"dial".increment(' .. -v:count1 .. ')<CR>'

vnoremap <silent><expr> <Plug>(dial-increment) ':<C-u>lua require"dial".increment_visual(' .. v:count1  .. ')<CR>gv'
vnoremap <silent><expr> <Plug>(dial-decrement) ':<C-u>lua require"dial".increment_visual(' .. -v:count1 .. ')<CR>gv'

command! DialShowSearchList lua require"dial".print_searchlist()

command! -range -bang -nargs=+ DialIncrement lua require"dial".increment_command_with_range(1, {<f-args>}, {<line1>, <line2>})

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_dial = 1
