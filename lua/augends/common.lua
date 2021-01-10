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

-- augend の find field を簡単に実装する。
function M.find_pattern_regex(ptn)
    function f(cursor, line)
        local idx_start = 1
        while idx_start <= #line do

            local s, e = vim.regex(ptn):match_str(line:sub(idx_start))

            if s then

                s = s + idx_start      -- 上で得られた s は相対位置なので
                e = e + idx_start - 1  -- 上で得られた s は相対位置なので

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

function M.enum_sequence(tbl)
    vim.validate{
        name = {tbl.name, "string"},
        strlist = {tbl.strlist, "table"},
        desc = {tbl.desc, "string", true},
        ptn_format = {tbl.ptn_format, "string", true},
    }
    local name, desc, strlist, ptn_format = tbl.name, tbl.desc, tbl.strlist, tbl.ptn_format

    -- option 引数
    if ptn_format == nil then
        ptn_format = "\\C\\M\\<\\(%s\\)\\>"
    end
    local vim_regex_ptn = ptn_format:format(table.concat(strlist, "\\|"))

    if desc == nil then
        desc = vim_regex_ptn
    end

    find = M.find_pattern_regex(vim_regex_ptn)

    local function add(cursor, text, addend)
        n_ptnlst = #strlist
        n = 1
        for i, ptn in pairs(strlist) do
            if text:find(ptn) ~= nil then
                n = i
            end
        end
        n = n + addend
        if n < 1 then n = 1 end
        if n > n_ptnlst then n = n_ptnlst end
        text = strlist[n]
        cursor = #text
        return cursor, text
    end

    return {
        name = name,
        desc = desc,
        find = find,
        add = add,
    }
end

function M.enum_cyclic(tbl)
    vim.validate{
        name = {tbl.name, "string"},
        strlist = {tbl.strlist, "table"},
        desc = {tbl.desc, "string", true},
        ptn_format = {tbl.ptn_format, "string", true},
    }
    util.validate_list(("strlist of %s"):format(tbl.name), tbl.strlist, "string", false)
    local name, desc, strlist, ptn_format = tbl.name, tbl.desc, tbl.strlist, tbl.ptn_format

    -- option 引数
    if ptn_format == nil then
        ptn_format = "\\C\\M\\<\\(%s\\)\\>"
    end
    local vim_regex_ptn = ptn_format:format(table.concat(strlist, "\\|"))

    if desc == nil then
        desc = vim_regex_ptn
    end

    find = M.find_pattern_regex(vim_regex_ptn)

    local function add(cursor, text, addend)
        n_ptnlst = #strlist
        n = 1
        for i, ptn in pairs(strlist) do
            if text:find(ptn) ~= nil then
                n = i
            end
        end
        n = (n + addend - 1) % n_ptnlst + 1
        text = strlist[n]
        cursor = #text
        return cursor, text
    end

    return {
        name = name,
        desc = desc,
        find = find,
        add = add,
    }
end

return M
