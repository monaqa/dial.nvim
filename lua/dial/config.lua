local augend = require("dial.augend")
local util   = require("dial.util")
local M = {}

---@class augends
---@field group table<string, Augend[]>
M.augends = {
    group = {
        default = {
            augend.integer.alias.decimal,
            augend.integer.alias.hex,
            augend.date.alias["%Y/%m/%d"],
            augend.date.alias["%Y-%m-%d"],
            augend.date.alias["%m/%d"],
            augend.date.alias["%H:%M"],
            augend.constant.alias.ja_weekday_full,
        },
    },
}

---新しいグループを登録する。
---@param tbl table<string, Augend[]>
function M.augends:register_group(tbl)
    -- TODO: validate augends

    for name, augends in pairs(tbl) do

        local nil_keys = util.index_with_nil_value(augends)

        if #nil_keys ~= 0 then
            local str_nil_keys = table.concat(nil_keys, ", ")
            error(("Failed to register augend group '%s'. it contains nil at index %s."):format(name, str_nil_keys))
        end

        self.group[name] = augends
    end
end

---グループを取得する。
---@param group_name string
function M.augends:get(group_name)
    return self.group[group_name]
end

return M
