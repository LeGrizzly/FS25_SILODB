-- setValue use-case
local usecase = function(adapter, key, value)
  if not key or value == nil then
    return false, "missing key or value"
  end
  adapter.set(key, value)
  return true
end

-- Auto-registration
if DBTest and DBTest.modules then
    DBTest.modules.setUsecase = usecase
end

return usecase
