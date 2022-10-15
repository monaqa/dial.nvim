local util = require "dial.util"
local common = require "dial.augend.common"
local user = require "dial.augend.user"

local M = {}

M.alias = {}

M.alias.markdown_header = user.new {
    ---@param line string
    ---@param cursor? integer
    ---@return textrange?
    find = function(line, cursor)
        local header_mark_s, header_mark_e = line:find "^#+"
        if header_mark_s == nil or header_mark_e >= 7 then
            return nil
        end
        return { from = header_mark_s, to = header_mark_e }
    end,

    ---@param text string
    ---@param addend integer
    ---@param cursor? integer
    ---@return { text?: string, cursor?: integer }
    add = function(text, addend, cursor)
        local n = #text
        n = n + addend
        if n < 1 then
            n = 1
        end
        if n > 6 then
            n = 6
        end
        text = ("#"):rep(n)
        cursor = 1
        return { text = text, cursor = cursor }
    end,
}

return M
