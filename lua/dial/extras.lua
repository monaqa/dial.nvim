local M = {}

-- Private function that takes care of the filetype resolution
function M._resolve_ft()
  local ft = vim.o.filetype
  if require("dial.config").augends.group[ft] then
    return ft
  else
    return "default"
  end
end

M.group_from_ft = [["..require("dial.extras")._resolve_ft().."]]

---@param ... table Tables to be concatenated
function M.concat_lists(...)
  local sink = {}
  for _, l in ipairs{...} do
    vim.list_extend(sink, l)
  end
  return sink
end

return M
