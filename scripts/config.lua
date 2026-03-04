-- Configuration for DBTest
local M = {
  DB_DIR = "modSaveData_DBTest",
  CMD_SET = "dbSet",
  CMD_GET = "dbGet",
}

-- Auto-registration
if DBTest and DBTest.modules then
    DBTest.modules.config = M
end

return M
