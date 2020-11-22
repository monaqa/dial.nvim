local function dbg(...)
    print(vim.inspect(...))
end

local function increment(addend)
    -- インクリメントする。
    local bufnum, lnum, col, off, curswant = vim.call('getcurpos')
    local line = vim.fn.getline('.')

    local newline = line .. 'a'
    local newcol = #newline
    vim.fn.setline('.', newline)
    vim.fn.setpos('.', {bufnum, lnum, col, off})
end

return {
    increment = increment
}
