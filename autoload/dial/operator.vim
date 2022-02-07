function dial#operator#increment_normal(type, ...)
  lua require("dial.command").operator_normal("increment")
endfunction

function dial#operator#decrement_normal(type, ...)
  lua require("dial.command").operator_normal("decrement")
endfunction

" function dial#operator#increment_visual(type, ...)
"   call denops#request("dial", "operatorVisual", [a:type, "increment", v:false])
" endfunction
" 
" function dial#operator#decrement_visual(type, ...)
"   call denops#request("dial", "operatorVisual", [a:type, "decrement", v:false])
" endfunction
" 
" function dial#operator#increment_gvisual(type, ...)
"   call denops#request("dial", "operatorVisual", [a:type, "increment", v:true])
" endfunction
" 
" function dial#operator#decrement_gvisual(type, ...)
"   call denops#request("dial", "operatorVisual", [a:type, "decrement", v:true])
" endfunction
