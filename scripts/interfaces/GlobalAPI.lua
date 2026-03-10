-- GlobalAPI - Public API exposed as _G.SILODB for other mods
-- This is the ONLY file that touches _G.SILODB.
-- All public methods validate inputs and delegate to use cases.

--- Builds the public API table.
--- @param deps table {adapter, modelRegistry, modelRepo, schemaValidator, ...}
--- @return table api The public _G.SILODB API
local function buildGlobalAPI(deps)
    local api = {}

    --- Returns true if the database is ready to use.
    --- @return boolean
    function api.isReady()
        return deps.adapter.isReady()
    end

    --- Returns the API version string.
    --- @return string
    function api.getVersion()
        return "2.0.0"
    end

    --- Returns true if ORM features are available.
    --- @return boolean
    function api.hasORM()
        return true
    end

    --- Binds to a namespace and returns an ORM instance with CRUD methods.
    --- @param namespace string Your mod name (e.g. "FS25_MyMod")
    --- @return table instance Bound ORM instance with :define, :create, :find, etc.
    function api.bind(namespace)
        if not namespace or namespace == "" then
            print("SILODB Error: bind() requires a namespace")
            return nil
        end

        local instance = { _namespace = namespace }

        --- Defines a model in this namespace.
        --- @param self table
        --- @param modelName string Model name (e.g. "Player")
        --- @param definition table Model definition with fields
        --- @return table|nil schema
        --- @return string|nil errorMessage
        function instance:define(modelName, definition)
            return deps.modelRegistry.define(
                deps.adapter, deps.modelRepo, deps.schemaValidator,
                self._namespace, modelName, definition
            )
        end

        --- Creates a new record.
        --- @param self table
        --- @param modelName string Model name
        --- @param data table Field values
        --- @return table|nil record
        --- @return string|nil errorMessage
        function instance:create(modelName, data)
            return deps.createRecord(deps, self._namespace, modelName, data)
        end

        --- Finds a single record matching a query.
        --- @param self table
        --- @param modelName string Model name
        --- @param query table|nil Query options
        --- @return table|nil record
        --- @return string|nil errorMessage
        function instance:find(modelName, query)
            return deps.findRecord.find(deps, self._namespace, modelName, query)
        end

        --- Finds all records matching a query.
        --- @param self table
        --- @param modelName string Model name
        --- @param query table|nil Query options
        --- @return table|nil results
        --- @return string|nil errorMessage
        function instance:findAll(modelName, query)
            return deps.findRecord.findAll(deps, self._namespace, modelName, query)
        end

        --- Finds a record by ID.
        --- @param self table
        --- @param modelName string Model name
        --- @param id number Record ID
        --- @return table|nil record
        --- @return string|nil errorMessage
        function instance:findById(modelName, id)
            return deps.findRecord.findById(deps, self._namespace, modelName, id)
        end

        --- Updates a record by ID.
        --- @param self table
        --- @param modelName string Model name
        --- @param id number Record ID
        --- @param data table Partial field values to update
        --- @return table|nil record
        --- @return string|nil errorMessage
        function instance:update(modelName, id, data)
            return deps.updateRecord(deps, self._namespace, modelName, id, data)
        end

        --- Deletes a record by ID.
        --- @param self table
        --- @param modelName string Model name
        --- @param id number Record ID
        --- @return boolean success
        --- @return string|nil errorMessage
        function instance:delete(modelName, id)
            return deps.deleteRecord(deps, self._namespace, modelName, id)
        end

        --- Counts records matching a query.
        --- @param self table
        --- @param modelName string Model name
        --- @param query table|nil Query options
        --- @return number|nil count
        --- @return string|nil errorMessage
        function instance:count(modelName, query)
            return deps.findRecord.count(deps, self._namespace, modelName, query)
        end

        return instance
    end

    return api
end

if _G.SILODB_LOADER then _G.SILODB_LOADER._temp = buildGlobalAPI end
return buildGlobalAPI
