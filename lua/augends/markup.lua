local common = require("./augends/common")
local util = require("./util")

local M = {}

M.markdown_header = {
    name = "markup.markdown_header",
    desc = "Markdown Header (# Title)",

    find = function(cursor, line)
        header_mark_s, header_mark_e = line:find("^#+")
        if header_mark_s == nil or header_mark_e > 7 then
            return nil
        end
        return {from = header_mark_s, to = header_mark_e}
    end,

    add = function(cursor, text, addend)
        n = #text
        n = n + addend
        if n < 1 then n = 1 end
        if n > 6 then n = 6 end
        text = ("#"):rep(n)
        cursor = 1
        return cursor, text
    end

}

return M
