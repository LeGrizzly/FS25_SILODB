-- FS25_DBAPI - Centralized Database Manager
-- Main entry point and Dependency Injection container.

local MOD_NAME = g_currentModName
local MOD_DIR = g_currentModDirectory

-- Ensure MOD_DIR ends with a slash for robust path concatenation
if MOD_DIR ~= nil and not MOD_DIR:find("/$") and not MOD_DIR:find("\\$") then
    MOD_DIR = MOD_DIR .. "/"
end

-- Temporary loader to avoid exposing internal structure early
_G.DBAPI_LOADER = {
    _temp = nil
}

-- Internal storage for modules (private to this file)
local modules = {}

--- Safely loads a Lua module from the mod directory.
--- @param name string Module identifier
--- @param path string Relative path from mod root
--- @return any|nil module The loaded module or nil on failure
local function loadModule(name, path)
    local fullPath = MOD_DIR .. path
    if not fileExists(fullPath) then
        print(string.format("DBAPI Error: File not found: %s", fullPath))
        return nil
    end

    _G.DBAPI_LOADER._temp = nil
    local result = source(fullPath)
    
    -- Si source() retourne nil (typique FS25), on récupère ce que le module a déposé dans _temp
    if result == nil then
        result = _G.DBAPI_LOADER._temp
    end
    
    if result ~= nil then
        modules[name] = result
        _G.DBAPI_LOADER._temp = nil -- Nettoyage après chaque chargement
        return result
    end

    print(string.format("DBAPI Warning: Module '%s' returned nil", name))
    return nil
end

-- =============================================================================
-- Phase 1: Load modules
-- =============================================================================

local json             = loadModule("json",          "scripts/utils/json.lua")
local FlatDB           = loadModule("flatdb",        "scripts/infrastructure/FlatDB.lua")
local DatabaseAdapter  = loadModule("adapter",       "scripts/persistence/DatabaseAdapter.lua")
local SetValue         = loadModule("setValue",       "scripts/usecases/SetValue.lua")
local GetValue         = loadModule("getValue",       "scripts/usecases/GetValue.lua")
local DeleteValue      = loadModule("deleteValue",    "scripts/usecases/DeleteValue.lua")
local ListKeys         = loadModule("listKeys",       "scripts/usecases/ListKeys.lua")
local ConsoleInterface = loadModule("console",      "scripts/interfaces/ConsoleInterface.lua")
local buildGlobalAPI   = loadModule("globalAPI",     "scripts/interfaces/GlobalAPI.lua")

-- Nettoyage du loader temporaire
_G.DBAPI_LOADER = nil

-- Link JSON to FlatDB
if FlatDB and json then
    FlatDB.linkJSON(json)
end

-- =============================================================================
-- Dependency bundle
-- =============================================================================

local deps = {
    adapter     = DatabaseAdapter,
    setValue     = SetValue,
    getValue     = GetValue,
    deleteValue  = DeleteValue,
    listKeys     = ListKeys,
    json         = json,
}

-- =============================================================================
-- Final Global Exposure
-- =============================================================================

-- Global table for cross-mod access
if _G.g_globalMods == nil then
    _G.g_globalMods = {}
end

-- Build public API
local publicAPI = nil
if buildGlobalAPI then
    publicAPI = buildGlobalAPI(deps)
end

-- Expose via g_globalMods["FS25_DBAPI"] as requested
if publicAPI then
    _G.g_globalMods["FS25_DBAPI"] = publicAPI
    print("DBAPI: Public API exposed via g_globalMods['FS25_DBAPI']")
else
    print("DBAPI Error: Failed to build public API")
end

-- =============================================================================
-- Mod Event Listener
-- =============================================================================

local DBAPI_Listener = {}
DBAPI_Listener.name = MOD_NAME
DBAPI_Listener.directory = MOD_DIR

function DBAPI_Listener:loadMap(filename)
    local savegameDir = g_currentMission.missionInfo.savegameDirectory
    local dbPath = savegameDir and (savegameDir .. "/DBAPI_data") or "modSaveData_DBAPI"

    if DatabaseAdapter and FlatDB then
        DatabaseAdapter.init(FlatDB, dbPath)
    end
    print("DBAPI: Database layer initialized")
    
    -- Register console commands here to ensure dependencies are initialized
    if ConsoleInterface then
        ConsoleInterface.register(deps)
    end
end

function DBAPI_Listener:deleteMap()
    if DatabaseAdapter then
        DatabaseAdapter.save()
    end
end

addModEventListener(DBAPI_Listener)
print("DBAPI: Mod loaded (v1.0.0)")
