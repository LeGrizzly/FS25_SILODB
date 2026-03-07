-- FindRecord - Use cases for querying records: find, findAll, findById, count

local FindRecord = {}

--- Finds a single record matching a query.
--- @param deps table {modelRegistry, modelRepo, queryEngine, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param query table|nil Query with optional where
--- @return table|nil record First matching record
--- @return string|nil errorMessage
function FindRecord.find(deps, namespace, modelName, query)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return nil, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    local records = deps.modelRepo.loadAllRecords(deps.adapter, namespace, modelName)
    query = query or {}
    query.limit = 1
    local results = deps.queryEngine.execute(records, query)

    if #results == 0 then
        return nil
    end
    return results[1]
end

--- Finds all records matching a query.
--- @param deps table {modelRegistry, modelRepo, queryEngine, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param query table|nil Query with optional where, orderBy, limit, offset
--- @return table|nil results Array of matching records
--- @return string|nil errorMessage
function FindRecord.findAll(deps, namespace, modelName, query)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return nil, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    local records = deps.modelRepo.loadAllRecords(deps.adapter, namespace, modelName)
    return deps.queryEngine.execute(records, query)
end

--- Finds a record by its ID.
--- @param deps table {modelRegistry, modelRepo, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param id number Record ID
--- @return table|nil record
--- @return string|nil errorMessage
function FindRecord.findById(deps, namespace, modelName, id)
    local schema = deps.modelRegistry.getSchema(namespace, modelName)
    if not schema then
        return nil, string.format("model '%s' is not defined in namespace '%s'", modelName, namespace)
    end

    if not id then
        return nil, "id is required"
    end

    local records = deps.modelRepo.loadAllRecords(deps.adapter, namespace, modelName)
    return records[tostring(id)]
end

--- Counts records matching a query.
--- @param deps table {modelRegistry, modelRepo, queryEngine, adapter}
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @param query table|nil Query with optional where
--- @return number|nil count
--- @return string|nil errorMessage
function FindRecord.count(deps, namespace, modelName, query)
    local results, err = FindRecord.findAll(deps, namespace, modelName, query)
    if not results then
        return nil, err
    end
    return #results
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = FindRecord end
return FindRecord
