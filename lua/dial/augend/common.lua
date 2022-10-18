-- augend で共通して用いられる関数。

local util = require "dial.util"

local M = {}

---augend の find field を簡単に実装する。
---@param ptn string
---@return findf
function M.find_pattern(ptn)
    ---@param line string
    ---@param cursor? integer
    ---@return textrange?
    local function f(line, cursor)
        local idx_start = 1
        while idx_start <= #line do
            local s, e = line:find(ptn, idx_start)
            if s then
                -- 検索結果があったら
                if cursor == nil or cursor <= e then
                    -- cursor が終了文字より後ろにあったら終了
                    return { from = s, to = e }
                else
                    -- 終了文字の後ろから探し始める
                    idx_start = e + 1
                end
            else
                -- 検索結果がなければそこで終了
                break
            end
        end
        return nil
    end
    return f
end

-- augend の find field を簡単に実装する。
---@param ptn string
---@return findf
function M.find_pattern_regex(ptn)
    ---@param line string
    ---@param cursor? integer
    ---@return textrange?
    local function f(line, cursor)
        local idx_start = 1
        while idx_start <= #line do
            local s, e = vim.regex(ptn):match_str(line:sub(idx_start))

            if s then
                s = s + idx_start -- 上で得られた s は相対位置なので
                e = e + idx_start - 1 -- 上で得られた s は相対位置なので

                -- 検索結果があったら
                if cursor == nil or cursor <= e then
                    -- cursor が終了文字より後ろにあったら終了
                    return { from = s, to = e }
                else
                    -- 終了文字の後ろから探し始める
                    idx_start = e + 1
                end
            else
                -- 検索結果がなければそこで終了
                break
            end
        end
        return nil
    end
    return f
end

---@param elems string[]
function M.enum_to_regex(elems)
    return table.concat(elems, [[\|]])
end

return M
