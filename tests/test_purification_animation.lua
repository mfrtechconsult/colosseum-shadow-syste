-- Headless contract test for the purification ceremony bridge.
-- The graphical state itself is validated in-game; this verifies that the
-- fallback path performs purification exactly once and reports its result.

local calls = 0
local env = setmetatable({
  love = nil,
  monName = function() return "PIKACHU" end,
  purify = function(game, mon)
    calls = calls + 1
    mon.colosseumShadow.isShadow = false
    mon.colosseumShadow.purified = true
    return true, 1234, 15
  end,
}, { __index = _G })

local chunk
if setfenv then
  chunk = assert(loadfile("src/part10.lua"))
  setfenv(chunk, env)
else
  chunk = assert(loadfile("src/part10.lua", "t", env))
end
chunk()

assert(type(env.COLOSSEUM_PURIFICATION_STATE_V14) == "table",
  "purification animation state missing")

local mon = {
  colosseumShadow = { version = 1, isShadow = true, purified = false },
}
local reported
local asynchronous = env.startPurificationAnimation(
  { stack = {} }, mon,
  function(ok, bank, oldLevel) reported = { ok, bank, oldLevel } end)

assert(asynchronous == false, "headless purification must use the fallback path")
assert(calls == 1, "headless fallback must purify exactly once")
assert(reported and reported[1] == true and reported[2] == 1234
       and reported[3] == 15,
  "purification result must be forwarded to the command")
assert(mon.colosseumShadow.purified and not mon.colosseumShadow.isShadow,
  "purification state transition missing")

print("Purification animation bridge test passed.")
