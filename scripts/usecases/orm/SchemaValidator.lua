-- SchemaValidator - Validates data against model field definitions
-- Supports types: string, number, boolean, table
-- Handles required fields, defaults, and unknown field rejection.

local SchemaValidator = {}

local VALID_TYPES = {
    string = true,
    number = true,
    boolean = true,
    table = true,
}

--- Validates a model definition (called at define time).
--- @param definition table The model definition with fields
--- @return boolean valid
--- @return string|nil errorMessage
function SchemaValidator.validateDefinition(definition)
    if not definition then
        return false, "definition is required"
    end
    if not definition.fields or type(definition.fields) ~= "table" then
        return false, "definition.fields is required and must be a table"
    end

    local hasFields = false
    for fieldName, fieldDef in pairs(definition.fields) do
        hasFields = true
        if type(fieldName) ~= "string" then
            return false, "field names must be strings"
        end
        if type(fieldDef) ~= "table" then
            return false, string.format("field '%s' definition must be a table", fieldName)
        end
        if not fieldDef.type then
            return false, string.format("field '%s' must have a type", fieldName)
        end
        if not VALID_TYPES[fieldDef.type] then
            return false, string.format("field '%s' has invalid type '%s'", fieldName, tostring(fieldDef.type))
        end
    end

    if not hasFields then
        return false, "definition must have at least one field"
    end

    return true
end

--- Validates data against a schema's fields.
--- @param schema table The model schema (with .fields)
--- @param data table The data to validate
--- @param isUpdate boolean If true, skip required checks for missing fields
--- @return table|nil cleanedData Cleaned/validated data with defaults applied
--- @return string|nil errorMessage
function SchemaValidator.validate(schema, data, isUpdate)
    if not data or type(data) ~= "table" then
        return nil, "data must be a table"
    end

    local fields = schema.fields
    local cleaned = {}

    -- Check for unknown fields
    for key, _ in pairs(data) do
        if not fields[key] then
            return nil, string.format("unknown field '%s'", key)
        end
    end

    for fieldName, fieldDef in pairs(fields) do
        local value = data[fieldName]

        if value ~= nil then
            -- Type check
            if type(value) ~= fieldDef.type then
                return nil, string.format(
                    "field '%s' expected type '%s', got '%s'",
                    fieldName, fieldDef.type, type(value)
                )
            end
            cleaned[fieldName] = value
        elseif not isUpdate then
            -- Create mode: apply defaults or check required
            if fieldDef.required then
                return nil, string.format("field '%s' is required", fieldName)
            end
            if fieldDef.default ~= nil then
                cleaned[fieldName] = fieldDef.default
            end
        end
    end

    return cleaned
end

if _G.SILODB_LOADER then _G.SILODB_LOADER._temp = SchemaValidator end
return SchemaValidator
