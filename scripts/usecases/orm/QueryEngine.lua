-- QueryEngine - Filters, sorts, and paginates record sets
-- Supports exact match, comparison operators, ordering, limit/offset.

local QueryEngine = {}

--- Checks if a record field matches a single where condition value.
--- @param fieldValue any The record's field value
--- @param condition any Exact value or operator table
--- @return boolean
local function matchesCondition(fieldValue, condition)
    if type(condition) ~= "table" then
        return fieldValue == condition
    end

    -- Operator table: { gt = 3, lte = 10, neq = 5, contains = "abc" }
    for op, expected in pairs(condition) do
        if op == "gt" then
            if not (type(fieldValue) == "number" and fieldValue > expected) then return false end
        elseif op == "gte" then
            if not (type(fieldValue) == "number" and fieldValue >= expected) then return false end
        elseif op == "lt" then
            if not (type(fieldValue) == "number" and fieldValue < expected) then return false end
        elseif op == "lte" then
            if not (type(fieldValue) == "number" and fieldValue <= expected) then return false end
        elseif op == "neq" then
            if fieldValue == expected then return false end
        elseif op == "contains" then
            if type(fieldValue) ~= "string" or not fieldValue:find(expected, 1, true) then return false end
        else
            return false
        end
    end
    return true
end

--- Checks if a record matches all where conditions.
--- @param record table The record to test
--- @param where table Map of field names to conditions
--- @return boolean
function QueryEngine.matchesWhere(record, where)
    if not where then return true end
    for field, condition in pairs(where) do
        if not matchesCondition(record[field], condition) then
            return false
        end
    end
    return true
end

--- Executes a query against a records table.
--- @param records table Map of string IDs to records
--- @param query table|nil Query with optional where, orderBy, orderDir, limit, offset
--- @return table results Array of matching records
function QueryEngine.execute(records, query)
    query = query or {}
    local results = {}

    -- Filter
    for _, record in pairs(records) do
        if QueryEngine.matchesWhere(record, query.where) then
            results[#results + 1] = record
        end
    end

    -- Sort
    if query.orderBy then
        local field = query.orderBy
        local desc = (query.orderDir == "desc")
        table.sort(results, function(a, b)
            local va = a[field]
            local vb = b[field]
            if va == nil and vb == nil then return false end
            if va == nil then return not desc end
            if vb == nil then return desc end
            if desc then
                return va > vb
            end
            return va < vb
        end)
    end

    -- Pagination
    if query.offset or query.limit then
        local offset = query.offset or 0
        local limit = query.limit or #results
        local paginated = {}
        for i = offset + 1, math.min(offset + limit, #results) do
            paginated[#paginated + 1] = results[i]
        end
        results = paginated
    end

    return results
end

if _G.SILODB_LOADER then _G.SILODB_LOADER._temp = QueryEngine end
return QueryEngine
