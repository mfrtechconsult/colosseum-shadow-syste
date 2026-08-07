-- Purification ceremony presentation (v1.4.0).
--
-- Gen1Recomp has no Relic Stone movie, so this state deliberately borrows the
-- visual language of its evolution movie: isolated full-screen Pokémon sprite,
-- accelerating flashes, dedicated music, then the normal-colored Pokémon and
-- its cry. The actual Shadow-state mutation occurs at the climax, never before.

local function purificationFrontSprite(game, mon)
  if not (love and love.graphics) then return nil, false end
  local path, trueColor = require("src.pokemon.Sprites").path(
    game.data, mon.species, "front", { mon = mon, kind = "purification" })
  if not path then return nil, false end
  local ok, img = pcall(love.graphics.newImage, path)
  return ok and img or nil, ok and trueColor or false
end

local PurificationState = {}
PurificationState.__index = PurificationState
PurificationState.isOpaque = true
PurificationState.letterboxWhite = true
PurificationState.holdsUIAnchors = true

local OPEN_FRAMES = 168
local SETTLE_FRAMES = 48

function PurificationState.new(game, mon, onDone)
  local self = setmetatable({}, PurificationState)
  self.game = game
  self.mon = mon
  self.onDone = onDone
  self.name = monName(game, mon)
  self.sprite, self.trueColor = purificationFrontSprite(game, mon)
  self.t = 0
  self.purified = false
  self.result = nil
  require("src.core.Music").play(
    game.data, require("src.core.Music").special(game.data, "evolution"))
  return self
end

function PurificationState:sgbPalettes(game)
  local PaletteFX = require("src.render.PaletteFX")
  if not self.purified then
    local black = PaletteFX.pal(game.data, "BLACK")
    if black then return { PaletteFX.whole(black) } end
  end
  local colors = PaletteFX.monPal(game.data, self.mon.species)
  if colors then return { PaletteFX.whole(colors) } end
  return PaletteFX.wholeNamed(game.data, "MEWMON")
end

function PurificationState:update(dt)
  self.t = self.t + 1
  if not self.purified and self.t >= OPEN_FRAMES then
    self.purified = true
    local ok, bank, oldLevel = purify(self.game, self.mon)
    self.result = { ok, bank, oldLevel }
    if ok then
      require("src.core.Sound").playCry(self.game.data, self.mon.species)
    end
  end

  if self.purified and self.t >= OPEN_FRAMES + SETTLE_FRAMES then
    local result = self.result or { false }
    require("src.core.Music").restoreMap(self.game.data)
    self.game.stack:pop()
    if self.onDone then self.onDone(unpack(result)) end
  end
end

function PurificationState:draw()
  local Font = require("src.render.Font")
  local g = love.graphics
  g.setColor(1, 1, 1, 1)
  g.rectangle("fill", 0, 0, 160, 144)

  local cx, cy = 80, 58
  if not self.purified then
    -- Rings contract toward the Pokémon while the flashes accelerate. The
    -- geometry uses only primitives, so no copyrighted/new art is required.
    local progress = math.min(1, self.t / OPEN_FRAMES)
    local phase = self.t * (0.10 + progress * 0.18)
    g.setColor(0, 0, 0, 1)
    for i = 0, 3 do
      local cycle = (progress * 1.7 + i / 4) % 1
      local radius = math.max(5, math.floor(46 * (1 - cycle)))
      g.rectangle("line", cx - radius, cy - radius,
        radius * 2, radius * 2)
    end
    for i = 0, 7 do
      local a = phase + i * math.pi / 4
      local r = 18 + ((self.t + i * 7) % 20)
      g.rectangle("fill", math.floor(cx + math.cos(a) * r),
        math.floor(cy + math.sin(a) * r * 0.70), 2, 2)
    end
  end

  if self.sprite then
    local pulse = self.purified and 1 or (1 + 0.06 * math.sin(self.t * 0.22))
    local w, h = self.sprite:getDimensions()
    local x = cx - (w * pulse) / 2
    local y = cy - (h * pulse) / 2
    if not self.purified and (math.floor(self.t / math.max(3, 14 - math.floor(self.t / 18))) % 2 == 1) then
      g.setColor(0.15, 0.15, 0.15, 1)
    else
      g.setColor(1, 1, 1, 1)
    end
    g.draw(self.sprite, x, y, 0, pulse, pulse)
    if self.trueColor then
      require("src.render.PaletteFX").markTrueColor(x, y, w * pulse, h * pulse)
    end
  end

  g.setColor(0, 0, 0, 1)
  if self.purified then
    Font.draw(self.name, 8, 108)
    Font.draw("opened the door", 8, 118)
    Font.draw("to its heart!", 8, 128)
  else
    Font.draw("The door to", 8, 108)
    Font.draw(self.name .. "'s heart", 8, 118)
    Font.draw("is opening...", 8, 128)
  end
  g.setColor(1, 1, 1, 1)
end

function startPurificationAnimation(game, mon, onDone)
  if not (game and game.stack and love and love.graphics) then
    local ok, bank, oldLevel = purify(game, mon)
    if onDone then onDone(ok, bank, oldLevel) end
    return false
  end
  game.stack:push(PurificationState.new(game, mon, onDone))
  return true
end

-- Exposed only for headless regression tests.
COLOSSEUM_PURIFICATION_STATE_V14 = PurificationState
