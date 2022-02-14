function dial#operator#increment_normal(type, ...)
  lua require("dial.command").operator_normal("increment")
endfunction

function dial#operator#decrement_normal(type, ...)
  lua require("dial.command").operator_normal("decrement")
endfunction

function dial#operator#increment_visual(type, ...)
  lua require("dial.command").operator_visual("increment", false)
endfunction

function dial#operator#decrement_visual(type, ...)
  lua require("dial.command").operator_visual("decrement", false)
endfunction

function dial#operator#increment_gvisual(type, ...)
  lua require("dial.command").operator_visual("increment", true)
endfunction

function dial#operator#decrement_gvisual(type, ...)
  lua require("dial.command").operator_visual("decrement", true)
endfunction
