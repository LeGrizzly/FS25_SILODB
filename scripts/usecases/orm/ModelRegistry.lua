-- ModelRegistry - Registers and stores model definitions
-- Keeps an in-memory registry and persists schemas to FlatDB.

local ModelRegistry = {}

-- In-memory registry: registry["namespace:modelName"] = schema
local registry = {}

--- Builds a registry key from namespace and model name.
--- @param namespace string
--- @param modelName string
--- @return string
local function registryKey(namespace, modelName)
    return namespace .. ":" .. modelName
end

--- Defines a new model or returns existing schema if already defined.
--- @param adapter table DatabaseAdapter
--- @param modelRepo table ModelRepository
--- @param validator table SchemaValidator
--- @param namespace string Mod namespace
--- @param modelName string Model name (e.g. "Player")
--- @param definition table Model definition with fields (and optional relationships)
--- @return table|nil schema The registered schema
--- @return string|nil errorMessage
function ModelRegistry.define(adapter, modelRepo, validator, namespace, modelName, definition)
    if not namespace or namespace == "" then
        return nil, "namespace is required"
    end
    if not modelName or modelName == "" then
        return nil, "modelName is required"
    end

    local key = registryKey(namespace, modelName)

    -- Already registered in this session
    if registry[key] then
        return registry[key]
    end

    -- Validate the definition
    local ok, err = validator.validateDefinition(definition)
    if not ok then
        return nil, err
    end

    local schema = {
        modelName = modelName,
        namespace = namespace,
        fields = definition.fields,
        relationships = definition.relationships,
    }

    -- Persist schema to FlatDB
    local saveOk, saveErr = modelRepo.saveSchema(adapter, namespace, modelName, schema)
    if not saveOk then
        return nil, "failed to persist schema: " .. tostring(saveErr)
    end

    -- Store in memory
    registry[key] = schema
    return schema
end

--- Retrieves a registered schema.
--- @param namespace string Mod namespace
--- @param modelName string Model name
--- @return table|nil schema
function ModelRegistry.getSchema(namespace, modelName)
    return registry[registryKey(namespace, modelName)]
end

--- Clears the in-memory registry (useful for testing).
function ModelRegistry.clearRegistry()
    registry = {}
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = ModelRegistry end
return ModelRegistry
