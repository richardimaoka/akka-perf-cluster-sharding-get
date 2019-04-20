-- https://stackoverflow.com/questions/11201262/how-to-read-data-from-a-file-in-lua

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

local lines = lines_from("../../data/uuids.txt")
requests = {}
for i=1, #lines do
  requests[i] = wrk.format(
    "GET",
    lines[i]
  )
end

-- Initialize the requests array iterator
counter = 1

request = function()
  -- Increment the counter
  counter = counter + 1

  -- If the counter is longer than the requests array length then reset it
  if counter > #requests then
    counter = 1
  end

  -- Return the request object with the current URL path
  return requests[counter]
end