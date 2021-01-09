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

-- Signature assertion
--
-- Example(w/o type check):
-- ```
-- function f(a, b, c)
--     -- Dummy function with 3 augments,
--     -- whose types are "number", "string", "Option<string>", respectively.
--     if c ~= nil then
--         print(c)
--     end
--     print("%d, %s", a, b)
-- end
-- ```
--
-- Example(w/ type check):
-- ```
-- function f(...)
--     a, b, c = assert(util.check_args({...}, {"number", "string", "string/nil"}))
--     if c ~= nil then
--         print(c)
--     end
--     print("%d, %s", a, b)
-- end
-- ```
function M.check_args(args, typelist)
    if #args > #typelist then
        errormsg = ("The number of arguments is excessive. Expect: %d, Actual: %d"):format(#typelist, #args)
        return nil, errormsg
    end
    for idx, value in ipairs(typelist) do
        list_type_expect = M.Set(M.split(value, "/"))
        type_actual = type(args[idx])
        if not list_type_expect[type_actual] then
            -- 期待する型名リストの中に実際の args[idx] の型が無ければエラー
            errormsg = ("The type of %d-th argument should be %s, but actual type was %s."):format(
                idx, value, type_actual)
            return nil, errormsg
        end
    end
    return unpack(args)
end

-- いわゆる構造体（として扱いたい table）の型チェックを行う。
-- 必要なフィールドに適切な型がついてればひとまずOK。
function M.check_struct(struct, typestruct)
    for key, value in pairs(typestruct) do
        list_type_expect = M.Set(M.split(value, "/"))
        type_actual = type(struct[key])
        if not list_type_expect[type_actual] then
            -- 期待する型名リストの中に実際の args[idx] の型が無ければエラー
            if type_actual == "nil" then
                errormsg = ("The struct does not have field '%s', which is required by check_struct."):format(key)
                return nil, errormsg
            end
            errormsg = ("The type of filed '%s' should be %s, but actual type was %s."):format(
                key, value, type_actual)
            return nil, errormsg
        end
    end
    return struct
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

function M.eval(inStr)
    return assert(load(inStr))()
end

return M
