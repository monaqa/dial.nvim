local M = {}

M._augends = {}

M._augends_buflocal = {}

function M.set_default_augends(augends)
    M._augends = augends
end

function M.set_buflocal_augends(augends)
    local bufnr = vim.fn.bufnr("%")
    M._augends_buflocal[bufnr] = augends
end

return M
