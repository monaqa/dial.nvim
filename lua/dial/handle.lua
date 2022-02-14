-- ドットリピートを実現するため、増減の工程を以下の3つに分割している。
--
-- 1. **ルール選択**:
--    現在行 + カーソル位置の情報を元に、増減すべき augend rule を決定する
--
-- 2. **範囲選択**:
--    上で決まった rule に基づいて、増減するバッファ上の文字列の範囲を決定する
--    （テキストオブジェクト）
--
-- 3. **バッファ操作**: 上で決まった文字列を実際に増減する（オペレータ）
--
-- ノーマルモードの <C-a> や <C-x> では 1, 2, 3 が呼び出される。
-- ドットリピート実施時には 2, 3 のみ呼び出される。
--
-- 本クラスでは上の工程で定まる情報（augend rule やテキストの範囲など）を
-- 状態として保持しておき、実際に augend の関数を呼び出す処理を行う。
--
-- テキスト操作などの副作用はここでは起こさない。

---増減対象のテキストの範囲から、その範囲の優先順位を決めるスコア。
---@class Score
---@field cursor_loc integer
---@field start_pos integer
---@field neg_end_pos integer
local Score = {}

local util = require"dial.util"

---constructor
---@param cursor_loc integer
---@param start_pos integer
---@param neg_end_pos integer
---@return Score
function Score.new(cursor_loc, start_pos, neg_end_pos)
    return setmetatable({cursor_loc = cursor_loc, start_pos = start_pos, neg_end_pos = neg_end_pos}, {__index = Score})
end

---スコアを計算する。
---@param s integer
---@param e integer
---@param cursor? integer
---@return {cursor_loc: integer, start_pos: integer, neg_end_pos: integer}
local function calc_score(s, e, cursor)
    local cursor_loc
    if (cursor or 0) > e then
        cursor_loc = 2
    elseif (cursor or 0) < s then
        cursor_loc = 1
    else
        cursor_loc = 0
    end
    return {cursor_loc = cursor_loc, start_pos = s, neg_end_pos = -e}
end

---カーソルと範囲からスコアを生成する。
---@param s integer
---@param e integer
---@param cursor? integer
---@return Score
function Score.from_cursor(s, e, cursor)
    local tbl = calc_score(s, e, cursor)
    return setmetatable(tbl, {__index = Score})
end

---スコアを比較する。
---@param rhs Score
function Score.cmp(self, rhs)
    if self.cursor_loc < rhs.cursor_loc then
        return true
    end
    if self.cursor_loc > rhs.cursor_loc then
        return false
    end
    if self.start_pos < rhs.start_pos then
        return true
    end
    if self.start_pos > rhs.start_pos then
        return false
    end
    if self.neg_end_pos < rhs.neg_end_pos then
        return true
    end
    if self.neg_end_pos > rhs.neg_end_pos then
        return false
    end
    return false
end

---@class Handler
---@field count integer
---@field range textrange?
---@field active_augend Augend?
local Handler = {}

function Handler.new()
    return setmetatable(
        {count = 1, range = nil, active_augend = nil},
        {__index = Handler}
    )
end

---addend の値を取得する。
---@param direction direction
---@return integer
function Handler:get_addend(direction)
    if direction == "increment" then
        return self.count
    else
        return -self.count
    end
end

---count の値を設定する。
---@param count integer
function Handler:set_count(count)
    self.count = count
end

---comment
---@param line string
---@param cursor? integer
---@param augends Augend[]
function Handler:select_augend(line, cursor, augends)
    local interim_augend = nil;
    local interim_score = Score.new(3, 0, 0)  -- 最も優先度の低いスコア

    for _, augend in ipairs(augends) do
        (function()
            ---@type textrange?
            local range = nil;
            if (augend.find_stateful == nil) then
                range = augend:find(line, cursor)
            else
                range = augend:find_stateful(line, cursor)
            end
            if range == nil then
                return;
            end
            local score = Score.from_cursor(range.from, range.to, cursor)
            if score:cmp(interim_score) then
                interim_augend = augend
                interim_score = score
            end
        end)()
    end
    self.active_augend = interim_augend
end

---comment
---@param lines string[]
---@param cursor? integer
---@param augends Augend[]
function Handler:select_augend_visual(lines, cursor, augends)
    local interim_augend = nil;
    local interim_score = Score.new(3, 0, 0)  -- 最も優先度の低いスコア

    for _, line in ipairs(lines) do
        for _, augend in ipairs(augends) do
            (function()
                ---@type textrange?
                local range = nil;
                if (augend.find_stateful == nil) then
                    range = augend:find(line, cursor)
                else
                    range = augend:find_stateful(line, cursor)
                end
                if range == nil then
                    return;  -- equivalent to break (of nested for block)
                end
                local score = Score.from_cursor(range.from, range.to, cursor)
                if score:cmp(interim_score) then
                    interim_augend = augend
                    interim_score = score
                end
            end)()
        end
        if interim_augend ~= nil then
            self.active_augend = interim_augend
            return
        end
    end

end

---comment
---@param line string
---@param cursor integer
---@param direction direction
---@return {line?: string, cursor?: integer}
function Handler:operate(line, cursor, direction)
    if (self.range == nil or self.active_augend == nil) then
        return {}
    end

    local text = line:sub(self.range.from, self.range.to)
    local addend = self:get_addend(direction)
    local add_result = self.active_augend:add(text, addend, cursor)
    local new_line = nil
    local new_cursor = nil

    if add_result.text ~= nil then
        new_line = line:sub(1, self.range.from - 1) .. add_result.text .. line:sub(self.range.to + 1)
    end
    if add_result.cursor ~= nil then
        new_cursor = self.range.from - 1 + add_result.cursor
    end

    return {line = new_line, cursor = new_cursor}
end

---comment
---@param line string
---@param selected_range {from: integer, to?: integer}
---@param direction direction
---@param tier integer
---@return {result?: string}
function Handler:operate_visual(line, selected_range, direction, tier)
    if self.active_augend == nil then
        return {}
    end
    tier = util.unwrap_or(tier, 1)
    local line_partial = line:sub(selected_range.from, selected_range.to)
    local range = self.active_augend:find(line_partial, 0)
    if range == nil then
        return {}
    end
    local addend = self:get_addend(direction)
    local from = selected_range.from + range.from - 1
    local to = selected_range.from + range.to - 1
    local text = line:sub(from, to)
    local add_result = self.active_augend:add(text, addend * tier)
    local newline = nil
    if add_result.text ~= nil then
        newline = line:sub(1, from - 1) .. add_result.text .. line:sub(to + 1)
    end
    return {line = newline}
end

---text object が call されたとき、（副作用を伴わずに）現在 active な augend の対象範囲を range に設定する。
---@param line any
---@param cursor any
function Handler:find_text_range(line, cursor)
    if self.active_augend == nil then
        self.range = nil
        return
    end
    self.range = self.active_augend:find(line, cursor)
end

return Handler
