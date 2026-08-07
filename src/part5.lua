-- Generic trainer -> Shadow encounter registry. The original Pallet demo is
-- kept as the first entry so v1.6 behavior remains unchanged.
SHADOW_TRAINER_ENCOUNTERS = {
  [TRAINER_ID] = {
    partySlot = 0, -- canonical/adapter API is zero-based
    shadowId = SHADOW_ID,
    persistSnapshot = true,
    snapshotKey = "encounter_snapshot",
    statusKey = "encounter_status",
  },
}

SNAG_ACCESS_CHECK = nil

function registerShadowTrainerEncounter(trainerId, config)
  assert(type(trainerId) == "string" and trainerId ~= "",
    "Shadow trainer encounter requires a trainer id")
  assert(type(config) == "table",
    "Shadow trainer encounter requires a config table")
  local row = copy(config)
  row.partySlot = math.max(0, math.floor(row.partySlot or 0))
  row.shadowId = row.shadowId or ("SHADOW_" .. trainerId)
  SHADOW_TRAINER_ENCOUNTERS[trainerId] = row
  return row
end

function unregisterShadowTrainerEncounter(trainerId)
  local old = SHADOW_TRAINER_ENCOUNTERS[trainerId]
  SHADOW_TRAINER_ENCOUNTERS[trainerId] = nil
  return old
end

function shadowTrainerEncounter(trainerId)
  return SHADOW_TRAINER_ENCOUNTERS[trainerId]
end

function setSnagAccessCheck(fn)
  assert(fn == nil or type(fn) == "function",
    "Snag access check must be a function or nil")
  SNAG_ACCESS_CHECK = fn
end

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

  local function snagAccessAllowed(battle)
    if type(SNAG_ACCESS_CHECK) == "function" then
      local ok, allowed = pcall(SNAG_ACCESS_CHECK, battle)
      return ok and allowed == true
    end
    -- Backwards-compatible default for the bundled Pallet demonstration.
    return liveMod().save:get("snag_machine", false) == true
  end

  local vanillaNewTrainer = BattleState.newTrainer
  BattleState.newTrainer = function(game, oppClass, partyIndex)
    local battle = vanillaNewTrainer(game, oppClass, partyIndex)
    local encounter = shadowTrainerEncounter(oppClass)
    if not encounter then return battle end

    local slot = math.max(0, math.floor(encounter.partySlot or 0)) + 1
    local mon = battle.enemyParty and battle.enemyParty[slot]
    if not mon then
      -- Invalid adapter data should not corrupt an otherwise valid battle.
      battle.colosseumShadowEncounterError =
        "Shadow party slot " .. tostring(encounter.partySlot) ..
        " missing for " .. tostring(oppClass)
      return battle
    end

    battle.colosseumShadowBattle = true
    battle.colosseumShadowId = encounter.shadowId
    battle.colosseumShadowEncounter = encounter
    battle.colosseumShadowPartySlot = slot

    local restored
    if encounter.persistSnapshot then
      restored = liveMod().save:get(encounter.snapshotKey or "encounter_snapshot")
    end
    if restored then
      restored = copy(restored)
      for k in pairs(mon) do mon[k] = nil end
      for k, v in pairs(restored) do mon[k] = v end
    else
      attachShadow(mon, game.data, encounter)
      if encounter.persistSnapshot then
        liveMod().save:set(encounter.snapshotKey or "encounter_snapshot", copy(mon))
      end
    end

    -- Ensure legacy snapshots receive the current encounter configuration.
    attachShadow(mon, game.data, encounter)
    battle.enemyParty[slot] = mon

    -- If the Shadow is already the active battler, refresh its battle cache.
    if battle.enemy and battle.enemy.mon == mon then
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
    if not snagAccessAllowed(self) then
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
    local mon = self.enemy and self.enemy.mon
    local state = mon and shadow(mon)
    local snagged = self.colosseumShadowBattle and state and state.isShadow
    local encounter = self.colosseumShadowEncounter

    if snagged and encounter and encounter.persistSnapshot then
      liveMod().save:set(encounter.statusKey or "encounter_status", "snagged")
      liveMod().save:set(encounter.snapshotKey or "encounter_snapshot", false)
    end

    local results = { vanillaStoreCaught(self) }
    if snagged then
      Runtime.emit("shadow.snagged", {
        battle = self,
        mon = mon,
        shadowId = state.shadowId,
        trainerId = self.opponentClass,
        partySlot = self.colosseumShadowPartySlot
          and (self.colosseumShadowPartySlot - 1) or nil,
      })
    end
    return unpack(results)
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
    local shadowMove = (state and state.shadowMove) or SHADOW_MOVE

    if moveId ~= shadowMove then
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
