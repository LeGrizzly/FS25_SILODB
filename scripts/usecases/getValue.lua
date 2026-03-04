-- getValue use-case
local usecase = function(adapter, key)
  if not key then
    return nil, "missing key"
  end
  local value = adapter.get(key)
  return value
end

-- Auto-registration
if DBTest and DBTest.modules then
    DBTest.modules.getUsecase = usecase
end

return usecase
