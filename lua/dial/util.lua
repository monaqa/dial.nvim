-- utils
local M = {}

function M.dbg(obj, text)
    if text ~= nil then
        print("[" .. text .. "]: " .. vim.inspect(obj))
    else
        print(vim.inspect(obj))
    end
end

function M.Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

function M.split(str, delim)
  local t = {}
  i=1
  for s in str:gmatch("([^" .. delim .. "]+)") do
    t[i] = s
    i = i + 1
  end

  return t
end

-- Check if the argument is a valid list (which does not contain nil).
function M.validate_list(name, list, arg1, arg2)
    if not vim.tbl_islist(list) then
        error(("%s is not list."):format(name))
    end

    if type(arg1) == "string" then
        typename, _ = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            -- 型名が一致しない場合
            if type(value) ~= typename then
                error(("Type error: %s[%d] should have type %s, got %s"):format(
                        name, idx, typename, type(value)
                    ))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in a list."):format(
                    name, count_idx + 1
                ))
        end

    else
        checkf, errormsg = arg1, arg2

        local count_idx = 0
        for idx, value in ipairs(list) do
            count_idx = idx
            ok, err = checkf(value)
            if not ok then
                error(("List validation error: %s[%d] does not satisfy '%s' (%s)"):format(
                        name, idx, errormsg, err
                    ))
            end
        end

        if count_idx ~= #list then
            error(("The %s[%d] is nil. nil is not allowed in valid list."):format(
                    name, count_idx + 1
                ))
        end
    end
end


function M.has_augend_field(tbl)
    if type(tbl) ~= "table" then
        return false, "not table"
    end

    if vim.tbl_islist(tbl) then
        return false, "augend have to be a map, not list"
    end

    if type(tbl.find) ~= "function" then
        return false, "augend should have a method (function field) 'find'"
    end

    if type(tbl.add) ~= "function" then
        return false, "augend should have a method (function field) 'add'"
    end

    if type(tbl.desc) ~= "string" then
        return false, "augend should have a string field 'desc'"
    end

    return true
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
            table.insert(a, {ary[i], fn(ary[i])})
        end
    end
    return a
end

function M.tostring_with_base(n, b, wid, pad)
    n = math.floor(n)
    if not b or b == 10 then return tostring(n) end
    local digits = "0123456789abcdefghijklmnopqrstuvwxyz"
    local t = {}
    if n < 0 then
        -- be positive
        n = -n
    end
    repeat
        local d = (n % b) + 1
        n = math.floor(n / b)
        table.insert(t, 1, digits:sub(d,d))
    until n == 0
    text = table.concat(t,"")
    if wid then
        if #text < wid then
            if pad == nil then
                pad = " "
            end
            padding = pad:rep(wid - #text)
            return padding .. text
        end
    end
    return text
end

-- util.try_get_keys({foo = "bar", hoge = "fuga", teka = "pika"}, ["teka", "foo"])
-- -> ["pika", "bar"]
function M.try_get_keys(tbl, keylst)
    if not vim.tbl_islist(keylst) then
        return nil, "the 2nd argument is not list."
    end

    local values = {}

    for _, key in ipairs(keylst) do
        val = tbl[key]
        if val ~= nil then
            table.insert(values, val)
        else
            errmsg = ("The value corresponding to the key '%s' is not found in the table."):format(key)
            return nil, errmsg
        end
    end

    return values
end

return M
