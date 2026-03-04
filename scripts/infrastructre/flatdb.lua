-- https://github.com/uleelx/FlatDB
-- FlatDB v2.2 - Refactored for robust loading
-- Minimalist NoSQL Engine using JSON for storage

local flatdb = {}
local db_pool = setmetatable({}, {__mode = "v"})
local path_pool = setmetatable({}, {__mode = "k"})
local db_methods = {}

-- Get JSON from the shared modules table
local json = DBTest.modules.json
local json_decode, json_encode

if json then
    json_decode, json_encode = json.decode, json.encode
    print("DBTest: FlatDB linked to JSON engine")
else
    -- Fallback: try to source it again if missing
    print("DBTest FlatDB: JSON missing, attempting emergency reload...")
    source(g_currentModDirectory .. "scripts/utils/json.lua")
    json = DBTest.modules.json
    if json then
        json_decode, json_encode = json.decode, json.encode
    else
        print("DBTest Error: JSON engine could NOT be loaded even after emergency reload!")
    end
end

-- =============================================================================
-- Filesystem Utilities
-- =============================================================================

local function is_file(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function store_page(path, page)
    if not json_encode then return false end
    local ok, json_string = pcall(json_encode, page)
    if not ok then return false end

    -- FS25 Sandbox: Only 'w' and 'r' modes are allowed, binary 'b' flag is restricted
    local f = io.open(path, "w")
    if not f then return false end
    f:write(json_string)
    f:close()
    return true
end

local function load_page(path)
    if not json_decode then return nil end
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    if content == "" then return {} end
    local ok, page_data = pcall(json_decode, content)
    return ok and page_data or nil
end

db_methods.save = function(db, page_name)
    local db_path = path_pool[db]
    if not db_path then return false end
    if page_name then
        if type(page_name) == "string" and type(db[page_name]) == "table" then
            return store_page(db_path .. "/" .. page_name, db[page_name])
        else
            return false
        end
    end
    for name, page_data in pairs(db) do
        if type(page_data) == "table" then
            store_page(db_path .. "/" .. name, page_data)
        end
    end
    return true
end

local db_metatable = {
    __index = function(db, key)
        if db_methods[key] then return db_methods[key] end
        local db_path = path_pool[db]
        local page_path = db_path .. "/" .. key
        if is_file(page_path) then
            local page_data = load_page(page_path)
            if page_data then
                rawset(db, key, page_data)
                return page_data
            end
        end
        return nil
    end
}

setmetatable(flatdb, {
    __call = function(_, path)
        if db_pool[path] then return db_pool[path] end
        local db = {}
        setmetatable(db, db_metatable)
        db_pool[path] = db
        path_pool[db] = path
        return db
    end
})

-- Register ourselves
if DBTest and DBTest.modules then
    DBTest.modules.flatdb = flatdb
end

return flatdb
