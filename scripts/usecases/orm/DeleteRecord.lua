-- DeleteRecord - Use case for deleting a record by ID

--- Deletes a record by ID.
--- @param deps table {modelRegistry, modelRepo, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param id number Record ID
--- @return boolean success
--- @return string|nil errorMessage
local function DeleteRecord(deps, namespace, modelName, id)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return false, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    if not id then
        return false, "id is required"
    end

    local records = deps.modelRepo.loadAllRecords(deps.adapter, namespace, modelName)
    if not records[tostring(id)] then
        return false, string.format("record with id %s not found", tostring(id))
    end

    return deps.modelRepo.deleteRecord(deps.adapter, namespace, modelName, id)
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = DeleteRecord end
return DeleteRecord
