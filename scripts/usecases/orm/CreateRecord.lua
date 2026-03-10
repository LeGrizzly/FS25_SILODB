-- CreateRecord - Use case for creating a new record with validation and auto-ID

--- Creates a new record for a model.
--- @param deps table {modelRegistry, modelRepo, schemaValidator, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param data table Field values for the new record
--- @return table|nil record The created record with id and timestamps
--- @return string|nil errorMessage
local function CreateRecord(deps, namespace, modelName, data)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return nil, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    local cleaned, err = deps.schemaValidator.validate(schema, data, false)
    if not cleaned then
        return nil, err
    end

    local id = deps.modelRepo.getNextId(deps.adapter, namespace, modelName)
    local now = 0
    if g_currentMission and g_currentMission.time then
        now = g_currentMission.time
    end

    cleaned.id = id
    cleaned._createdAt = now
    cleaned._updatedAt = now

    local ok, saveErr = deps.modelRepo.saveRecord(deps.adapter, namespace, modelName, id, cleaned)
    if not ok then
        return nil, "failed to save record: " .. tostring(saveErr)
    end

    return cleaned
end

if _G.SILODB_LOADER then _G.SILODB_LOADER._temp = CreateRecord end
return CreateRecord
