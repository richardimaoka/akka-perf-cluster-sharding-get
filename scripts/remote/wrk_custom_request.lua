-- https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end

-- Initialize the requests array iterator
requests = {}
function init(args)
  print("Trying to read uuids from " .. args[1])
  local lines = lines_from(args[1])
  print(#lines .. " uuids are read")

  for i=1, #lines do
    local url = args[0] .. "/actors/" .. lines[i]
    table.insert(requests, wrk.format("GET", url))
  end
end

counter = 1
function request()
  -- Increment the counter
  counter = counter + 1

  -- If the counter is longer than the requests array length then reset it
  if counter > #requests then
    counter = 1
  end

  -- Return the request object with the current URL path
  return requests[counter]
end

function done(summary, latency, requests)
  print("done!")
end