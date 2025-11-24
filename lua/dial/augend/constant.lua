local util = require "dial.util"
local common = require "dial.augend.common"

---@alias AugendConstantConfig { elements: string[], cyclic: boolean, pattern_regexp: string, preserve_case: boolean, match_before_cursor: boolean }

---@class AugendConstant
---@implement Augend
---@field config AugendConstantConfig
local AugendConstant = {}

local M = {}

---@param word string
---@return string
local function to_first_upper(word)
    local first_letter = word:sub(1, 1)
    local rest = word:sub(2)
    return first_letter:upper() .. rest:lower()
end

---@param word string
---@return "all-lower" | "all-upper" | "first-upper" | nil
local function preserve_case(word)
    if word:lower() == word then
        return "all-lower"
    end
    if word:upper() == word then
        return "all-upper"
    end
    if to_first_upper(word) == word then
        return "first-upper"
    end
    return nil
end

---@param config { elements: string[], word?: boolean, cyclic?: boolean, pattern_regexp?: string, preserve_case?: boolean, match_before_cursor?: boolean }
---@return Augend
function M.new(config)
    util.validate_list("config.elements", config.elements, "string")

    vim.validate("word", config.word, "boolean", true)
    vim.validate("cyclic", config.cyclic, "boolean", true)
    vim.validate("pattern_regexp", config.pattern_regexp, "string", true)
    vim.validate("preserve_case", config.preserve_case, "boolean", true)
    vim.validate("match_before_cursor", config.match_before_cursor, "boolean", true)

    if config.preserve_case == nil then
        config.preserve_case = false
    end
    if config.match_before_cursor == nil then
        config.match_before_cursor = false
    end
    if config.pattern_regexp == nil then
        local case_sensitive_flag = util.if_expr(config.preserve_case, [[\c]], [[\C]])
        local word = util.unwrap_or(config.word, true)
        if word then
            config.pattern_regexp = case_sensitive_flag .. [[\V\<\(%s\)\>]]
        else
            config.pattern_regexp = case_sensitive_flag .. [[\V\(%s\)]]
        end
    end
    if config.cyclic == nil then
        config.cyclic = true
    end
    return setmetatable({ config = config }, { __index = AugendConstant })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendConstant:find(line, cursor)
    local escaped_elements = vim.tbl_map(function(e)
        return vim.fn.escape(e, [[/\]])
    end, self.config.elements)
    local vim_regex_ptn = self.config.pattern_regexp:format(table.concat(escaped_elements, [[\|]]))
    return common.find_pattern_regex(vim_regex_ptn, self.config.match_before_cursor)(line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendConstant:add(text, addend, cursor)
    local elements = self.config.elements
    local n_patterns = #elements
    local n = 1

    local query
    if self.config.preserve_case then
        query = function(elem)
            return text:lower() == elem:lower()
        end
    else
        query = function(elem)
            return text == elem
        end
    end

    for i, elem in ipairs(elements) do
        if query(elem) then
            n = i
        end
    end
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
    local new_text = elements[n]

    local case = nil
    if self.config.preserve_case then
        case = preserve_case(text)
    end
    if case == "all-lower" then
        text = new_text:lower()
    elseif case == "all-upper" then
        text = new_text:upper()
    elseif case == "first-upper" then
        text = to_first_upper(new_text)
    else
        text = new_text
    end

    cursor = #text
    return { text = text, cursor = cursor }
end

M.alias = {
    bool = M.new { elements = { "true", "false" } },
    Bool = M.new { elements = { "True", "False" } },
    alpha = M.new {
        elements = {
            "a",
            "b",
            "c",
            "d",
            "e",
            "f",
            "g",
            "h",
            "i",
            "j",
            "k",
            "l",
            "m",
            "n",
            "o",
            "p",
            "q",
            "r",
            "s",
            "t",
            "u",
            "v",
            "w",
            "x",
            "y",
            "z",
        },
        cyclic = false,
    },
    Alpha = M.new {
        elements = {
            "A",
            "B",
            "C",
            "D",
            "E",
            "F",
            "G",
            "H",
            "I",
            "J",
            "K",
            "L",
            "M",
            "N",
            "O",
            "P",
            "Q",
            "R",
            "S",
            "T",
            "U",
            "V",
            "W",
            "X",
            "Y",
            "Z",
        },
        cyclic = false,
    },
    ja_weekday = M.new {
        elements = { "日", "月", "火", "水", "木", "金", "土" },
        word = true,
        cyclic = true,
    },
    ja_weekday_full = M.new {
        elements = { "日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日" },
        word = false,
        cyclic = true,
    },
    de_weekday = M.new {
        elements = { "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So" },
        word = true,
        cyclic = true,
    },
    de_weekday_full = M.new {
        elements = {
            "Montag",
            "Dienstag",
            "Mittwoch",
            "Donnerstag",
            "Freitag",
            "Samstag",
            "Sonntag",
        },
        word = true,
        cyclic = true,
    },
    en_weekday = M.new {
        elements = { "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun" },
        word = true,
        cyclic = true,
    },
    en_weekday_full = M.new {
        elements = {
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thursday",
            "Friday",
            "Saturday",
            "Sunday",
        },
        word = true,
        cyclic = true,
    },
}

return M
