-- GlobalAPI - Public API exposed as _G.DBAPI for other mods
-- This is the ONLY file that touches _G.DBAPI.
-- All public methods validate inputs and delegate to use cases.

--- Builds the public API table.
--- @param deps table {adapter, setValue, getValue, deleteValue, listKeys}
--- @return table api The public _G.DBAPI API
local function buildGlobalAPI(deps)
    local api = {}

    --- Stores a value in the database.
    --- @param namespace string Your mod name (e.g. "FS25_MyMod")
    --- @param key string The key to store
    --- @param value any The value (string, number, boolean, or table)
    --- @return boolean success
    --- @return string|nil errorMessage
    function api.setValue(namespace, key, value)
        return deps.setValue(deps.adapter, namespace, key, value)
    end

    --- Retrieves a value from the database.
    --- @param namespace string Your mod name
    --- @param key string The key to retrieve
    --- @return any|nil value
    --- @return string|nil errorMessage
    function api.getValue(namespace, key)
        return deps.getValue(deps.adapter, namespace, key)
    end

    --- Deletes a key from the database.
    --- @param namespace string Your mod name
    --- @param key string The key to delete
    --- @return boolean success
    --- @return string|nil errorMessage
    function api.deleteValue(namespace, key)
        return deps.deleteValue(deps.adapter, namespace, key)
    end

    --- Lists all keys in a namespace.
    --- @param namespace string Your mod name
    --- @return table|nil keys Sorted array of key names
    --- @return string|nil errorMessage
    function api.listKeys(namespace)
        return deps.listKeys(deps.adapter, namespace)
    end

    --- Returns true if the database is ready to use.
    --- @return boolean
    function api.isReady()
        return deps.adapter.isReady()
    end

    --- Returns the API version string.
    --- @return string
    function api.getVersion()
        return "1.0.0"
    end

    return api
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = buildGlobalAPI end
return buildGlobalAPI
