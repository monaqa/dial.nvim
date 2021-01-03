-- utils
local function dbg(obj, text)
    if text ~= nil then
        print("[" .. text .. "]: " .. vim.inspect(obj))
    else
        print(vim.inspect(obj))
    end
end

local function filter(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) then
            table.insert(a, ary[i])
        end
    end
    return a
end

local function filter_map(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) ~= nil then
            table.insert(a, fn(ary[i]))
        end
    end
    return a
end

local function filter_map_zip(fn, ary)
    local a = {}
    for i = 1, #ary do
        if fn(ary[i]) ~= nil then
            table.insert(a, {ary[i], fn(ary[i])})
        end
    end
    return a
end

return {
    dbg = dbg,
    filter_map = filter_map,
    filter_map_zip = filter_map_zip,
}
