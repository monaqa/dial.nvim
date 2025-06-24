local common = require "dial.augend.common"
local util = require "dial.util"

local M = {}

---@alias casetype '"PascalCase"' | '"camelCase"' | '"snake_case"' | '"kebab-case"' | '"SCREAMING_SNAKE_CASE"'
---@alias extractf fun(word: string) -> string[] | nil
---@alias constractf fun(terms: string[]) -> string
---@alias casepattern { word_regex: string, extract: extractf, constract: constractf }

---@class AugendCase
---@implement Augend
---@field config { types: casetype[], cyclic: boolean }
---@field patterns casepattern[]
local AugendCase = {}

---@type table<casetype, casepattern>
M.case_patterns = {}

M.case_patterns["camelCase"] = {
    word_regex = [[\C\v<([a-z][a-z0-9]*)([A-Z][a-z0-9]*)+>]],

    ---@param word string
    ---@return string[] | nil
    extract = function(word)
        local subwords = {}
        local ptr = 1
        for i = 1, word:len(), 1 do
            local char = word:sub(i, i)
            if not (char == char:lower()) then
                -- i 番目の文字が大文字の場合は直前で切る
                -- 小文字や数字などは切らない
                if i == 1 then
                    -- ただし最初の文字が大文字になることはないはず
                    return nil
                end
                table.insert(subwords, word:sub(ptr, i - 1))
                ptr = i
            end
        end
        table.insert(subwords, word:sub(ptr, word:len()))
        return vim.tbl_map(function(s)
            return s:lower()
        end, subwords)
    end,

    ---@param terms string[]
    ---@return string
    constract = function(terms)
        local result = ""
        for index, term in ipairs(terms) do
            if index == 1 then
                result = result .. term
            else
                result = result .. term:sub(1, 1):upper() .. term:sub(2)
            end
        end

        return result
    end,
}

M.case_patterns["PascalCase"] = {
    word_regex = [[\C\v<([A-Z][a-z0-9]*)+>]],

    ---@param word string
    ---@return string[] | nil
    extract = function(word)
        local subwords = {}
        local ptr = 1
        for i = 2, word:len(), 1 do
            local char = word:sub(i, i)
            if not (char == char:lower()) then
                -- i 番目の文字が大文字の場合は直前で切る
                -- 小文字や数字などは切らない
                table.insert(subwords, word:sub(ptr, i - 1))
                ptr = i
            end
        end
        table.insert(subwords, word:sub(ptr, word:len()))
        return vim.tbl_map(function(s)
            return s:lower()
        end, subwords)
    end,

    ---@param terms string[]
    ---@return string
    constract = function(terms)
        local result = ""
        for _, term in ipairs(terms) do
            result = result .. term:sub(1, 1):upper() .. term:sub(2)
        end

        return result
    end,
}

M.case_patterns["snake_case"] = {
    word_regex = [[\C\v<([a-z][a-z0-9]*)(_[a-z0-9]*)+>]],

    ---@param word string
    ---@return string[] | nil
    extract = function(word)
        local subwords = {}
        local ptr = 1
        for i = 1, word:len(), 1 do
            local char = word:sub(i, i)
            if char == "_" then
                table.insert(subwords, word:sub(ptr, i - 1))
                ptr = i + 1
            end
        end
        table.insert(subwords, word:sub(ptr, word:len()))
        return subwords
    end,

    ---@param terms string[]
    ---@return string
    constract = function(terms)
        return table.concat(terms, "_")
    end,
}

M.case_patterns["kebab-case"] = {
    word_regex = [[\C\v<([a-z][a-z0-9]*)(-[a-z0-9]*)+>]],

    ---@param word string
    ---@return string[] | nil
    extract = function(word)
        local subwords = {}
        local ptr = 1
        for i = 1, word:len(), 1 do
            local char = word:sub(i, i)
            if char == "-" then
                table.insert(subwords, word:sub(ptr, i - 1))
                ptr = i + 1
            end
        end
        table.insert(subwords, word:sub(ptr, word:len()))
        return subwords
    end,

    ---@param terms string[]
    ---@return string
    constract = function(terms)
        return table.concat(terms, "-")
    end,
}

M.case_patterns["SCREAMING_SNAKE_CASE"] = {
    word_regex = [[\C\v<([A-Z][A-Z0-9]*)(_[A-Z0-9]*)+>]],

    ---@param word string
    ---@return string[] | nil
    extract = function(word)
        local subwords = {}
        local ptr = 1
        for i = 1, word:len(), 1 do
            local char = word:sub(i, i)
            if char == "_" then
                table.insert(subwords, word:sub(ptr, i - 1))
                ptr = i + 1
            end
        end
        table.insert(subwords, word:sub(ptr, word:len()))
        return vim.tbl_map(function(s)
            return s:lower()
        end, subwords)
    end,

    ---@param terms string[]
    ---@return string
    constract = function(terms)
        return table.concat(terms, "_"):upper()
    end,
}

---@param config { types: casetype[], cyclic?: boolean }
---@return Augend
function M.new(config)
    vim.validate("cyclic", config.cyclic, "boolean", true)

    if config.cyclic == nil then
        config.cyclic = true
    end
    util.validate_list("types", config.types, function(val)
        if
            val == "PascalCase"
            or val == "camelCase"
            or val == "snake_case"
            or val == "kebab-case"
            or val == "SCREAMING_SNAKE_CASE"
        then
            return true
        end
        return false
    end)
    local patterns = vim.tbl_map(function(type)
        return M.case_patterns[type]
    end, config.types)

    -- local query = prefix .. util.if_expr(natural, "", "-?") .. "[" .. radix_to_query_character(radix) .. delimiter .. "]+"
    return setmetatable({
        patterns = patterns,
        config = config,
    }, { __index = AugendCase })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendCase:find(line, cursor)
    ---@type textrange?
    local most_front_range = nil

    for _, caseptn in ipairs(self.patterns) do
        ---@type textrange
        local range = common.find_pattern_regex(caseptn.word_regex)(line, cursor)
        if range ~= nil then
            if most_front_range == nil or range.from < most_front_range.from then
                most_front_range = range
            end
        end
    end
    return most_front_range
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendCase:add(text, addend, cursor)
    local len_patterns = #self.patterns
    ---@type integer
    local index
    for i, caseptn in ipairs(self.patterns) do
        local range = common.find_pattern_regex(caseptn.word_regex)(text, 1)
        if range ~= nil then
            index = i
            break
        end
    end

    local terms = self.patterns[index].extract(text)

    local new_index
    if self.config.cyclic then
        new_index = (len_patterns + (index - 1 + addend) % len_patterns) % len_patterns + 1
    else
        new_index = index + addend
        if new_index <= 0 then
            new_index = 1
        end
        if new_index > len_patterns then
            new_index = len_patterns
        end
    end
    if new_index == index then
        return { cursor = text:len() }
    end
    text = self.patterns[new_index].constract(terms)
    return { text = text, cursor = text:len() }
end

return M
