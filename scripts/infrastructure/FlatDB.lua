-- FlatDB v2.2 (FS25 Edition) - NoSQL Engine using XML-wrapped JSON
-- Bypasses io.open restrictions by using GIANTS XML API.

local FlatDB = {}
local dbPool = setmetatable({}, {__mode = "v"})
local pathPool = setmetatable({}, {__mode = "k"})
local dbMethods = {}

local jsonDecode, jsonEncode

--- Links the JSON engine to FlatDB.
function FlatDB.linkJSON(json)
    if not json or not json.encode or not json.decode then
        print("DBAPI Error: Invalid JSON module passed to FlatDB.linkJSON")
        return
    end
    jsonEncode = json.encode
    jsonDecode = json.decode
end

-- =============================================================================
-- FS25 Filesystem Utilities (using XML API)
-- =============================================================================

local function storePage(path, pageData)
    if not jsonEncode then return false end
    local ok, jsonString = pcall(jsonEncode, pageData)
    if not ok then return false end

    -- Path in FS25 must be relative to the mod directory or an absolute sandbox-safe path
    -- We use the XMLFile class in FS25
    local xmlFile = XMLFile.create("dbPage", path, "db")
    if xmlFile ~= nil then
        xmlFile:setString("db.data", jsonString)
        xmlFile:save()
        xmlFile:delete()
        return true
    end
    return false
end

local function loadPage(path)
    if not jsonDecode then return nil end
    if not fileExists(path) then return nil end
    
    local xmlFile = XMLFile.load("dbPage", path)
    if xmlFile == nil then return nil end
    
    local jsonString = xmlFile:getString("db.data")
    xmlFile:delete()
    
    if not jsonString or jsonString == "" then return {} end
    local ok, pageData = pcall(jsonDecode, jsonString)
    return ok and pageData or nil
end

-- =============================================================================
-- Database Methods (available on db instances)
-- =============================================================================

--- Saves one or all pages to disk.
dbMethods.save = function(db, pageName)
    local dbPath = pathPool[db]
    if not dbPath then return false end

    if pageName then
        if type(pageName) == "string" and type(db[pageName]) == "table" then
            return storePage(dbPath .. "/" .. pageName .. ".xml", db[pageName])
        end
        return false
    end

    for name, pageData in pairs(db) do
        if type(pageData) == "table" then
            storePage(dbPath .. "/" .. name .. ".xml", pageData)
        end
    end
    return true
end

local dbMetatable = {
    __index = function(db, key)
        if dbMethods[key] then return dbMethods[key] end
        local dbPath = pathPool[db]
        local pagePath = dbPath .. "/" .. key .. ".xml"
        if fileExists(pagePath) then
            local pageData = loadPage(pagePath)
            if pageData then
                rawset(db, key, pageData)
                return pageData
            end
        end
        return nil
    end
}

-- =============================================================================
-- Constructor: FlatDB(path) returns a db instance
-- =============================================================================

setmetatable(FlatDB, {
    __call = function(_, path)
        if dbPool[path] then return dbPool[path] end
        local db = {}
        setmetatable(db, dbMetatable)
        dbPool[path] = db
        pathPool[db] = path
        return db
    end
})

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = FlatDB end
return FlatDB
