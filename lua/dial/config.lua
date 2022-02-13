local augend = require("dial.augend")
local M = {}

---@class augends
---@field group table<string, Augend[]>
M.augends = {
    group = {
        default = {
            augend.integer{},
        },
    },
}

---新しいグループを登録する。
---@param tbl table<string, Augend[]>
function M.augends:register_group(tbl)
    -- TODO: validate augends
    for name, augends in pairs(tbl) do
        -- if self.group[name] == nil then
        --     self.group[name] = augends
        -- else
        --     error(([[group "%s" already exists.]]):format(name))
        -- end

        self.group[name] = augends
    end
end

---グループを取得する。
---@param group_name string
function M.augends:get(group_name)
    return self.group[group_name]
end

return M
