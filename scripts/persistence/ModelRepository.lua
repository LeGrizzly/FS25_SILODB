-- ModelRepository - Raw access to ORM schema/data pages via DatabaseAdapter
-- Uses prefixed namespaces to avoid collision with key-value data.

local ModelRepository = {}

--- Returns the FlatDB page name for a model's schema.
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return string
function ModelRepository.getSchemaPageName(namespace, modelName)
    return namespace .. "__schema_" .. modelName
end

--- Returns the FlatDB page name for a model's data.
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return string
function ModelRepository.getDataPageName(namespace, modelName)
    return namespace .. "__data_" .. modelName
end

--- Loads all records for a model.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return table records Map of stringified IDs to record tables
function ModelRepository.loadAllRecords(adapter, namespace, modelName)
    local pageName = ModelRepository.getDataPageName(namespace, modelName)
    local data = adapter.get(pageName, "__records")
    return data or {}
end

--- Saves a single record by ID.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param id number Record ID
--- @param record table Record data
--- @return boolean success
--- @return string|nil errorMessage
function ModelRepository.saveRecord(adapter, namespace, modelName, id, record)
    local pageName = ModelRepository.getDataPageName(namespace, modelName)
    local records = ModelRepository.loadAllRecords(adapter, namespace, modelName)
    records[tostring(id)] = record
    return adapter.set(pageName, "__records", records)
end

--- Deletes a record by ID.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param id number Record ID
--- @return boolean success
--- @return string|nil errorMessage
function ModelRepository.deleteRecord(adapter, namespace, modelName, id)
    local pageName = ModelRepository.getDataPageName(namespace, modelName)
    local records = ModelRepository.loadAllRecords(adapter, namespace, modelName)
    records[tostring(id)] = nil
    return adapter.set(pageName, "__records", records)
end

--- Gets the next auto-increment ID for a model and increments the counter.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return number nextId
function ModelRepository.getNextId(adapter, namespace, modelName)
    local pageName = ModelRepository.getSchemaPageName(namespace, modelName)
    local nextId = adapter.get(pageName, "__nextId") or 1
    adapter.set(pageName, "__nextId", nextId + 1)
    return nextId
end

--- Loads the schema definition for a model.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return table|nil schema
function ModelRepository.loadSchema(adapter, namespace, modelName)
    local pageName = ModelRepository.getSchemaPageName(namespace, modelName)
    return adapter.get(pageName, "__schema")
end

--- Saves the schema definition for a model.
--- @param adapter table DatabaseAdapter
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param schema table Schema definition
--- @return boolean success
--- @return string|nil errorMessage
function ModelRepository.saveSchema(adapter, namespace, modelName, schema)
    local pageName = ModelRepository.getSchemaPageName(namespace, modelName)
    return adapter.set(pageName, "__schema", schema)
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = ModelRepository end
return ModelRepository
