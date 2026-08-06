-- Shadow battle presentation and Pokémon summary integration.
-- Gen1Recomp does not currently expose public hooks for either screen, so
-- this module uses the mod's declared engine_internals permission.

function installShadowUIRuntime(mod)
  local BattleState = require("src.battle.BattleState")
  local Font = require("src.render.Font")

  BattleState._colosseumShadowUIHooksV1 = {
    shadow = shadow,
    isActiveShadow = isActiveShadow,
  }

  if not BattleState._colosseumShadowUIInstalledV1 then
    BattleState._colosseumShadowUIInstalledV1 = true

    local vanillaEnter = BattleState.enter
    if type(vanillaEnter) == "function" then
      BattleState.enter = function(self, ...)
        local results = { vanillaEnter(self, ...) }
        local hooks = BattleState._colosseumShadowUIHooksV1
        local enemyMon = self.enemy and self.enemy.mon
        if self.colosseumShadowBattle
           and hooks and hooks.isActiveShadow(enemyMon)
           and not self._colosseumShadowRevealQueued then
          self._colosseumShadowRevealQueued = true
          self:act(function()
            self._colosseumShadowRevealActive = true
          end)
          table.insert(self.queue, { wait = 48 })
          self:say("RUI: That POKéMON...\nIt has a dark aura!\f"
            .. "It's a SHADOW POKéMON!")
          self:act(function()
            self._colosseumShadowRevealActive = false
          end)
        end
        return unpack(results)
      end
    end

    local vanillaDrawTextArea = BattleState.drawTextArea
    if type(vanillaDrawTextArea) == "function" then
      BattleState.drawTextArea = function(self, ...)
        local results = { vanillaDrawTextArea(self, ...) }
        if not (love and love.graphics) then return unpack(results) end

        local hooks = BattleState._colosseumShadowUIHooksV1
        if not hooks then return unpack(results) end
        local enemyShadow = self.enemy and hooks.isActiveShadow(self.enemy.mon)
        local playerShadow = self.player and hooks.isActiveShadow(self.player.mon)
        if not enemyShadow and not playerShadow then return unpack(results) end

        local width = 160
        if type(self.uiSize) == "function" then width = select(1, self:uiSize()) or 160 end

        local function badge(x, y)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.rectangle("fill", x, y, 56, 10)
          love.graphics.setColor(0, 0, 0, 1)
          love.graphics.rectangle("line", x, y, 56, 10)
          Font.draw("SHADOW", x + 4, y + 1)
        end

        if enemyShadow then badge(width - 57, 0) end
        if playerShadow then badge(0, 86) end

        if enemyShadow and self._colosseumShadowRevealActive then
          local frame = self.waitFrames or 0
          local cx, cy = width - 32, 40
          love.graphics.setColor(0, 0, 0, 1)
          for i = 0, 9 do
            local angle = (i / 10) * math.pi * 2 + frame * 0.18
            local radius = 20 + ((frame + i * 5) % 14)
            local x = math.floor(cx + math.cos(angle) * radius)
            local y = math.floor(cy + math.sin(angle) * (radius * 0.72))
            local size = 1 + ((i + frame) % 3)
            love.graphics.rectangle("fill", x, y, size, size)
          end
          local pulse = 2 + (frame % 8)
          love.graphics.rectangle("line", cx - 22 - pulse / 2,
            cy - 22 - pulse / 2, 44 + pulse, 44 + pulse)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.rectangle("fill", width - 82, 69, 82, 10)
          love.graphics.setColor(0, 0, 0, 1)
          Font.draw("DARK AURA!", width - 80, 70)
        end

        love.graphics.setColor(1, 1, 1, 1)
        return unpack(results)
      end
    end
  end

  local ok, SummaryMenu = pcall(require, "src.ui.SummaryMenu")
  if not ok or type(SummaryMenu) ~= "table" then return end

  SummaryMenu._colosseumShadowUIHooksV1 = {
    shadow = shadow,
    section = section,
    natureVisible = natureVisible,
    unlockedNormalMoves = unlockedNormalMoves,
  }

  if SummaryMenu._colosseumShadowUIInstalledV1 then return end
  SummaryMenu._colosseumShadowUIInstalledV1 = true

  local vanillaUpdate = SummaryMenu.update
  SummaryMenu.update = function(self, dt)
    local hooks = SummaryMenu._colosseumShadowUIHooksV1
    local state = hooks and hooks.shadow(self.mon)
    if not state then return vanillaUpdate(self, dt) end

    local input = self.game.input
    if input:wasPressed("a") or input:wasPressed("b") then
      if self.page == 1 then
        self.page = 2
      elseif self.page == 2 then
        self.page = 3
      else
        self.game.stack:pop()
      end
    end
  end

  local vanillaDraw = SummaryMenu.draw
  SummaryMenu.draw = function(self)
    local hooks = SummaryMenu._colosseumShadowUIHooksV1
    local state = hooks and hooks.shadow(self.mon)
    if not state then return vanillaDraw(self) end

    if self.page ~= 3 then
      vanillaDraw(self)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 8, 64, 56, 9)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("SHADOW", 8, 64)
      love.graphics.setColor(1, 1, 1, 1)
      return
    end

    local mon = self.mon
    local def = self.game.data.pokemon[mon.species]
    local maxHeart = state.heartMax or HEART_MAX
    local heart = math.max(0, math.min(maxHeart, state.heart or maxHeart))
    local closedSections = state.purified and 0 or hooks.section(state)
    local percent = maxHeart > 0 and math.floor(heart * 100 / maxHeart + 0.5) or 0
    local nature = (state.purified or hooks.natureVisible(state))
      and (state.nature or "UNKNOWN") or "????"
    local mode = state.purified and "PURIFIED"
      or (state.hyperMode and "HYPER MODE" or "NORMAL")
    local moveCount = state.purified and 4
      or math.min(4, 1 + hooks.unlockedNormalMoves(state))

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.setColor(0, 0, 0, 1)
    Font.drawBox(0, 0, 20, 18)
    Font.draw("SHADOW DATA", 8, 8)
    Font.draw(mon.nickname or def.name, 8, 24)
    Font.draw(state.purified and "PURIFIED" or "ACTIVE", 96, 24)

    Font.draw("HEART GAUGE", 8, 40)
    for i = 1, 5 do
      local x = 8 + (i - 1) * 28
      love.graphics.rectangle("line", x, 52, 24, 9)
      if i <= closedSections then
        love.graphics.rectangle("fill", x + 2, 54, 20, 5)
      end
    end
    Font.draw(("%d%% CLOSED"):format(percent), 8, 64)
    Font.draw(("S%d/5"):format(closedSections), 120, 64)

    Font.draw("NATURE/", 8, 80)
    Font.draw(nature, 80, 80)
    Font.draw("MODE/", 8, 96)
    Font.draw(mode, 80, 96)
    Font.draw("MOVES/", 8, 112)
    Font.draw(("%d/4 UNLOCKED"):format(moveCount), 80, 112)
    Font.draw("EXP/" .. tostring(state.expBank or 0), 8, 128)
    Font.draw(("STEP/%03d"):format(state.stepCounter or 0), 88, 128)

    if not state.purified and heart == 0 then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 56, 8, 96, 9)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("PURIFY READY", 56, 8)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end
