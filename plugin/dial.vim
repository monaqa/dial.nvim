if exists('g:loaded_dial') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
nnoremap <silent><expr> <Plug>(dial-increment) '<Cmd>lua require"dial".cmd.increment_normal(' .. v:count1 .. ')<CR>'
nnoremap <silent><expr> <Plug>(dial-decrement) '<Cmd>lua require"dial".cmd.increment_normal(' .. -v:count1 .. ')<CR>'

vnoremap <silent><expr> <Plug>(dial-increment) ':<C-u>lua require"dial".cmd.increment_visual(' .. v:count1  .. ')<CR>gv'
vnoremap <silent><expr> <Plug>(dial-decrement) ':<C-u>lua require"dial".cmd.increment_visual(' .. -v:count1 .. ')<CR>gv'

vnoremap <silent><expr> <Plug>(dial-increment-additional) ':<C-u>lua require"dial".cmd.increment_visual(' .. v:count1  .. ', nil, true)<CR>gv'
vnoremap <silent><expr> <Plug>(dial-decrement-additional) ':<C-u>lua require"dial".cmd.increment_visual(' .. -v:count1 .. ', nil, true)<CR>gv'

command! DialShowSearchList lua require"dial".cmd.print_searchlist()

command! -range -nargs=1 -complete=customlist,DialShowAugends DialIncrement lua require"dial".cmd.increment_range(1, {from = <line1>, to = <line2>}, {<f-args>})
command! -range -nargs=1 -complete=customlist,DialShowAugends DialDecrement lua require"dial".cmd.increment_range(-1, {from = <line1>, to = <line2>}, {<f-args>})

" TOOD: move into autoload?
function! DialShowAugends(lead, line, pos)
  let cands = luaeval('vim.tbl_keys(require"dial".augends)')
  let regex = '^' .. a:lead
  call filter(cands, 'v:val =~# regex')
  return cands
endfunction

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_dial = 1
