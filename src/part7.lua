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

  -- A Shadow badge belongs to the currently drawn Pokémon sprite, never to
  -- the trainer/back portrait that temporarily occupies the same battle slot.
  BattleState._colosseumShadowBadgeVisibleV1 = function(self, battler, side)
    local hooks = BattleState._colosseumShadowUIHooksV1
    if not battler or not battler.mon or battler.fainted
       or not hooks or not hooks.isActiveShadow(battler.mon) then
      return false
    end

    if side == "enemy" then
      if self.showEnemyTrainer or self.enemySendingOut or self.enemyHidden then
        return false
      end
    else
      if self.showPlayerBack or self.sendingOut or self.safari or self.demo then
        return false
      end
    end

    if type(self.growInScale) == "function" and self:growInScale(battler) then
      return false
    end
    if type(self.fxHidden) == "function" and self:fxHidden(battler) then
      return false
    end
    return true
  end

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
        local badgeVisible = BattleState._colosseumShadowBadgeVisibleV1
        local enemyShadow = badgeVisible
          and badgeVisible(self, self.enemy, "enemy") or false
        local playerShadow = badgeVisible
          and badgeVisible(self, self.player, "player") or false
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
    isActiveShadow = isActiveShadow,
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
    if not (state and hooks.isActiveShadow(self.mon)) then
      if (self.page or 1) > 2 then self.page = 2 end
      return vanillaUpdate(self, dt)
    end

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
    if not (state and hooks.isActiveShadow(self.mon)) then
      return vanillaDraw(self)
    end

    if self.page ~= 3 then
      vanillaDraw(self)

      -- Colosseum keeps all four move slots visible. Locked normal moves are
      -- shown as ???? with unknown PP instead of disappearing from the list.
      if self.page == 2 and state.isShadow then
        -- Shadow Rush has no usable PP counter in Colosseum.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 104, 80, 48, 8)
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw("--/--", 112, 80)

        local firstLocked = 2 + hooks.unlockedNormalMoves(state)
        for i = firstLocked, 4 do
          local y = 72 + (i - 1) * 16
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.rectangle("fill", 8, y, 144, 16)
          love.graphics.setColor(0, 0, 0, 1)
          Font.draw("????", 16, y)
          Font.draw("PP", 88, y + 8)
          Font.draw("??/??", 112, y + 8)
        end
      end

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 8, 64, 56, 9)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("SHADOW", 8, 64)
      love.graphics.setColor(1, 1, 1, 1)
      return
    end

    local mon = self.mon
    local def = self.game.data.pokemon[mon.species]
    local closedSections = hooks.section(state)
    local nature = hooks.natureVisible(state)
      and (state.nature or "UNKNOWN") or "????"
    local mode = state.hyperMode and "HYPER MODE" or "NORMAL"
    local expState = hooks.natureVisible(state)
      and (((state.expBank or 0) > 0) and "STORING" or "READY") or "LOCKED"

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.setColor(0, 0, 0, 1)
    Font.drawBox(0, 0, 20, 18)
    Font.draw("SHADOW DATA", 8, 8)
    Font.draw(mon.nickname or def.name, 8, 24)
    Font.draw("ACTIVE", 104, 24)

    Font.draw("HEART GAUGE", 8, 40)
    for i = 1, 5 do
      local x = 8 + (i - 1) * 28
      love.graphics.rectangle("line", x, 52, 24, 9)
      if i <= closedSections then
        love.graphics.rectangle("fill", x + 2, 54, 20, 5)
      end
    end

    Font.draw(heartMessage(state), 8, 64)
    Font.draw("NATURE/", 8, 88)
    Font.draw(nature, 80, 88)
    Font.draw("MODE/", 8, 104)
    Font.draw(mode, 80, 104)
    Font.draw("EXP/", 8, 120)
    Font.draw(expState, 80, 120)

    if (state.heart or 0) == 0 then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 56, 8, 96, 9)
      love.graphics.setColor(0, 0, 0, 1)
      Font.draw("PURIFY READY", 56, 8)
    end
    love.graphics.setColor(1, 1, 1, 1)
  end
end
