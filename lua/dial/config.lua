local augend = require("dial.augend")
local util   = require("dial.util")
local M = {}

---@class augends
---@field group table<string, Augend[]>
M.augends = {
    group = {
        default = {
            augend.integer.alias.decimal,
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
            error(("tried to register augend group '%s', but it contains nil augend at index %s."):format(name, str_nil_keys))
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
