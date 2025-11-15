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

M.alias.ordinals = user.new {
    ---@param line string
    ---@param cursor? integer
    ---@return textrange?
    find = function(line, cursor)
        local idx_start = 1

        while idx_start <= #line do
            local mark_start, mark_end = line:find("-?%d+%a%a", idx_start)
            local _, check_end = line:find("-?%d+%a+", idx_start)

            if mark_start then
                if (cursor == nil or cursor <= mark_end) and check_end == mark_end then
                    return { from = mark_start, to = mark_end }
                else
                    idx_start = mark_end + 1
                end
            else
                break
            end
        end

        return nil
    end,
    ---@param text string
    ---@param addend integer
    ---@param cursor? integer
    ---@return { text?: string, cursor?: integer }
    add = function(text, addend, cursor)
        local special_suffix = { "st", "nd", "rd" }

        for ordinal in text:gmatch "-?%d+" do
            local cardinal = ordinal + addend
            local remainder = math.abs(cardinal) % 100

            local suffix = not vim.tbl_contains({ 11, 12, 13 }, remainder) and special_suffix[remainder % 10] or "th"

            text = cardinal .. suffix
        end

        cursor = 1

        return { text = text, cursor = cursor }
    end,
}

return M
