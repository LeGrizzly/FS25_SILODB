-- ConsoleInterface - Registers developer console commands for DBAPI
-- ORM Commands: dbDefine, dbCreate, dbFind, dbFindAll, dbUpdate, dbRemove, dbHelp

local ConsoleInterface = {}
local isRegistered = false

local adapter = nil
local jsonModule = nil
local ormDeps = nil

--- Formats a value for console display.
--- @param value any
--- @return string
local function formatValue(value)
    if value == nil then return "nil" end
    if type(value) == "table" then
        if jsonModule then
            local ok, str = pcall(jsonModule.encode, value)
            if ok then return str end
        end
        return "{table}"
    end
    return tostring(value)
end

--- Parses "field:type:constraint" tokens into a fields definition table.
--- e.g. "name:string:required money:number:0" => { name={type="string",required=true}, money={type="number",default=0} }
--- @param ... string Field tokens
--- @return table fields
local function parseFieldTokens(...)
    local fields = {}
    local args = {...}
    for _, token in ipairs(args) do
        local parts = {}
        for part in token:gmatch("[^:]+") do
            parts[#parts + 1] = part
        end
        local name = parts[1]
        local ftype = parts[2] or "string"
        local constraint = parts[3]

        local fieldDef = { type = ftype }
        if constraint == "required" then
            fieldDef.required = true
        elseif constraint then
            if ftype == "number" then
                fieldDef.default = tonumber(constraint) or 0
            elseif ftype == "boolean" then
                fieldDef.default = (constraint == "true")
            else
                fieldDef.default = constraint
            end
        end
        fields[name] = fieldDef
    end
    return fields
end

--- Parses "key=value" tokens into a data table, coercing types based on schema.
--- @param schema table Model schema
--- @param ... string Data tokens
--- @return table data
local function parseDataTokens(schema, ...)
    local data = {}
    local args = {...}
    for _, token in ipairs(args) do
        local eqPos = token:find("=")
        if eqPos then
            local key = token:sub(1, eqPos - 1)
            local val = token:sub(eqPos + 1)
            local fieldDef = schema.fields[key]
            if fieldDef then
                if fieldDef.type == "number" then
                    data[key] = tonumber(val)
                elseif fieldDef.type == "boolean" then
                    data[key] = (val == "true")
                else
                    data[key] = val
                end
            else
                data[key] = val
            end
        end
    end
    return data
end

--- Console handler: dbDefine <namespace> <model> <field:type:constraint> ...
function ConsoleInterface:onDefine(namespace, model, ...)
    if not namespace or not model then
        print("Usage: dbDefine <namespace> <model> <field:type[:required|default]> ...")
        return
    end
    local fields = parseFieldTokens(...)
    local schema, err = ormDeps.modelRegistry.define(
        adapter, ormDeps.modelRepo, ormDeps.schemaValidator,
        namespace, model, { fields = fields }
    )
    if schema then
        print(string.format("DBAPI ORM: Model '%s' defined in [%s]", model, namespace))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbCreate <namespace> <model> <key=value> ...
function ConsoleInterface:onCreate(namespace, model, ...)
    if not namespace or not model then
        print("Usage: dbCreate <namespace> <model> <key=value> ...")
        return
    end
    local schema = ormDeps.modelRegistry.getSchema(namespace, model)
    if not schema then
        print(string.format("DBAPI Error: model '%s' not defined in [%s]", model, namespace))
        return
    end
    local data = parseDataTokens(schema, ...)
    local record, err = ormDeps.createRecord(ormDeps, namespace, model, data)
    if record then
        print(string.format("DBAPI ORM: Created %s #%d in [%s]", model, record.id, namespace))
        print("  " .. formatValue(record))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbFind <namespace> <model> <id>
function ConsoleInterface:onFindById(namespace, model, id)
    if not namespace or not model or not id then
        print("Usage: dbFind <namespace> <model> <id>")
        return
    end
    local numId = tonumber(id)
    if not numId then
        print("DBAPI Error: id must be a number")
        return
    end
    local record, err = ormDeps.findRecord.findById(ormDeps, namespace, model, numId)
    if err then
        print(string.format("DBAPI Error: %s", tostring(err)))
    elseif record then
        print(string.format("DBAPI ORM: %s #%d in [%s]", model, numId, namespace))
        print("  " .. formatValue(record))
    else
        print(string.format("DBAPI ORM: %s #%d not found in [%s]", model, numId, namespace))
    end
end

--- Console handler: dbFindAll <namespace> <model>
function ConsoleInterface:onFindAll(namespace, model)
    if not namespace or not model then
        print("Usage: dbFindAll <namespace> <model>")
        return
    end
    local results, err = ormDeps.findRecord.findAll(ormDeps, namespace, model)
    if err then
        print(string.format("DBAPI Error: %s", tostring(err)))
        return
    end
    print(string.format("DBAPI ORM: %d %s record(s) in [%s]", #results, model, namespace))
    for _, rec in ipairs(results) do
        print("  " .. formatValue(rec))
    end
end

--- Console handler: dbUpdate <namespace> <model> <id> <key=value> ...
function ConsoleInterface:onUpdate(namespace, model, id, ...)
    if not namespace or not model or not id then
        print("Usage: dbUpdate <namespace> <model> <id> <key=value> ...")
        return
    end
    local numId = tonumber(id)
    if not numId then
        print("DBAPI Error: id must be a number")
        return
    end
    local schema = ormDeps.modelRegistry.getSchema(namespace, model)
    if not schema then
        print(string.format("DBAPI Error: model '%s' not defined in [%s]", model, namespace))
        return
    end
    local data = parseDataTokens(schema, ...)
    local record, err = ormDeps.updateRecord(ormDeps, namespace, model, numId, data)
    if record then
        print(string.format("DBAPI ORM: Updated %s #%d in [%s]", model, numId, namespace))
        print("  " .. formatValue(record))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbRemove <namespace> <model> <id>
function ConsoleInterface:onRemove(namespace, model, id)
    if not namespace or not model or not id then
        print("Usage: dbRemove <namespace> <model> <id>")
        return
    end
    local numId = tonumber(id)
    if not numId then
        print("DBAPI Error: id must be a number")
        return
    end
    local ok, err = ormDeps.deleteRecord(ormDeps, namespace, model, numId)
    if ok then
        print(string.format("DBAPI ORM: Deleted %s #%d from [%s]", model, numId, namespace))
    else
        print(string.format("DBAPI Error: %s", tostring(err)))
    end
end

--- Console handler: dbHelp
function ConsoleInterface:onHelp()
    print("--- DBAPI ORM Console Commands ---")
    print("  dbDefine <ns> <model> <field:type[:constraint]> ...")
    print("  dbCreate <ns> <model> <key=value> ...")
    print("  dbFind <ns> <model> <id>           Find record by ID")
    print("  dbFindAll <ns> <model>              List all records")
    print("  dbUpdate <ns> <model> <id> <key=value> ...")
    print("  dbRemove <ns> <model> <id>          Delete a record")
    print("  dbHelp                             Show this help")
    print("----------------------------------")
end

--- Registers all console commands with the FS25 engine.
--- @param deps table {adapter, json, modelRegistry, ...}
function ConsoleInterface.register(deps)
    if isRegistered then return end

    adapter = deps.adapter
    jsonModule = deps.json
    ormDeps = deps

    if addConsoleCommand == nil then
        print("DBAPI Error: addConsoleCommand not available")
        return
    end

    addConsoleCommand("dbDefine", "Define model: dbDefine <ns> <model> <field:type[:constraint]> ...", "onDefine", ConsoleInterface)
    addConsoleCommand("dbCreate", "Create record: dbCreate <ns> <model> <key=value> ...", "onCreate", ConsoleInterface)
    addConsoleCommand("dbFind", "Find by ID: dbFind <ns> <model> <id>", "onFindById", ConsoleInterface)
    addConsoleCommand("dbFindAll", "List records: dbFindAll <ns> <model>", "onFindAll", ConsoleInterface)
    addConsoleCommand("dbUpdate", "Update record: dbUpdate <ns> <model> <id> <key=value> ...", "onUpdate", ConsoleInterface)
    addConsoleCommand("dbRemove", "Delete record: dbRemove <ns> <model> <id>", "onRemove", ConsoleInterface)
    addConsoleCommand("dbHelp", "Show DBAPI help", "onHelp", ConsoleInterface)

    isRegistered = true
    print("DBAPI: Console commands registered (dbDefine, dbCreate, dbFind, dbFindAll, dbUpdate, dbRemove, dbHelp)")
end

if _G.DBAPI_LOADER then _G.DBAPI_LOADER._temp = ConsoleInterface end
return ConsoleInterface
