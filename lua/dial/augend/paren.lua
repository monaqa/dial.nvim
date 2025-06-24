local util = require "dial.util"
local common = require "dial.augend.common"

---@class AugendParen
---@implement Augend
---@field config { patterns: string[][], escape_char?: string, cyclic: boolean, nested: boolean }
---@field find_pattern string
local AugendParen = {}

local M = {}

---text の i 文字目から先が ptn から始まっていたら true を、そうでなければ false を返す。
---@param text string
---@param ptn string
---@param idx integer
---@return boolean
local function precedes(text, ptn, idx)
    return text:sub(idx, idx + #ptn - 1) == ptn
end

---括弧のペアを見つける。
---@param line string
---@param open string
---@param close string
---@param nested boolean
---@param cursor_idx integer
---@param escape_char? string
---@return textrange?
local function find_nested_paren(line, open, close, nested, cursor_idx, escape_char)
    local depth_at_cursor = nil
    local start_idx_stack = {}
    local escaped = false

    -- idx: 探索している場所
    local idx = 1
    while idx <= #line do
        -- util.dbg{
        --     idx = idx,
        --     depth_at_cursor = depth_at_cursor,
        --     start_idx_stack = start_idx_stack,
        --     escaped = escaped,
        -- }

        -- idx が cursor_idx を超えた瞬間に depth_at_cursor を記録
        if depth_at_cursor == nil and idx >= cursor_idx then
            -- util.dbg"cursor detected!"
            depth_at_cursor = #start_idx_stack
        end

        -- idx を増やしつつ走査。
        -- 括弧の open, close または escape char に当たったら特別処理を入れる。
        -- open と close が同じパターン列の場合は close を優先。
        local from, to = (function()
            -- escape 文字: escaped のトグルを行う
            if escape_char ~= nil and precedes(line, escape_char, idx) then
                -- util.dbg"escape char detected!"
                idx = idx + #escape_char
                escaped = not escaped
                return nil
            end

            -- close 文字: 括弧の終了
            if #start_idx_stack >= 1 and precedes(line, close, idx) then
                -- 括弧が閉じきっていないときに close が見つかったら stack を pop
                -- util.dbg"close char detected!"
                idx = idx + #close
                local close_end_idx = idx - 1

                -- idx が cursor_idx を超えた瞬間に depth_at_cursor を記録
                if depth_at_cursor == nil and close_end_idx >= cursor_idx then
                    -- util.dbg"cursor detected!"
                    depth_at_cursor = #start_idx_stack
                end
                if escaped then
                    escaped = false
                    return nil
                end
                escaped = false
                local start_idx = table.remove(start_idx_stack, #start_idx_stack)

                -- カーソル下の深さの括弧を抜けたらその時点で探索終了
                if depth_at_cursor ~= nil and #start_idx_stack <= depth_at_cursor then
                    return start_idx, idx - 1
                end
                return nil
            end

            -- open 文字: 括弧の開始
            if precedes(line, open, idx) then
                -- util.dbg"open char detected!"
                idx = idx + #open
                if escaped then
                    escaped = false
                    return nil
                end
                escaped = false

                if nested or #start_idx_stack == 0 then
                    table.insert(start_idx_stack, idx - #open)
                end
                return nil
            end
            escaped = false
            idx = idx + 1
        end)()

        -- range が見つかった場合は速やかに本関数から return する
        if from ~= nil then
            return { from = from, to = to }
        end
    end

    -- nest がすべて解決しなかったので nil を返す
    return nil
end

---@param config { patterns?: string[][], escape_char?: string, cyclic?: boolean, nested?: boolean }
---@return Augend
function M.new(config)
    if config.patterns == nil then
        config.patterns = { { [[']], [[']] }, { [["]], [["]] } }
    end
    if config.nested == nil then
        config.nested = true
    end
    if config.cyclic == nil then
        config.cyclic = true
    end
    vim.validate("cyclic", config.cyclic, "boolean")

    util.validate_list("patterns", config.patterns, "table")

    return setmetatable({ config = config }, { __index = AugendParen })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendParen:find(line, cursor)
    ---@type textrange?
    local tmp_range = nil
    if cursor == nil then
        cursor = 1
    end

    for _, ptn in ipairs(self.config.patterns) do
        local open = ptn[1]
        local close = ptn[2]
        local range = find_nested_paren(line, open, close, self.config.nested, cursor, self.config.escape_char)
        if range ~= nil then
            if tmp_range == nil then
                tmp_range = range
            else
                local rel = range.from > cursor
                local tmp_rel = tmp_range.from > cursor
                if tmp_rel and rel then
                    tmp_range = util.if_expr(tmp_range.from < range.from, tmp_range, range)
                elseif tmp_rel and not rel then
                    tmp_range = range
                elseif not tmp_rel and rel then
                else
                    tmp_range = util.if_expr(tmp_range.from > range.from, tmp_range, range)
                end
            end
        end
    end

    return tmp_range
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendParen:add(text, addend, cursor)
    local n_patterns = #self.config.patterns
    local n = 1
    for i, elem in ipairs(self.config.patterns) do
        local open = elem[1]
        if precedes(text, open, 1) then
            n = i
            break
        end
    end
    local old_paren_pair = self.config.patterns[n]
    -- util.dbg{old_paren_pair = old_paren_pair, text = text}
    local text_inner = text:sub(#old_paren_pair[1] + 1, #text - #old_paren_pair[2])

    if self.config.cyclic then
        n = (n + addend - 1) % n_patterns + 1
    else
        n = n + addend
        if n < 1 then
            n = 1
        end
        if n > n_patterns then
            n = n_patterns
        end
    end
    local new_paren_pair = self.config.patterns[n]
    local new_paren_open = new_paren_pair[1]
    local new_paren_close = new_paren_pair[2]

    text = new_paren_open .. text_inner .. new_paren_close
    cursor = #text
    return { text = text, cursor = cursor }
end

M.alias = {
    quote = M.new {
        patterns = { { "'", "'" }, { '"', '"' } },
        nested = false,
        escape_char = [[\]],
        cyclic = true,
    },
    brackets = M.new {
        patterns = { { "(", ")" }, { "[", "]" }, { "{", "}" } },
        nested = true,
        cyclic = true,
    },
    lua_str_literal = M.new {
        patterns = {
            { "'", "'" },
            { '"', '"' },
            { "[[", "]]" },
            { "[=[", "]=]" },
            { "[==[", "]==]" },
            { "[===[", "]===]" },
        },
        nested = false,
        cyclic = false,
    },
    rust_str_literal = M.new {
        patterns = {
            { '"', '"' },
            { 'r#"', '"#' },
            { 'r##"', '"##' },
            { 'r###"', '"###' },
        },
        nested = false,
        cyclic = false,
    },
}

return M
