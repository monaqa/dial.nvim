local M = {}

M.augends = {}

function M.setup(tbl)
    if tbl.augends ~= nil then
        M.augends = tbl.augends
    end
end

return M
