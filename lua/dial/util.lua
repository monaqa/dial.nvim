-- utils
local M = {}

---@generic T
---@param cond boolean
---@param branch_true T
---@param branch_false T
---@return T
function M.if_expr(cond, branch_true, branch_false)
    if cond then
        return branch_true
    end
    return branch_false
end

---@generic T
---@param x T | nil
---@param default T
---@return T
function M.unwrap_or(x, default)
    if x == nil then
        return default
    end
    return x
end

function M.Set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

-- Check if the argument is a valid list (which does not contain nil).
---@param name string
---@param list any[]
---@param arg1 string | function
---@param arg2? string
function M.validate_list(name, list, arg1, arg2)
    if not vim.islist(list) then
        error(("%s is not list."):format(name))
    end

    if type(arg1) == "string" then
        local typename, _ = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            if type(value) ~= typename then
                error(("Type error: %s[%d] should have type %s, got %s"):format(name, idx, typename, type(value)))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in a list."):format(name, count_idx + 1))
        end
    else
        local checkf, errormsg = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            local ok, err = checkf(value)
            if not ok then
                error(("List validation error: %s[%d] does not satisfy '%s' (%s)"):format(name, idx, errormsg, err))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in valid list."):format(name, count_idx + 1))
        end
    end
end

---Returns the indices with the value nil.
---returns an index array
---@param tbl array
---@return integer[]
function M.index_with_nil_value(tbl)
    -- local maxn, k = 0, nil
    -- repeat
    --     k = next( table, k )
    --     if type( k ) == 'number' and k > maxn then
    --         maxn = k
    --     end
    -- until not k
    -- M.dbg(maxn)

    local maxn = table.maxn(tbl)
    local nil_keys = {}
    for i = 1, maxn, 1 do
        if tbl[i] == nil then
            table.insert(nil_keys, i)
        end
    end
    return nil_keys
end

function M.filter(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) then
            table.insert(a, ary[i])
        end
    end
    return a
end

function M.filter_map(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) ~= nil then
            table.insert(a, fn(ary[i]))
        end
    end
    return a
end

function M.filter_map_zip(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) ~= nil then
            table.insert(a, { ary[i], fn(ary[i]) })
        end
    end
    return a
end

function M.tostring_with_base(n, b, wid, pad)
    n = math.floor(n)
    if not b or b == 10 then
        return tostring(n)
    end
    local digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    local t = {}
    if n < 0 then
        -- be positive
        n = -n
    end
    repeat
        local d = (n % b) + 1
        n = math.floor(n / b)
        table.insert(t, 1, digits:sub(d, d))
    until n == 0
    local text = table.concat(t, "")
    if wid then
        if #text < wid then
            if pad == nil then
                pad = " "
            end
            local padding = pad:rep(wid - #text)
            return padding .. text
        end
    end
    return text
end

-- util.try_get_keys({foo = "bar", hoge = "fuga", teka = "pika"}, ["teka", "foo"])
-- -> ["pika", "bar"]
function M.try_get_keys(tbl, keylst)
    if not vim.islist(keylst) then
        return nil, "the 2nd argument is not list."
    end

    local values = {}

    for _, key in ipairs(keylst) do
        local val = tbl[key]
        if val ~= nil then
            table.insert(values, val)
        else
            local errmsg = ("The value corresponding to the key '%s' is not found in the table."):format(key)
            return nil, errmsg
        end
    end

    return values
end

---return the iterator returning UTF-8 based characters
---@param text string
---@return fun(): string | nil
function M.chars(text)
    return text:gmatch "[%z\1-\127\194-\244][\128-\191]*"
end

return M
