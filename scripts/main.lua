-- FS25_SILODB - Centralized Database Manager (ORM)
-- Main entry point and Dependency Injection container.

local MOD_NAME = g_currentModName
local MOD_DIR = g_currentModDirectory

-- Ensure MOD_DIR ends with a slash for robust path concatenation
if MOD_DIR ~= nil and not MOD_DIR:find("/$") and not MOD_DIR:find("\\$") then
    MOD_DIR = MOD_DIR .. "/"
end

-- Temporary loader to avoid exposing internal structure early
_G.SILODB_LOADER = {
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
        print(string.format("SILODB Error: File not found: %s", fullPath))
        return nil
    end

    _G.SILODB_LOADER._temp = nil
    local result = source(fullPath)

    -- Si source() retourne nil (typique FS25), on recupere ce que le module a depose dans _temp
    if result == nil then
        result = _G.SILODB_LOADER._temp
    end

    if result ~= nil then
        modules[name] = result
        _G.SILODB_LOADER._temp = nil -- Nettoyage apres chaque chargement
        return result
    end

    print(string.format("SILODB Warning: Module '%s' returned nil", name))
    return nil
end

-- =============================================================================
-- Phase 1: Load modules
-- =============================================================================

local json             = loadModule("json",          "scripts/utils/json.lua")
local FlatDB           = loadModule("flatdb",        "scripts/infrastructure/FlatDB.lua")
local DatabaseAdapter  = loadModule("adapter",       "scripts/persistence/DatabaseAdapter.lua")
local ConsoleInterface = loadModule("console",      "scripts/interfaces/ConsoleInterface.lua")
local buildGlobalAPI   = loadModule("globalAPI",     "scripts/interfaces/GlobalAPI.lua")

-- ORM modules
local ModelRepository  = loadModule("modelRepo",       "scripts/persistence/ModelRepository.lua")
local SchemaValidator  = loadModule("schemaValidator",  "scripts/usecases/orm/SchemaValidator.lua")
local QueryEngine      = loadModule("queryEngine",      "scripts/usecases/orm/QueryEngine.lua")
local ModelRegistry    = loadModule("modelRegistry",    "scripts/usecases/orm/ModelRegistry.lua")
local CreateRecord     = loadModule("createRecord",     "scripts/usecases/orm/CreateRecord.lua")
local FindRecord       = loadModule("findRecord",       "scripts/usecases/orm/FindRecord.lua")
local UpdateRecord     = loadModule("updateRecord",     "scripts/usecases/orm/UpdateRecord.lua")
local DeleteRecord     = loadModule("deleteRecord",     "scripts/usecases/orm/DeleteRecord.lua")

-- Nettoyage du loader temporaire
_G.SILODB_LOADER = nil

-- Link JSON to FlatDB
if FlatDB and json then
    FlatDB.linkJSON(json)
end

-- =============================================================================
-- Dependency bundle
-- =============================================================================

local deps = {
    adapter         = DatabaseAdapter,
    json             = json,
    modelRepo        = ModelRepository,
    schemaValidator  = SchemaValidator,
    queryEngine      = QueryEngine,
    modelRegistry    = ModelRegistry,
    createRecord     = CreateRecord,
    findRecord       = FindRecord,
    updateRecord     = UpdateRecord,
    deleteRecord     = DeleteRecord,
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

-- Expose via g_globalMods["FS25_SILODB"] as requested
if publicAPI then
    _G.g_globalMods["FS25_SILODB"] = publicAPI
    print("SILODB: Public API exposed via g_globalMods['FS25_SILODB']")
else
    print("SILODB Error: Failed to build public API")
end

-- =============================================================================
-- Mod Event Listener
-- =============================================================================

local SILODB_Listener = {}
SILODB_Listener.name = MOD_NAME
SILODB_Listener.directory = MOD_DIR

function SILODB_Listener:loadMap(filename)
    local savegameDir = g_currentMission.missionInfo.savegameDirectory
    local dbPath = savegameDir and (savegameDir .. "/SILODB_data") or "modSaveData_SILODB"

    if DatabaseAdapter and FlatDB then
        DatabaseAdapter.init(FlatDB, dbPath)
    end
    print("SILODB: Database layer initialized")

    ItemSystem.save = Utils.prependedFunction(
        ItemSystem.save,
        function()
            print("SILODB [SAVE-HOOK]: ItemSystem.save hook triggered")
            if DatabaseAdapter then
                DatabaseAdapter.save()
            end
        end
    )
    print("SILODB: ItemSystem.save hook registered")

    -- Register console commands here to ensure dependencies are initialized
    if ConsoleInterface then
        ConsoleInterface.register(deps)
    end
end

function SILODB_Listener:deleteMap()
    if DatabaseAdapter then
        DatabaseAdapter.save()
    end
end

addModEventListener(SILODB_Listener)
print("SILODB: Mod loaded (v2.0.0)")
