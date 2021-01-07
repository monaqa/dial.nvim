local util = require("./util")

local M = {}

-- augend の find field を簡単に実装する。
function M.find_pattern(ptn)
    function f(cursor, line)
        local idx_start = 1
        while idx_start <= #line do
            local s, e = line:find(ptn, idx_start)
            if s then
                -- 検索結果があったら
                if (cursor <= e) then
                    -- cursor が終了文字より後ろにあったら終了
                    text = line:sub(s, e)
                    return {from = s, to = e}
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

function M.enum_sequence(name, ptnlst, ptn_format)
    if ptn_format == nil then
        ptn_format = "\\C\\M\\<\\(%s\\)\\>"
    end
    local vim_regex_ptn = string.format(ptn_format, table.concat(ptnlst, "\\|"))

    local function find(cursor, line)
        local idx_start = 1
        match = vim.fn.matchstrpos(line, vim_regex_ptn, cursor - 1)
        if match[2] == -1 then
            return nil
        end
        return {from = match[2] + 1, to = match[3]}
    end

    local function add(cursor, text, addend)
        n_ptnlst = #ptnlst
        n = 1
        for i, ptn in pairs(ptnlst) do
            if text:find(ptn) ~= nil then
                n = i
            end
        end
        n = (n + addend - 1) % n_ptnlst + 1
        text = ptnlst[n]
        cursor = #text
        return cursor, text
    end

    return {
        name = name,
        desc = vim_regex_ptn,
        find = find,
        add = add,
    }
end

function M.enum_cyclic(name, ptnlst, ptn_format)
    if ptn_format == nil then
        ptn_format = "\\C\\M\\<\\(%s\\)\\>"
    end
    local vim_regex_ptn = string.format(ptn_format, table.concat(ptnlst, "\\|"))

    local function find(cursor, line)
        local idx_start = 1
        match = vim.fn.matchstrpos(line, vim_regex_ptn, cursor - 1)
        if match[2] == -1 then
            return nil
        end
        return {from = match[2] + 1, to = match[3]}
    end

    local function add(cursor, text, addend)
        n_ptnlst = #ptnlst
        n = 1
        for i, ptn in pairs(ptnlst) do
            if text:find(ptn) ~= nil then
                n = i
            end
        end
        n = (n + addend - 1) % n_ptnlst + 1
        text = ptnlst[n]
        cursor = #text
        return cursor, text
    end

    return {
        name = name,
        desc = vim_regex_ptn,
        find = find,
        add = add,
    }
end

return M
