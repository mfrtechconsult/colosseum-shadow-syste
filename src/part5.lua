function installBattleRuntime(mod)
  local BattleState = require("src.battle.BattleState")
  BattleState._colosseumShadowModV1 = mod
  if BattleState._colosseumShadowSystemV1 then return end
  BattleState._colosseumShadowSystemV1 = true
  local function liveMod()
    return BattleState._colosseumShadowModV1 or mod
  end

  local Runtime = require("src.mods.Runtime")
  local Strings = require("src.core.Strings")
  local TextBox = require("src.render.TextBox")

  local vanillaNewTrainer = BattleState.newTrainer
  BattleState.newTrainer = function(game, oppClass, partyIndex)
    local battle = vanillaNewTrainer(game, oppClass, partyIndex)
    if oppClass ~= TRAINER_ID then return battle end

    battle.colosseumShadowBattle = true
    battle.colosseumShadowId = SHADOW_ID
    local mon = battle.enemy and battle.enemy.mon
    local snapshot = liveMod().save:get("encounter_snapshot")
    if snapshot and mon then
      local restored = copy(snapshot)
      for k in pairs(mon) do mon[k] = nil end
      for k, v in pairs(restored) do mon[k] = v end
    elseif mon then
      attachShadow(mon, game.data)
      liveMod().save:set("encounter_snapshot", copy(mon))
    end

    if mon then
      attachShadow(mon, game.data)
      battle.enemyParty[1] = mon
      battle.enemy.mon = mon
      battle.enemy.curMoves = mon.moves
      battle.enemy.curStats = copy(mon.stats)
      battle.enemy.curTypes = copy(game.data.pokemon[mon.species].types)
    end
    return battle
  end

  local vanillaThrowBall = BattleState.throwBall
  BattleState.throwBall = function(self, ball)
    local target = self.enemy and self.enemy.mon
    if not (self.colosseumShadowBattle and isActiveShadow(target)) then
      return vanillaThrowBall(self, ball)
    end
    if not liveMod().save:get("snag_machine", false) then
      return vanillaThrowBall(self, ball)
    end

    local item = self.data.items[ball]
    self:sayAuto(Strings("%s used\n%s!", self.game.save.player.name,
      item and item.name or ball))
    self:act(function()
      require("src.core.Sound").play(self.data, "Ball_Toss")
      self:sayNext("The SNAG MACHINE\nconverted the BALL!")
      self.lastBall = ball
      local caught, shakes = self:catchAttempt(ball)
      Runtime.emit("battle.ball_thrown", {
        battle = self, ball = ball, caught = caught, shakes = shakes,
        snag = true,
      })
      self.nextInsert = (self.nextInsert or 0) + 1
      table.insert(self.queue, self.nextInsert, { wait = 20 })
      self:ballChain(self:tossAnimFor(ball), caught, shakes, ball)
      if caught then
        self:actNext(function()
          require("src.core.Sound").play(self.data, "Caught_Mon")
        end)
        self:sayNext(Strings("All right!\n%s was SNAGGED!", self.enemy.name))
        self:act(function() self:storeCaughtMon() end)
      else
        self:sayNext(self:ballMissMessage(shakes))
        self:act(function()
          self:executeAction(self.enemy, self.player, self:enemyAction())
        end)
        self:queueResidual(self.player, self.enemy)
        self:act(function() self:endOfTurn() end)
      end
    end)
  end

  local vanillaStoreCaught = BattleState.storeCaughtMon
  BattleState.storeCaughtMon = function(self)
    local snagged = self.colosseumShadowBattle
      and self.enemy and isActiveShadow(self.enemy.mon)
    if snagged then
      liveMod().save:set("encounter_status", "snagged")
      liveMod().save:set("encounter_snapshot", false)
    end
    return vanillaStoreCaught(self)
  end

  local vanillaApplyDamage = BattleState.applyDamage
  BattleState.applyDamage = function(self, target, damage)
    local dealt = vanillaApplyDamage(self, target, damage)
    local context = self._colosseumShadowRush
    if context and target == context.target and type(dealt) == "number" then
      context.dealt = context.dealt + dealt
    end
    return dealt
  end

  local vanillaPerformMove = BattleState.performMove
  BattleState.performMove = function(self, user, target, moveInst, isCalled)
    local state = user and shadow(user.mon)
    local moveId = moveInst and moveInst.id

    if moveId ~= SHADOW_MOVE then
      return vanillaPerformMove(self, user, target, moveInst, isCalled)
    end

    if user and user.isPlayer and state and state.isShadow
       and not state.hyperMode and not isCalled
       and self.rng(0, 9999) < math.floor(hyperRate(state) * 10000) then
      state.hyperMode = true
      self:sayNext(monName(self.game, user.mon) .. " entered\nHYPER MODE!")
      return
    end

    local oldPP = moveInst.pp
    local context = { user = user, target = target, dealt = 0 }
    self._colosseumShadowRush = context
    local results = { vanillaPerformMove(self, user, target, moveInst, isCalled) }
    self._colosseumShadowRush = nil
    moveInst.pp = oldPP

    if context.dealt > 0 and user and user.mon.hp > 0 then
      local recoil = math.max(1,
        math.floor(user.mon.stats.hp / 16) + self.rng(-1, 1))
      self:sayNext(monName(self.game, user.mon) .. " is hit\nwith recoil!")
      self:actNext(function()
        vanillaApplyDamage(self, user, recoil)
        if user.mon.hp <= 0 then self:onFaint(user) end
      end)
    end
    return unpack(results)
  end

  local vanillaAskNickname = BattleState.askNicknameUI
  BattleState.askNicknameUI = function(self, mon, displayName)
    if isActiveShadow(mon) then
      self.lockedBall = nil
      self.blankForAskName = true
      return TextBox.new(self.game,
        "A SHADOW POKéMON\ncan't be nicknamed\nuntil purification.",
        function() self.blankForAskName = false end)
    end
    return vanillaAskNickname(self, mon, displayName)
  end
end
