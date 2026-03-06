-- ConsoleInterface - Registers developer console commands for DBAPI
-- Commands: dbSet, dbGet, dbDelete, dbList, dbHelp

local ConsoleInterface = {}
local isRegistered = false

local adapter = nil
local setValue = nil
local getValue = nil
local deleteValue = nil
local listKeys = nil
local jsonModule = nil

--- Formats a value for console display.
--- @param value any
--- @return string
local function formatValue(value)
    if value == nil then return "nil" end
    if type(value) == "table" then
        if jsonModule then
            local ok, str = pcall(jsonModule.encode, value)
            if ok then return str end
        end
        return "{table}"
    end
    return tostring(value)
end

--- Console handler: dbSet <namespace> <key> <value>
function ConsoleInterface:onSet(namespace, key, value)
    if not namespace or not key or value == nil then
        print("Usage: dbSet <namespace> <key> <value>")
        return
    end

    local ok, err = setValue(adapter, namespace, key, value)
    if ok then
        print(string.format("DBAPI: [%s] %s = %s", namespace, key, formatValue(value)))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbGet <namespace> <key>
function ConsoleInterface:onGet(namespace, key)
    if not namespace or not key then
        print("Usage: dbGet <namespace> <key>")
        return
    end

    local value, err = getValue(adapter, namespace, key)
    if err then
        print(string.format("DBAPI Error: %s", tostring(err)))
    else
        print(string.format("DBAPI: [%s] %s = %s", namespace, key, formatValue(value)))
    end
end

--- Console handler: dbDelete <namespace> <key>
function ConsoleInterface:onDelete(namespace, key)
    if not namespace or not key then
        print("Usage: dbDelete <namespace> <key>")
        return
    end

    local ok, err = deleteValue(adapter, namespace, key)
    if ok then
        print(string.format("DBAPI: [%s] Deleted key '%s'", namespace, key))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbList <namespace>
function ConsoleInterface:onList(namespace)
    if not namespace then
        print("Usage: dbList <namespace>")
        return
    end

    local keys, err = listKeys(adapter, namespace)
    if err then
        print(string.format("DBAPI Error: %s", tostring(err)))
        return
    end

    if #keys == 0 then
        print(string.format("DBAPI: [%s] No keys found", namespace))
        return
    end

    print(string.format("DBAPI: [%s] %d key(s):", namespace, #keys))
    for _, k in ipairs(keys) do
        local val = getValue(adapter, namespace, k)
        print(string.format("  %s = %s", k, formatValue(val)))
    end
end

--- Console handler: dbHelp
function ConsoleInterface:onHelp()
    print("--- DBAPI Console Commands ---")
    print("  dbSet <namespace> <key> <value>   Store a value")
    print("  dbGet <namespace> <key>            Retrieve a value")
    print("  dbDelete <namespace> <key>         Delete a key")
    print("  dbList <namespace>                 List all keys in namespace")
    print("  dbHelp                             Show this help")
    print("-------------------------------")
end

--- Registers all console commands with the FS25 engine.
--- @param deps table {adapter, setValue, getValue, deleteValue, listKeys, json}
function ConsoleInterface.register(deps)
    if isRegistered then return end

    adapter = deps.adapter
    setValue = deps.setValue
    getValue = deps.getValue
    deleteValue = deps.deleteValue
    listKeys = deps.listKeys
    jsonModule = deps.json

    if addConsoleCommand == nil then
        print("DBAPI Error: addConsoleCommand not available")
        return
    end

    addConsoleCommand("dbSet", "Store a value: dbSet <namespace> <key> <value>", "onSet", ConsoleInterface)
    addConsoleCommand("dbGet", "Get a value: dbGet <namespace> <key>", "onGet", ConsoleInterface)
    addConsoleCommand("dbDelete", "Delete a key: dbDelete <namespace> <key>", "onDelete", ConsoleInterface)
    addConsoleCommand("dbList", "List keys: dbList <namespace>", "onList", ConsoleInterface)
    addConsoleCommand("dbHelp", "Show DBAPI help", "onHelp", ConsoleInterface)

    isRegistered = true
    print("DBAPI: Console commands registered (dbSet, dbGet, dbDelete, dbList, dbHelp)")
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = ConsoleInterface end
return ConsoleInterface
