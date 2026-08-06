-- Standalone test for the post-purification summary lifecycle.

local SummaryMenu = {
  update = function(self)
    if self.game.input:wasPressed("a") then
      if self.page == 1 then self.page = 2 else self.game.stack:pop() end
    end
  end,
  draw = function(self)
    self.rendererSawShadowRecord = self.mon.colosseumShadow ~= nil
  end,
}

package.preload["src.ui.SummaryMenu"] = function() return SummaryMenu end

local env = setmetatable({
  shadow = function(mon)
    local state = mon and mon.colosseumShadow
    if type(state) == "table" and state.version == 1 then return state end
  end,
}, { __index = _G })

local chunk
if setfenv then
  chunk = assert(loadfile("src/part8.lua"))
  setfenv(chunk, env)
else
  chunk = assert(loadfile("src/part8.lua", "t", env))
end
chunk()

assert(SummaryMenu._colosseumPurifiedSummaryV1,
  "purified summary lifecycle was not installed")

local purifiedState = {
  version = 1, isShadow = false, purified = true, nationalRibbon = true,
}
local purified = { colosseumShadow = purifiedState }
local popped = false
local summary = {
  mon = purified,
  page = 3,
  game = {
    input = { wasPressed = function(_, key) return key == "a" end },
    stack = { pop = function() popped = true end },
  },
}

SummaryMenu.draw(summary)
assert(summary.rendererSawShadowRecord == false,
  "purified Pokémon must use the ordinary summary renderer")
assert(purified.colosseumShadow == purifiedState,
  "purification history must be restored after drawing")

SummaryMenu.update(summary, 0)
assert(summary.page == 2 and popped,
  "purified Pokémon summary must close after page two")
assert(purified.colosseumShadow == purifiedState,
  "purification history must be restored after updating")

local activeState = { version = 1, isShadow = true, purified = false }
local active = { colosseumShadow = activeState }
local activeSummary = {
  mon = active,
  page = 1,
  game = {
    input = { wasPressed = function() return false end },
    stack = { pop = function() end },
  },
}
SummaryMenu.draw(activeSummary)
assert(activeSummary.rendererSawShadowRecord == true,
  "active Shadow Pokémon must retain its Shadow summary path")

print("Purified summary lifecycle test passed.")
