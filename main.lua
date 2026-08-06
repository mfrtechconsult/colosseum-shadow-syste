-- Loader for the split Shadow-system implementation.
-- Each part executes inside one private environment, preserving the original
-- top-level state without leaking globals into Gen1Recomp.

local PARTS = {
  "src/part1.lua", "src/part2.lua", "src/part3.lua",
  "src/part4.lua", "src/part5.lua", "src/part6.lua",
}

local function readPart(mod, path)
  local full = ((mod and mod.path) and (mod.path .. "/" .. path)) or path
  if love and love.filesystem then
    local ok, data = pcall(love.filesystem.read, full)
    if ok and type(data) == "string" then return data end
  end
  local file, err = io.open(full, "rb")
  assert(file, err or ("cannot open " .. full))
  local data = file:read("*a")
  file:close()
  return data
end

local function compile(code, name, env)
  if loadstring and setfenv then
    local chunk, err = loadstring(code, name)
    assert(chunk, err)
    setfenv(chunk, env)
    return chunk
  end
  local chunk, err = load(code, name, "t", env)
  assert(chunk, err)
  return chunk
end

return function(mod)
  local env = setmetatable({}, { __index = _G })
  local entry
  for _, path in ipairs(PARTS) do
    local result = compile(readPart(mod, path), "@" .. path, env)()
    if result ~= nil then entry = result end
  end
  assert(type(entry) == "function", "Shadow-system entry function missing")
  return entry(mod)
end
