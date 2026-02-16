local cjson = require("cjson") -- Or "cjson" depending on your setup

local function read_json_file(path)
    -- Open file in read mode
    local file, err = io.open(path, "r")
    if not file then
        return nil, "Could not open file: " .. err
    end

    -- Read the entire content
    local content = file:read("*a")
    file:close()

    return content
end

local function processOld()
    -- Process trigger function strings for optimal j.php performance
    local function processTriggerFunctionStrings(input_data, shouldDecode)
        local trigger_data
    
        if shouldDecode then
            -- Live mode: input_data is full JSON string, need to decode and extract dsl
            local decoded_value = cjson.decode(input_data)
            if not decoded_value.dsl then
                return input_data -- Return original if no dsl field
            end
            trigger_data = decoded_value.dsl
        else
            -- Preview mode: input_data is already the dsl string
            trigger_data = input_data
        end
    
        -- Check if trigger contains "cnds" - if yes, skip processing
        if trigger_data:find("cnds", 1, true) then
            return trigger_data
        end
    
        -- Check if trigger has function string
        local has_fn = trigger_data:find('"fn":"function', 1, true)
        if not has_fn then
            return trigger_data
        end
    
        -- -- Convert function strings for maximum j.php performance
        -- local processed_trigger = trigger_data:gsub('"fn":"(function%(evl%).*})"', function(fn_content)
        --     return '"fn":' .. fn_content:gsub('\\"', '"')
        -- end)
    
        -- Convert function strings for maximum j.php performance
        local processed_trigger = trigger_data:gsub('"fn":"(function%(evl%)%s*{[^}]*evl[^}]*})"', function(fn_content)
            return '"fn":' .. fn_content:gsub('\\"', '"')
        end)
    
        return processed_trigger
    end

    -- Example Usage:
    local my_data, err = read_json_file("test.txt")

    print(cjson.encode({ dsl=processTriggerFunctionStrings(my_data, true)}))
end

local function processNew()
    -- Helper function to process function strings and convert fn field to raw JavaScript
    -- Takes data (string or table), decodes if needed, and processes fn field
    -- This is the core logic extracted from processTriggerFunctionStrings
    local function processFunctionStrings(data)
        if not data then
            return data
        end
    
        -- Try to decode if it's a string
        local decoded = data
        if type(data) == "string" then
            local ok, result = pcall(cjson.decode, data)
            if not ok or not result then
                -- Decoding failed, return as-is
                return data
            end
            decoded = result
        end
    
        -- If decoded is not a table, return as-is
        if type(decoded) ~= "table" then
            return data
        end
    
        -- Process the table: if it has "fn" key, encode it as raw JavaScript
        local hasFn = false
        local parts = {}
        for key, val in pairs(decoded) do
                print(val)
            if key == "fn" then
                hasFn = true
                -- fn should be raw JavaScript, not JSON-encoded
                parts[#parts + 1] = string.format('"%s":%s', key, val)
            else
                -- Other fields are JSON-encoded normally
                parts[#parts + 1] = string.format('"%s":%s', key, cjson.encode(val))
            end
        end
    
        if hasFn and #parts > 0 then
            -- Return manually built JSON string with fn as raw JavaScript
            return "{" .. table.concat(parts, ",") .. "}"
        else
            -- No fn field, return encoded normally
            return cjson.encode(decoded)
        end
    end

    -- Helper function to process trigger data and convert fn field to raw JavaScript
    -- Takes trigger data (string or table), decodes if needed, and processes fn field
    local function processTriggerFunctionStrings(triggerData, shouldDecode)
        if not triggerData then
            return triggerData
        end
    
        if shouldDecode then
            -- Live mode: input_data is full JSON string, need to decode and extract dsl
            local decoded_value = cjson.decode(triggerData)
            if not decoded_value.dsl then
                return triggerData -- Return original if no dsl field
            end
            triggerData = decoded_value.dsl
        else
            -- Preview mode: input_data is already the dsl string
            triggerData = triggerData
        end
    
        -- Use the core processFunctionStrings logic
        return processFunctionStrings(triggerData)
    end

    -- cjson.decode_max_depth(1)
    local my_data, err = read_json_file("test.txt")
    print(cjson.decode(my_data).fn)

    -- print(cjson.encode({ dsl=processTriggerFunctionStrings(my_data, true)}))
end

-- processOld()
processNew()

-- print(my_data.dsl)
-- if err then
--     print("Error:", err)
-- else
--     -- Accessing your data
--     print("Survey Type: " .. (my_data.questions or "N/A"))
-- end

-- json.decode(my_data)


-- local cjson = require("cjson")

-- local json = [[
-- {
--   "pattern": ^https?\\:\\\/\\\/(w{3}\\.)?testdata\\.wingified\\.com\\\/sync\\\/analyse\\.html\\\/?\\?id\\=4000687&test\\=CoalGoal(?:#.*)?$
-- }
-- ]]

-- local data = cjson.decode(json)

-- print(data.pattern)
