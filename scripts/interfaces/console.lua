-- Console Interface for DBTest
-- Using standard FS25 addConsoleCommand

local M = {}
local isRegistered = false

local function formatValue(value)
  if value == nil then return "nil" end
  if type(value) == "table" then return "{...}" end
  return tostring(value)
end

function M.register(adapter, setUsecase, getUsecase)
  if isRegistered then return end
  
  -- Store dependencies
  M.adapter = adapter
  M.setUsecase = setUsecase
  M.getUsecase = getUsecase

  -- Command Handler for dbSet
  function M:onSet(key, value)
    if not key or value == nil then
      print("Usage: dbSet <key> <value>")
      return
    end
    
    local ok, err = self.setUsecase(self.adapter, key, value)
    if ok then
      print(string.format("DBTest: Set %s = %s", key, formatValue(value)))
    else
      print(string.format("DBTest Error: %s", err))
    end
  end

  -- Command Handler for dbGet
  function M:onGet(key)
    if not key then
      print("Usage: dbGet <key>")
      return
    end
    
    local value, err = self.getUsecase(self.adapter, key)
    if err then
      print(string.format("DBTest Error: %s", err))
    else
      print(string.format("DBTest: Get %s = %s", key, formatValue(value)))
    end
  end

  -- Registration via standard FS25 global function
  -- Parameters: commandName, description, functionName, targetObject
  if addConsoleCommand ~= nil then
    addConsoleCommand("dbSet", "Sets a key/value pair in mod database", "onSet", M)
    addConsoleCommand("dbGet", "Retrieves a value from mod database by key", "onGet", M)
    
    isRegistered = true
    print("DBTest: Console commands registered via addConsoleCommand")
  else
    print("DBTest Error: addConsoleCommand function not found in global scope")
  end
end

-- Auto-registration in DBTest modules
if DBTest and DBTest.modules then
    DBTest.modules.console = M
end

return M
