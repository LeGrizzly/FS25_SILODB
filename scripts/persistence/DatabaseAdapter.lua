-- DatabaseAdapter - Bridges FlatDB with FS25's savegame system
-- Each namespace gets its own FlatDB "page" (saved as namespace.xml).

local DatabaseAdapter = {}

local db = nil
local dbPath = nil
local flatDBRef = nil

--- Creates the database directory using FS25's sandbox-safe function.
--- @param path string Directory path to create
--- @return boolean success
local function ensureDirectory(path)
    if createFolder then
        print("SILODB [DIR]: ensureDirectory() calling createFolder: " .. tostring(path))
        createFolder(path)
        return true
    end
    print("SILODB [DIR]: WARNING - createFolder is not available!")
    return false
end

--- Initializes the database at the given path.
--- @param flatDB table The FlatDB constructor
--- @param path string File system path for the database
function DatabaseAdapter.init(flatDB, path)
    if db then return end

    if not flatDB then
        print("SILODB Error: FlatDB module is required for DatabaseAdapter.init")
        return
    end

    dbPath = path or "modSaveData_SILODB"
    flatDBRef = flatDB
    ensureDirectory(dbPath)
    db = flatDB(dbPath)
    print("SILODB: Database initialized at " .. tostring(dbPath))
end

--- Sets a value in a namespaced page.
--- @param namespace string The mod namespace (e.g. "FS25_MyMod")
--- @param key string The key to store
--- @param value any The value to store (string, number, boolean, table)
--- @return boolean success
--- @return string|nil errorMessage
function DatabaseAdapter.set(namespace, key, value)
    if not db then return false, "Database not initialized" end
    if not namespace or namespace == "" then return false, "namespace is required" end
    if not key or key == "" then return false, "key is required" end
    if value == nil then return false, "value cannot be nil (use delete to remove)" end

    if not db[namespace] then db[namespace] = {} end
    db[namespace][key] = value
    return db:save(namespace)
end

--- Gets a value from a namespaced page.
--- @param namespace string The mod namespace
--- @param key string The key to retrieve
--- @return any|nil value
--- @return string|nil errorMessage
function DatabaseAdapter.get(namespace, key)
    if not db then return nil, "Database not initialized" end
    if not namespace or namespace == "" then return nil, "namespace is required" end
    if not key or key == "" then return nil, "key is required" end

    local page = db[namespace]
    if not page then return nil end
    return page[key]
end

--- Persists all data to disk.
--- Resolves the current savegameDirectory at save-time because FS25 swaps
--- savegameDirectory to a tempsavegame folder during the save cycle.
function DatabaseAdapter.save()
    if not db then
        print("SILODB [SAVE]: SKIPPED - db is nil")
        return
    end

    local savePath = dbPath
    if g_currentMission
        and g_currentMission.missionInfo
        and g_currentMission.missionInfo.savegameDirectory then
        savePath = g_currentMission.missionInfo.savegameDirectory .. "/SILODB_data"
    end

    if not savePath then
        print("SILODB [SAVE]: SKIPPED - no save path available")
        return
    end

    print("SILODB [SAVE]: Saving to: " .. savePath .. " (dbPath was: " .. tostring(dbPath) .. ")")
    ensureDirectory(savePath)

    local originalPath = flatDBRef and flatDBRef.getPath(db) or nil
    if flatDBRef and savePath ~= originalPath then
        flatDBRef.setPath(db, savePath)
    end

    db:save()

    if flatDBRef and originalPath and savePath ~= originalPath then
        flatDBRef.setPath(db, originalPath)
    end

    print("SILODB [SAVE]: db:save() completed at " .. savePath)
end

--- Returns true if the database is initialized.
--- @return boolean
function DatabaseAdapter.isReady()
    return db ~= nil
end

if _G.SILODB_LOADER then _G.SILODB_LOADER._temp = DatabaseAdapter end
return DatabaseAdapter
