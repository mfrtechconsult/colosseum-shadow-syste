local path = assert(arg[1], "Lua file path required")
local chunk, err = loadfile(path)
if not chunk then error(err) end
print(path .. " syntax OK")
