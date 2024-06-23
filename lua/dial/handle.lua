-- The business logic of dial.nvim.
-- To achieve dot repeating, dial.nvim divides the increment/decrement process
-- into the following three parts:
--
-- 1. Select the rule:
--    determine the augend rule to increment/decrement from the current line and cursor position.
--
-- 2. Select the range:
--    determine the range of strings (text object) on the buffer
--    to be incremented/decremented based on the rule determined above.
--
-- 3. Edit the buffer:
--    actually increment/decrement the string (operator).
--
-- In NORMAL mode <C-a>/<C-x>, 1, 2, and 3 are called.
-- In NORMAL mode dot repeating, only 2 and 3 are called.
--
-- `Handler` class, defined in this module, saves information such as augend rule
-- and text range as a state, and performs the actual increment/decrement operation
-- by calling the augend function.
-- Text on buffers is not manipulated from the handler instance.

---Scores used to determine which rules to operate.
---@class Score
---@field cursor_loc integer
---@field start_pos integer
---@field neg_end_pos integer
local Score = {}

local util = require "dial.util"

---constructor
---@param cursor_loc integer
---@param start_pos integer
---@param neg_end_pos integer
---@return Score
function Score.new(cursor_loc, start_pos, neg_end_pos)
    return setmetatable(
        { cursor_loc = cursor_loc, start_pos = start_pos, neg_end_pos = neg_end_pos },
        { __index = Score }
    )
end

---Calculate the score.
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
    return { cursor_loc = cursor_loc, start_pos = s, neg_end_pos = -e }
end

---Calculate the score from the cursor position and text range.
---@param s integer
---@param e integer
---@param cursor? integer
---@return Score
function Score.from_cursor(s, e, cursor)
    local tbl = calc_score(s, e, cursor)
    return setmetatable(tbl, { __index = Score })
end

---Compare the score.
---If and only if `self` has the higher priority than `rhs`, returns true.
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
---@field cumsum integer
---@field range textrange?
---@field active_augend Augend?
local Handler = {}

function Handler.new()
    return setmetatable({ count = 1, cumsum = 0, range = nil, active_augend = nil }, { __index = Handler })
end

---Get addend value.
---@param direction direction
---@return integer
function Handler:get_addend(direction)
    if direction == "increment" then
        return self.count
    else
        return -self.count
    end
end

---Set count value.
---@param count integer
function Handler:set_count(count)
    self.count = count
end

---Select the most appropriate augend (in NORMAL mode).
---@param line string
---@param cursor? integer
---@param augends Augend[]
function Handler:select_augend(line, cursor, augends)
    -- initialize
    self.cumsum = 0

    local interim_augend = nil
    local interim_score = Score.new(3, 0, 0) -- score with the lowest priority

    for _, augend in ipairs(augends) do
        (function()
            ---@type textrange?
            local range = nil
            if augend.find_stateful == nil then
                range = augend:find(line, cursor)
            else
                range = augend:find_stateful(line, cursor)
            end
            if range == nil then
                return
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

---Select the most appropriate augend (in VISUAL mode).
---@param lines string[]
---@param cursor? integer
---@param augends Augend[]
function Handler:select_augend_visual(lines, cursor, augends)
    -- initialize
    self.cumsum = 0

    local interim_augend = nil
    local interim_score = Score.new(3, 0, 0) -- 最も優先度の低いスコア

    for _, line in ipairs(lines) do
        for _, augend in ipairs(augends) do
            (function()
                ---@type textrange?
                local range = nil
                if augend.find_stateful == nil then
                    range = augend:find(line, cursor)
                else
                    range = augend:find_stateful(line, cursor)
                end
                if range == nil then
                    return -- equivalent to break (of nested for block)
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

---The process that runs when operator is called (in NORMAL mode).
---@param line string
---@param cursor integer
---@param direction direction
---@param additive? boolean
---@return {range?: textrange, text?: string, cursor?: integer}
function Handler:operate(line, cursor, direction, additive)
    if self.range == nil or self.active_augend == nil then
        return {}
    end

    local text = line:sub(self.range.from, self.range.to)
    local addend = self:get_addend(direction)
    local add_result = self.active_augend:add(text, addend * (self.cumsum + 1), cursor)
    local new_cursor = nil

    if add_result.cursor ~= nil then
        new_cursor = self.range.from - 1 + add_result.cursor
    end

    if additive then
        self.cumsum = self.cumsum + 1
    end

    return { range = self.range, text = add_result.text, cursor = new_cursor }
end

---The process that runs when operator is called (in VISUAL mode).
---@param selected_range {from: integer, to?: integer}
---@param direction direction
---@param tier integer
---@return {range?: textrange, text?: string}
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
    return { range = { from = from, to = to }, text = add_result.text }
end

---Set self.range to the target range of the currently active augend (without side effects).
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
