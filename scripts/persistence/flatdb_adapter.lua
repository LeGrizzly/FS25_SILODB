-- FlatDB Adapter for FS25 DBTest
local M = {}
local db = nil
local dbPath = nil

function M.ensureDir(path)
  if createFolder then
    createFolder(path)
    return true
  end
  return false
end

function M.init(path)
  if not db then
    local flatdb = DBTest.modules.flatdb
    if not flatdb then
        print("DBTest Adapter Error: FlatDB module not found in DBTest.modules")
        return
    end
    
    dbPath = path or "modSaveData_DBTest"
    M.ensureDir(dbPath)
    db = flatdb(dbPath)
    print("DBTest: Database initialized at " .. tostring(dbPath))
  end
end

function M.set(key, value)
  if not db then return false, "Database not initialized" end
  if not db.data then db.data = {} end
  db.data[key] = value
  return db:save("data")
end

function M.get(key)
  if not db then return nil, "Database not initialized" end
  local data = db.data
  return data and data[key]
end

function M.save()
  if db then db:save() end
end

-- Auto-registration
if DBTest and DBTest.modules then
    DBTest.modules.adapter = M
end

return M
