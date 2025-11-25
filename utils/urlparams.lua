
local url = {}

function url.parse_query(uri)
    -- extract the part after "?"
    local query = uri:match("%?(.*)")
    if not query then
        return {} -- no params
    end

    local params = {}

    for key, value in query:gmatch("([^&=?]+)=([^&=?]+)") do
        -- decode percent encoding if needed
        key = key:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
        value = value:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)

        params[key] = value
    end

    return params
end

return url
