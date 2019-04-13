-- http://czerasz.com/2015/07/19/wrk-http-benchmarking-tool-example/

-- Module instantiation
local cjson = require "cjson"

-- Load URL paths from the file
function load_request_objects_from_file(file)
  local content

  -- Check if the file exists
  -- Resource: http://stackoverflow.com/a/4991602/325852
  local f=io.open(file,"r")
  if f~=nil then
    content = f:read("*all")

    io.close(f)
  else
    -- Return the empty array
    return lines
  end

  -- Translate Lua value to/from JSON
  local data = cjson.decode(content)

  return data
end

-- Load URL requests from file
request_data = load_request_objects_from_file("requests.json")

-- Check if at least one path was found in the file
if #request_data <= 0 then
  print("No requests found in the file.")
  os.exit()
end

print("multiple requests: Found " .. #requests .. " requests")

requests = {}
for i=1, #request_data do
  requests[i] = wrk.format(
    request_data.method,
    request_data.path
    -- request_data.headers,
    -- request_data.body
  )
end

-- Initialize the requests array iterator
counter = 1

request = function()
  -- Get the next requests array element
  local requests = requests[counter]

  -- Increment the counter
  counter = counter + 1

  -- If the counter is longer than the requests array length then reset it
  if counter > #requests then
    counter = 1
  end

  -- Return the request object with the current URL path
  return requests[i]
end