-- FS25_DBTest - Main Entry Point

local DBTest = {}
DBTest.name = g_currentModName
DBTest.directory = g_currentModDirectory
_G.DBTest = DBTest

-- Shared table for modules
DBTest.modules = {}

-- Function to safely source a file
local function loadModule(name, path)
    local fullPath = DBTest.directory .. path
    if fileExists(fullPath) then
        local result = source(fullPath)
        if result ~= nil then
            DBTest.modules[name] = result
            return result
        end
        if DBTest.modules[name] ~= nil then
            return DBTest.modules[name]
        end
        return nil
    else
        print(string.format("DBTest Error: Could not find file %s", fullPath))
        return nil
    end
end

-- Load all components in order
loadModule("json", "scripts/utils/json.lua")
loadModule("config", "scripts/config.lua")
loadModule("flatdb", "scripts/infrastructre/flatdb.lua")
loadModule("adapter", "scripts/persistence/flatdb_adapter.lua")
loadModule("setUsecase", "scripts/usecases/setValue.lua")
loadModule("getUsecase", "scripts/usecases/getValue.lua")
loadModule("console", "scripts/interfaces/console.lua")

--- Called when the mod map is loaded
function DBTest:loadMap(filename)
    -- Database initialization (FileSystem is ready here)
    local savegameDir = g_currentMission.missionInfo.savegameDirectory
    local dbPath = savegameDir and (savegameDir .. "/dbtest_data") or "modSaveData_DBTest"
    
    local adapter = DBTest.modules.adapter
    if adapter and adapter.init then
        adapter.init(dbPath)
    end
    
    print("DBTest: Filesystem and Database layer initialized")
end

--- Custom function called via Mission00 hook
function DBTest:onLoadMapFinished()
    local adapter = DBTest.modules.adapter
    local console = DBTest.modules.console
    
    if console and console.register then
        -- Now g_commandManager is guaranteed to be ready
        console.register(
            adapter, 
            DBTest.modules.setUsecase, 
            DBTest.modules.getUsecase
        )
        print("DBTest: Console Commands and UI layer initialized")
    else
        print("DBTest Error: Console module or register function not found")
    end
end

function DBTest:deleteMap()
    local adapter = DBTest.modules.adapter
    if adapter and adapter.save then
        adapter.save()
    end
end

-- HOOK: Force the call to onLoadMapFinished when the mission is ready
-- This is the most reliable way in FS25 to get a "Load Finished" event
Mission00.loadMapFinished = Utils.appendedFunction(Mission00.loadMapFinished, function(mission, node, ...)
    if DBTest and DBTest.onLoadMapFinished then
        DBTest:onLoadMapFinished()
    end
end)

-- Register for standard events (loadMap, deleteMap)
addModEventListener(DBTest)

print("DBTest: Mod loaded and mission hooks installed")
