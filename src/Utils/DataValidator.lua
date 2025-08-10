-- DataValidator.lua
-- Comprehensive data validation system for security and data integrity
-- Implements input sanitization, type checking, and format validation

local DataValidator = {}

-- Validation error types
local VALIDATION_ERRORS = {
    INVALID_TYPE = "INVALID_TYPE",
    INVALID_FORMAT = "INVALID_FORMAT",
    INVALID_RANGE = "INVALID_RANGE",
    INVALID_LENGTH = "INVALID_LENGTH",
    INVALID_CONTENT = "INVALID_CONTENT",
    SANITIZATION_FAILED = "SANITIZATION_FAILED"
}

-- Input sanitization patterns
local SANITIZATION_PATTERNS = {
    -- Remove potentially dangerous characters
    DANGEROUS_CHARS = "[<>\"'&]",
    -- Remove script injection patterns
    SCRIPT_INJECTION = "<script[^>]*>.*</script>",
    -- Remove HTML tags
    HTML_TAGS = "<[^>]+>",
    -- Remove control characters
    CONTROL_CHARS = "[\0-\31\127]"
}

-- Maximum allowed values for security
local MAXIMUM_VALUES = {
    STRING_LENGTH = 1000,
    TABLE_SIZE = 1000,
    ARRAY_SIZE = 100,
    NUMBER_MIN = -999999999,
    NUMBER_MAX = 999999999,
    USERNAME_LENGTH = 50,
    GUILD_NAME_LENGTH = 100,
    CHAT_MESSAGE_LENGTH = 500
}

-- Validation schemas for different data types
local VALIDATION_SCHEMAS = {
    USERNAME = {
        type = "string",
        minLength = 3,
        maxLength = MAXIMUM_VALUES.USERNAME_LENGTH,
        pattern = "^[a-zA-Z0-9_]+$",
        sanitize = true
    },
    
    GUILD_NAME = {
        type = "string",
        minLength = 3,
        maxLength = MAXIMUM_VALUES.GUILD_NAME_LENGTH,
        pattern = "^[a-zA-Z0-9\\s_-]+$",
        sanitize = true
    },
    
    CHAT_MESSAGE = {
        type = "string",
        minLength = 1,
        maxLength = MAXIMUM_VALUES.CHAT_MESSAGE_LENGTH,
        sanitize = true
    },
    
    POSITION = {
        type = "Vector3",
        validateRange = true,
        maxDistance = 1000
    },
    
    CASH_AMOUNT = {
        type = "number",
        min = 0,
        max = MAXIMUM_VALUES.NUMBER_MAX,
        allowNegative = false
    },
    
    ABILITY_LEVEL = {
        type = "number",
        min = 0,
        max = 10,
        allowNegative = false,
        allowDecimal = false
    }
}

-- Core validation functions

-- Validate and sanitize string input
function DataValidator.ValidateString(input, schema)
    if type(input) ~= "string" then
        return false, VALIDATION_ERRORS.INVALID_TYPE, "Input must be a string"
    end
    
    local sanitized = input
    
    -- Apply sanitization if required
    if schema and schema.sanitize then
        sanitized = DataValidator.SanitizeString(input)
        if not sanitized then
            return false, VALIDATION_ERRORS.SANITIZATION_FAILED, "String sanitization failed"
        end
    end
    
    -- Check length constraints
    if schema then
        if schema.minLength and #sanitized < schema.minLength then
            return false, VALIDATION_ERRORS.INVALID_LENGTH, "String too short (min: " .. schema.minLength .. ")"
        end
        
        if schema.maxLength and #sanitized > schema.maxLength then
            return false, VALIDATION_ERRORS.INVALID_LENGTH, "String too long (max: " .. schema.maxLength .. ")"
        end
        
        -- Check pattern if specified
        if schema.pattern then
            if not sanitized:match(schema.pattern) then
                return false, VALIDATION_ERRORS.INVALID_FORMAT, "String format invalid"
            end
        end
    end
    
    return true, sanitized
end

-- Validate numeric input
function DataValidator.ValidateNumber(input, schema)
    if type(input) ~= "number" then
        return false, VALIDATION_ERRORS.INVALID_TYPE, "Input must be a number"
    end
    
    -- Check for NaN or infinity
    if input ~= input or math.abs(input) == math.huge then
        return false, VALIDATION_ERRORS.INVALID_CONTENT, "Invalid number value"
    end
    
    if schema then
        -- Check range constraints
        if schema.min and input < schema.min then
            return false, VALIDATION_ERRORS.INVALID_RANGE, "Value too low (min: " .. schema.min .. ")"
        end
        
        if schema.max and input > schema.max then
            return false, VALIDATION_ERRORS.INVALID_RANGE, "Value too high (max: " .. schema.max .. ")"
        end
        
        -- Check for negative numbers if not allowed
        if schema.allowNegative == false and input < 0 then
            return false, VALIDATION_ERRORS.INVALID_RANGE, "Negative values not allowed"
        end
        
        -- Check for decimal numbers if not allowed
        if schema.allowDecimal == false and input ~= math.floor(input) then
            return false, VALIDATION_ERRORS.INVALID_FORMAT, "Decimal values not allowed"
        end
    end
    
    return true, input
end

-- Validate Vector3 input (for positions)
function DataValidator.ValidateVector3(input, schema)
    if typeof(input) ~= "Vector3" then
        return false, VALIDATION_ERRORS.INVALID_TYPE, "Input must be a Vector3"
    end
    
    if schema and schema.validateRange then
        local magnitude = input.Magnitude
        if schema.maxDistance and magnitude > schema.maxDistance then
            return false, VALIDATION_ERRORS.INVALID_RANGE, "Position too far from origin"
        end
    end
    
    return true, input
end

-- Validate table input
function DataValidator.ValidateTable(input, schema)
    if type(input) ~= "table" then
        return false, VALIDATION_ERRORS.INVALID_TYPE, "Input must be a table"
    end
    
    if schema then
        -- Check table size
        local size = 0
        for _ in pairs(input) do
            size = size + 1
            if size > MAXIMUM_VALUES.TABLE_SIZE then
                return false, VALIDATION_ERRORS.INVALID_LENGTH, "Table too large"
            end
        end
        
        -- Check array size if it's an array
        if #input > 0 and #input > MAXIMUM_VALUES.ARRAY_SIZE then
            return false, VALIDATION_ERRORS.INVALID_LENGTH, "Array too large"
        end
        
        -- Validate schema if provided
        if schema.properties then
            for key, expectedType in pairs(schema.properties) do
                if input[key] then
                    local isValid, result, error = DataValidator.Validate(input[key], expectedType)
                    if not isValid then
                        return false, error, "Invalid property '" .. key .. "': " .. result
                    end
                end
            end
        end
    end
    
    return true, input
end

-- Main validation function
function DataValidator.Validate(input, schema)
    if not schema then
        return true, input
    end
    
    -- Handle string validation
    if schema.type == "string" then
        return DataValidator.ValidateString(input, schema)
    end
    
    -- Handle number validation
    if schema.type == "number" then
        return DataValidator.ValidateNumber(input, schema)
    end
    
    -- Handle Vector3 validation
    if schema.type == "Vector3" then
        return DataValidator.ValidateVector3(input, schema)
    end
    
    -- Handle table validation
    if schema.type == "table" then
        return DataValidator.ValidateTable(input, schema)
    end
    
    -- Handle custom type validation
    if schema.validate then
        return schema.validate(input, schema)
    end
    
    return true, input
end

-- String sanitization
function DataValidator.SanitizeString(input)
    if type(input) ~= "string" then
        return nil
    end
    
    local sanitized = input
    
    -- Remove dangerous characters
    sanitized = sanitized:gsub(SANITIZATION_PATTERNS.DANGEROUS_CHARS, "")
    
    -- Remove script injection patterns
    sanitized = sanitized:gsub(SANITIZATION_PATTERNS.SCRIPT_INJECTION, "")
    
    -- Remove HTML tags
    sanitized = sanitized:gsub(SANITIZATION_PATTERNS.HTML_TAGS, "")
    
    -- Remove control characters
    sanitized = sanitized:gsub(SANITIZATION_PATTERNS.CONTROL_CHARS, "")
    
    -- Trim whitespace
    sanitized = sanitized:match("^%s*(.-)%s*$")
    
    return sanitized
end

-- Validate common data types using predefined schemas
function DataValidator.ValidateUsername(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.USERNAME)
end

function DataValidator.ValidateGuildName(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.GUILD_NAME)
end

function DataValidator.ValidateChatMessage(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.CHAT_MESSAGE)
end

function DataValidator.ValidatePosition(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.POSITION)
end

function DataValidator.ValidateCashAmount(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.CASH_AMOUNT)
end

function DataValidator.ValidateAbilityLevel(input)
    return DataValidator.Validate(input, VALIDATION_SCHEMAS.ABILITY_LEVEL)
end

-- Batch validation for multiple inputs
function DataValidator.ValidateBatch(inputs, schemas)
    local results = {}
    local errors = {}
    
    for key, input in pairs(inputs) do
        local schema = schemas[key]
        if schema then
            local isValid, result, error = DataValidator.Validate(input, schema)
            if isValid then
                results[key] = result
            else
                errors[key] = error
            end
        else
            -- No schema provided, pass through
            results[key] = input
        end
    end
    
    if next(errors) then
        return false, errors
    end
    
    return true, results
end

-- Export validation schemas for external use
DataValidator.Schemas = VALIDATION_SCHEMAS
DataValidator.MaximumValues = MAXIMUM_VALUES
DataValidator.ValidationErrors = VALIDATION_ERRORS

return DataValidator
