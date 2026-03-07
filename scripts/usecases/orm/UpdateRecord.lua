-- UpdateRecord - Use case for partial update of a record with validation

--- Updates an existing record by ID with partial data.
--- @param deps table {modelRegistry, modelRepo, schemaValidator, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param id number Record ID
--- @param data table Partial field values to update
--- @return table|nil record The updated record
--- @return string|nil errorMessage
local function UpdateRecord(deps, namespace, modelName, id, data)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return nil, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    if not id then
        return nil, "id is required"
    end

    local records = deps.modelRepo.loadAllRecords(deps.adapter, namespace, modelName)
    local existing = records[tostring(id)]
    if not existing then
        return nil, string.format("record with id %s not found", tostring(id))
    end

    local cleaned, err = deps.schemaValidator.validate(schema, data, true)
    if not cleaned then
        return nil, err
    end

    -- Merge cleaned fields into existing record
    for k, v in pairs(cleaned) do
        existing[k] = v
    end

    local now = 0
    if g_currentMission and g_currentMission.time then
        now = g_currentMission.time
    end
    existing._updatedAt = now

    local ok, saveErr = deps.modelRepo.saveRecord(deps.adapter, namespace, modelName, id, existing)
    if not ok then
        return nil, "failed to save record: " .. tostring(saveErr)
    end

    return existing
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = UpdateRecord end
return UpdateRecord
