-- =============================================================================
-- FS25_ExampleMod — Example usage of the DBAPI API
-- =============================================================================
-- This file shows how a mod developer can use DBAPI to persist data
-- across savegame sessions. Install the DBAPI mod, then use the global
-- _G.DBAPI API from any of your scripts.
-- =============================================================================

--- Namespace — use your mod name so keys never collide with other mods.
local MY_NAMESPACE = "FS25_ExampleMod"

-- =============================================================================
-- 1. Safety check — always verify DBAPI is loaded before using it
-- =============================================================================

--- Returns true when DBAPI is available and the database is open.
--- @return boolean
local function isDBAvailable()
    return _G.DBAPI ~= nil and DBAPI.isReady()
end

-- =============================================================================
-- 2. Storing values (string, number, boolean, table)
-- =============================================================================

local function saveExamples()
    if not isDBAvailable() then
        print("ExampleMod: DBAPI is not available yet")
        return
    end

    -- Store a simple number
    local ok, err = DBAPI.setValue(MY_NAMESPACE, "playerLevel", 12)
    if not ok then
        print("ExampleMod: Failed to save playerLevel — " .. tostring(err))
    end

    -- Store a string
    DBAPI.setValue(MY_NAMESPACE, "lastMap", "Elm Creek")

    -- Store a boolean
    DBAPI.setValue(MY_NAMESPACE, "tutorialDone", true)

    -- Store a table (automatically serialized to JSON)
    local settings = {
        difficulty  = "hard",
        volume      = 0.8,
        autosave    = true,
    }
    DBAPI.setValue(MY_NAMESPACE, "settings", settings)

    print("ExampleMod: All data saved!")
end

-- =============================================================================
-- 3. Reading values
-- =============================================================================

local function loadExamples()
    if not isDBAvailable() then
        return
    end

    -- Read a number (returns nil if the key doesn't exist)
    local level = DBAPI.getValue(MY_NAMESPACE, "playerLevel")
    if level then
        print("ExampleMod: Player level is " .. tostring(level))
    end

    -- Read with a fallback default
    local map = DBAPI.getValue(MY_NAMESPACE, "lastMap")
    if map == nil then
        map = "Haut-Beyleron"
    end
    print("ExampleMod: Map = " .. map)

    -- Read a table back
    local settings = DBAPI.getValue(MY_NAMESPACE, "settings")
    if settings then
        print("ExampleMod: Difficulty = " .. settings.difficulty)
        print("ExampleMod: Volume     = " .. tostring(settings.volume))
    end
end

-- =============================================================================
-- 4. Listing all keys in your namespace
-- =============================================================================

local function listAllData()
    if not isDBAvailable() then
        return
    end

    local keys, err = DBAPI.listKeys(MY_NAMESPACE)
    if err then
        print("ExampleMod: Error listing keys — " .. tostring(err))
        return
    end

    print("ExampleMod: Stored keys (" .. #keys .. "):")
    for _, key in ipairs(keys) do
        local value = DBAPI.getValue(MY_NAMESPACE, key)
        print("  " .. key .. " = " .. tostring(value))
    end
end

-- =============================================================================
-- 5. Deleting a key
-- =============================================================================

local function resetTutorial()
    if not isDBAvailable() then
        return
    end

    local ok, err = DBAPI.deleteValue(MY_NAMESPACE, "tutorialDone")
    if ok then
        print("ExampleMod: Tutorial flag cleared, will show again next time")
    else
        print("ExampleMod: Could not delete — " .. tostring(err))
    end
end

-- =============================================================================
-- 6. Checking the API version
-- =============================================================================

local function printVersion()
    if not isDBAvailable() then
        return
    end

    print("ExampleMod: Using DBAPI v" .. DBAPI.getVersion())
end

-- =============================================================================
-- 7. Typical mod integration — save on map exit, load on map enter
-- =============================================================================

local ExampleMod = {}

--- Called by FS25 when the savegame loads.
function ExampleMod:loadMap()
    if not isDBAvailable() then
        print("ExampleMod: DBAPI not found — persistent features disabled")
        return
    end

    printVersion()
    loadExamples()
    listAllData()
end

--- Called by FS25 when the player saves or exits.
function ExampleMod:saveToXMLFile()
    if not isDBAvailable() then
        return
    end

    saveExamples()
end

--- Called when the player resets the tutorial from an in-game menu.
function ExampleMod:onResetTutorial()
    resetTutorial()
end
