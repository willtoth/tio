-- Decode received text tokens such as 0x12345678 using a CSV map file.
--
-- CSV format:
--   0x12345678,decoded text
--
-- Usage:
--   TIO_TOKEN_MAP=./tokens.csv tio --script-file examples/lua/rx-token-csv-map.lua /dev/ttyUSB0

local map_file = os.getenv("TIO_TOKEN_MAP") or "tokens.csv"
local tokens = {}

for line in io.lines(map_file) do
    local key, value = line:match("^%s*([^,#][^,]*)%s*,%s*(.-)%s*$")
    if key and value then
        tokens[key:lower()] = value
    end
end

local carry = ""

tio.rx_filter(function(data)
    data = carry .. data
    carry = ""

    local partial = data:match("(0[xX]%x*)$") or data:match("(0[xX]?)$")
    if partial and #partial < 10 then
        carry = partial
        data = data:sub(1, #data - #carry)
    end

    return (data:gsub("0[xX]%x%x%x%x%x%x%x%x", function(token)
        return tokens[token:lower()] or token
    end))
end)
