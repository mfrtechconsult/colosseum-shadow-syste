-- Loader for the split Shadow-system implementation.
-- Each part executes inside one private environment, preserving the original
-- top-level state without leaking globals into Gen1Recomp.

local PARTS = {
  "src/part1.lua", "src/part2.lua", "src/part3.lua",
  "src/part4.lua", "src/part5.lua", "src/part6.lua",
  "src/part7.lua", "src/part8.lua", "src/part9.lua",
  "src/part10.lua",
}

local function readPart(mod, path)
  -- Gen1Recomp deliberately abstracts a mod's backing filesystem. In normal
  -- LÖVE play that is love.filesystem; the official SDK test harness mounts
  -- mods through an aliasing filesystem. `mod:read()` is the supported seam
  -- for both, whereas io.open(mod.path/...) bypasses that mount and makes a
  -- perfectly valid mod impossible to load headlessly.
  assert(mod and type(mod.read) == "function",
    "Shadow-system split loader requires Gen1Recomp mod:read()")
  local data = mod:read(path)
  assert(type(data) == "string",
    "cannot read Shadow-system part " .. tostring(path))
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
