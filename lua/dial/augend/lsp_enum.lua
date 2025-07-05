local util = require "dial.util"
local common = require "dial.augend.common"

local lsp = vim.lsp
local ms = vim.lsp.protocol.Methods
local lsp_util = vim.lsp.util

---@alias item_getter fun(symbol_kinds: lsp.SymbolKind[]): lsp.CompletionItem[]
---@alias AugendLspEnumConfig { cyclic: boolean, item_getter: item_getter, symbol_kinds: lsp.SymbolKind[] }

---@class AugendLspEnum
---@implement Augend
---@field config AugendLspEnumConfig
---@field elements string[]
local AugendLspEnum = {}

local M = {}

---@param symbol_kinds lsp.SymbolKind[]
---@return lsp.CompletionItem[]
local function get_lsp_items(symbol_kinds)
    local params = lsp_util.make_position_params(0, "utf-8")
    local results = lsp.buf_request_sync(0, ms.textDocument_completion, params)
    local items = {}
    if results and not vim.tbl_isempty(results) then
        for client_id, obj in pairs(results) do
            local result = obj.result
            if result then
                items = vim.iter(result.items)
                    :filter(function(item)
                        return vim.tbl_contains(symbol_kinds, item.kind)
                    end)
                    :totable()
            end

            if not vim.tbl_isempty(items) then
                break
            end
        end
    end
    return items
end

--- Returns the longest substring that exists under the cursor and matches one of the elements.
--- If there are two substrings with the same number of characters, the one with the first string in front is matched.
---@param elements string[]
---@param line string
---@param cursor integer
local function find_item_on_cursor(elements, line, cursor)
    local result = vim.iter(elements)
        :map(
            ---@param element string
            function(element)
                local init = cursor - #element + 1
                if init <= 0 then
                    init = 1
                end
                local idx = line:find(element, init, true)
                if idx == nil or idx > cursor then
                    return nil
                else
                    return {
                        element = element,
                        idx = idx,
                    }
                end
            end
        )
        :fold(
            nil,
            ---@param acc? {element: string, idx: integer}
            ---@param result? {element: string, idx: integer}
            ---@return {element: string, idx: integer}?
            function(acc, result)
                if acc == nil then
                    return result
                end
                if result == nil then
                    return acc
                end
                if #result.element > #acc.element then
                    return result
                end
                if #result.element < #acc.element then
                    return acc
                end
                if #result.idx < #acc.idx then
                    return result
                end
                return acc
            end
        )
    if result == nil then
        return nil
    end
    return { from = result.idx, to = result.idx + #result.element - 1 }
end

---@param config { cyclic?: boolean, symbol_kinds?: lsp.SymbolKind[] }
---@return Augend
function M.new(config)
    vim.validate {
        cyclic = { config.cyclic, "boolean", true },
    }

    if config.cyclic == nil then
        config.cyclic = true
    end

    if config.symbol_kinds == nil then
        config.symbol_kinds = {
            lsp.protocol.SymbolKind.EnumMember,
            lsp.protocol.SymbolKind.Null,
            lsp.protocol.SymbolKind.Key,
        }
    end
    util.validate_list("config.symbol_kinds", config.symbol_kinds, "number")

    -- used for mocking LSP behavior
    if config.item_getter == nil then
        config.item_getter = get_lsp_items
    end

    return setmetatable({ config = config, elements = {} }, { __index = AugendLspEnum })
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendLspEnum:find(line, cursor)
    if cursor == nil then
        cursor = 1
    end
    return find_item_on_cursor(self.elements, line, cursor)
end

---@param line string
---@param cursor? integer
---@return textrange?
function AugendLspEnum:find_stateful(line, cursor)
    if cursor == nil then
        cursor = 1
    end

    local items = self.config.item_getter(self.config.symbol_kinds)
    if #items == 0 then
        return
    end
    self.elements = vim.iter(items)
        :map(
            ---@param item lsp.CompletionItem
            function(item)
                return item.label
            end
        )
        :totable()

    return find_item_on_cursor(self.elements, line, cursor)
end

---@param text string
---@param addend integer
---@param cursor? integer
---@return { text?: string, cursor?: integer }
function AugendLspEnum:add(text, addend, cursor)
    local elements = self.elements
    local n_patterns = #elements
    local n = 1

    for i, elem in ipairs(elements) do
        if elem == text then
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
    text = elements[n]

    return { text = text }
end

return M
