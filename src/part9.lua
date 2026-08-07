-- Pokémon Colosseum fidelity pass (v1.3.0).
--
-- The public Gen1Recomp API does not yet expose every battle/menu seam used
-- by Colosseum, so this layer uses the mod's declared engine_internals
-- permission. Verified Colosseum constants are isolated below.

HEART_ACTION_VALUES = {
  HARDY   = { BATTLE=150, CALL=300, PARTY=150, DAYCARE=150, SCENT=100 },
  LONELY  = { BATTLE=50,  CALL=450, PARTY=150, DAYCARE=150, SCENT=200 },
  BRAVE   = { BATTLE=200, CALL=225, PARTY=150, DAYCARE=225, SCENT=75  },
  ADAMANT = { BATTLE=150, CALL=225, PARTY=150, DAYCARE=300, SCENT=75  },
  NAUGHTY = { BATTLE=150, CALL=225, PARTY=200, DAYCARE=225, SCENT=75  },
  BOLD    = { BATTLE=150, CALL=225, PARTY=200, DAYCARE=300, SCENT=50  },
  DOCILE  = { BATTLE=75,  CALL=600, PARTY=100, DAYCARE=225, SCENT=100 },
  RELAXED = { BATTLE=75,  CALL=225, PARTY=75,  DAYCARE=600, SCENT=150 },
  IMPISH  = { BATTLE=200, CALL=300, PARTY=150, DAYCARE=150, SCENT=75  },
  LAX     = { BATTLE=100, CALL=225, PARTY=150, DAYCARE=225, SCENT=150 },
  TIMID   = { BATTLE=50,  CALL=450, PARTY=50,  DAYCARE=600, SCENT=150 },
  HASTY   = { BATTLE=200, CALL=300, PARTY=75,  DAYCARE=150, SCENT=150 },
  SERIOUS = { BATTLE=100, CALL=450, PARTY=100, DAYCARE=300, SCENT=75  },
  JOLLY   = { BATTLE=150, CALL=300, PARTY=100, DAYCARE=150, SCENT=150 },
  NAIVE   = { BATTLE=100, CALL=300, PARTY=150, DAYCARE=225, SCENT=100 },
  MODEST  = { BATTLE=75,  CALL=300, PARTY=75,  DAYCARE=600, SCENT=100 },
  MILD    = { BATTLE=75,  CALL=225, PARTY=75,  DAYCARE=450, SCENT=200 },
  QUIET   = { BATTLE=100, CALL=300, PARTY=100, DAYCARE=300, SCENT=100 },
  BASHFUL = { BATTLE=50,  CALL=300, PARTY=75,  DAYCARE=450, SCENT=200 },
  RASH    = { BATTLE=75,  CALL=300, PARTY=100, DAYCARE=300, SCENT=150 },
  CALM    = { BATTLE=50,  CALL=300, PARTY=100, DAYCARE=450, SCENT=150 },
  GENTLE  = { BATTLE=50,  CALL=300, PARTY=75,  DAYCARE=600, SCENT=150 },
  SASSY   = { BATTLE=200, CALL=150, PARTY=150, DAYCARE=225, SCENT=100 },
  CAREFUL = { BATTLE=75,  CALL=300, PARTY=75,  DAYCARE=450, SCENT=150 },
  QUIRKY  = { BATTLE=200, CALL=225, PARTY=50,  DAYCARE=600, SCENT=75  },
}

local ACTION_ALIASES = {
  BATTLE_ENTRY = "BATTLE",
  WALK_256 = "PARTY",
  VIVID_SCENT = "SCENT",
  NATURAL_RECOVERY = "CALL",
}

function heartActionAmount(state, action, multiplier)
  if not state then return 0 end
  action = ACTION_ALIASES[action] or action
  local row = HEART_ACTION_VALUES[state.nature] or HEART_ACTION_VALUES.HARDY
  return math.max(0, math.floor((row[action] or 0) * (multiplier or 1)))
end

-- Preserve the old signature for compatibility. Known Colosseum actions use
-- the Nature/action table; baseAmount remains a fallback for custom actions.
function reduceHeart(mon, data, baseAmount, action, multiplier)
  local state = shadow(mon)
  if not state or not state.isShadow then return nil end
  local key = ACTION_ALIASES[action] or action
  if action == "VIVID_SCENT" and multiplier == nil then multiplier = 3 end
  local amount = heartActionAmount(state, key, multiplier)
  if amount <= 0 then amount = math.max(1, math.floor(baseAmount or 1)) end

  local before = section(state)
  state.heart = math.max(0, (state.heart or HEART_MAX) - amount)
  local after = section(state)
  state.lastHeartAction = key
  refreshShadowMoves(mon, data)
  return {
    amount = amount,
    before = before,
    after = after,
    threshold = after < before,
    ready = state.heart == 0,
  }
end

-- Hyper Mode entry probabilities by Nature and remaining Heart Gauge bars.
-- Arrays are indexed 5 bars, 4, 3, 2, 1, 0 bars.
local HYPER_RATE_GROUPS = {
  A = { 0.30, 0.70, 0.70, 0.70, 0.50, 0.25 },
  B = { 0.30, 0.25, 0.20, 0.15, 0.10, 0.05 },
  C = { 0.50, 0.40, 0.30, 0.20, 0.10, 0.05 },
  D = { 0.50, 0.40, 0.40, 0.30, 0.25, 0.12 },
  E = { 0.20, 0.20, 0.15, 0.15, 0.10, 0.05 },
  F = { 0.50, 0.50, 0.50, 0.50, 0.50, 0.50 },
}

local HYPER_NATURE_GROUP = {
  ADAMANT="A", BASHFUL="A", HARDY="A", RELAXED="A",
  CALM="B", LONELY="B", MODEST="B", TIMID="B",
  BOLD="C", BRAVE="C", LAX="C", QUIRKY="C", SASSY="C",
  HASTY="D", IMPISH="D", NAUGHTY="D", RASH="D",
  CAREFUL="E", DOCILE="E", QUIET="E", SERIOUS="E",
  GENTLE="F", JOLLY="F", MILD="F", NAIVE="F",
}

HYPER_MODE_RATES = {}
for nature, group in pairs(HYPER_NATURE_GROUP) do
  HYPER_MODE_RATES[nature] = HYPER_RATE_GROUPS[group]
end

function hyperRate(state)
  if not state then return 0 end
  local remaining = math.max(0, math.min(5, section(state)))
  local row = HYPER_MODE_RATES[state.nature] or HYPER_RATE_GROUPS.A
  return row[6 - remaining] or 0
end

function heartMessage(state)
  if not state then return "The door to its heart\nis tightly shut." end
  local maxHeart = math.max(1, state.heartMax or HEART_MAX)
  local heart = math.max(0, math.min(maxHeart, state.heart or maxHeart))
  if heart == maxHeart then
    return "The door to its heart\nis tightly shut."
  elseif heart > maxHeart * 0.8 then
    return "The door to its heart\nis starting to open."
  elseif heart > maxHeart * 0.6 then
    return "The door to its heart\nis opening up."
  elseif heart > maxHeart * 0.4 then
    return "The door to its heart\nis opening wider."
  elseif heart > maxHeart * 0.2 then
    return "The door to its heart\nis nearly open."
  elseif heart > 0 then
    return "The door to its heart\nis almost fully open."
  end
  return "The door is about to open.\nUndo the final lock!"
end

local SCENT_ITEMS = {
  JOY_SCENT = true,
  EXCITE_SCENT = true,
  VIVID_SCENT = true,
}

local function isRestrictedShadowItem(id)
  if id == "RARE_CANDY" then return true end
  if id == "FIRE_STONE" or id == "THUNDER_STONE" or id == "WATER_STONE"
     or id == "LEAF_STONE" or id == "MOON_STONE" then return true end
  return type(id) == "string" and (id:match("^TM") or id:match("^HM"))
end

local function installDayCareFidelity()
  local ok, OverworldState = pcall(require, "src.world.OverworldController")
  if not ok or type(OverworldState) ~= "table"
     or OverworldState._colosseumDayCareV13 then return end
  local previous = OverworldState.onStepComplete
  if type(previous) ~= "function" then return end
  OverworldState._colosseumDayCareV13 = true
  OverworldState.onStepComplete = function(self, ...)
    local results = { previous(self, ...) }
    local Game = require("src.core.Game")
    local daycare = Game.save and Game.save.daycare
    local mon = daycare and daycare.mon
    local state = shadow(mon)
    if state and state.isShadow then
      -- Colosseum opens the Heart Gauge in Day Care but does not let the
      -- Shadow Pokémon level there. The step event already advanced its own
      -- 256-step Heart counter, so only vanilla Day Care EXP is cancelled.
      daycare.steps = 0
      if state.hyperMode then state.hyperMode = false end
    end
    return unpack(results)
  end
end

local function installLinkFidelity()
  local ok, Protocol = pcall(require, "src.link.Protocol")
  local TradeSession = ok and Protocol and Protocol.TradeSession
  if type(TradeSession) ~= "table" or TradeSession._colosseumTradeV13 then return end
  TradeSession._colosseumTradeV13 = true

  local previousCanPick = TradeSession.canPick
  if type(previousCanPick) == "function" then
    TradeSession.canPick = function(self, index)
      if isActiveShadow(self.party and self.party[index]) then return false end
      return previousCanPick(self, index)
    end
  end

  local previousPick = TradeSession.pick
  if type(previousPick) == "function" then
    TradeSession.pick = function(self, index)
      if isActiveShadow(self.party and self.party[index]) then
        self.error = "SHADOW POKéMON must be purified before trading."
        return nil
      end
      return previousPick(self, index)
    end
  end
end

-- v1.6: compute the banked share with Gen1Recomp's pure EXP formula rather
-- than applying EXP to a cloned Pokémon. This avoids depending on clone shape
-- or secondary hooks and guarantees that the exact vanilla share is banked
-- without mutating level/stat EXP before purification.
function shadowExperienceShare(battle, mon, split)
  if not (battle and battle.enemy and battle.enemy.def and battle.enemy.mon) then
    return 0
  end
  local Experience = require("src.battle.Experience")
  return Experience.gainFor(battle.enemy.def, battle.enemy.mon.level,
    battle.kind == "trainer", split, mon and mon.traded,
    battle.data and battle.data.constants)
end

function bankShadowExperience(battle, mon, split)
  local state = shadow(mon)
  if not (state and state.isShadow) then return nil, "not_shadow" end
  if not expBankingEnabled(state) then return 0, "locked" end
  local gained = math.max(0, math.floor(shadowExperienceShare(battle, mon, split) or 0))
  state.expBank = math.max(0, math.floor(state.expBank or 0)) + gained
  state.lastStoredExp = gained
  return gained, "stored"
end

local previousInstallBattleRuntime = installBattleRuntime
function installBattleRuntime(mod)
  previousInstallBattleRuntime(mod)
  installDayCareFidelity()
  installLinkFidelity()

  local BattleState = require("src.battle.BattleState")
  local Strings = require("src.core.Strings")
  local Font = require("src.render.Font")
  local ItemEffects = require("src.inventory.ItemEffects")

  BattleState._colosseumFidelityHooksV13 = {
    shadow = shadow,
    isActiveShadow = isActiveShadow,
    reduceHeart = reduceHeart,
    hyperRate = hyperRate,
  }

  BattleState._colosseumShouldCallV13 = function(self)
    if self.safari or self.demo or self.kind == "link" then return false end
    -- v1.6: CALL is strictly a Shadow-Pokémon command in this Gen1Recomp
    -- adaptation. The opponent being Shadow, the trainer-battle kind, or a
    -- status on a normal Pokémon must never replace RUN. A sleeping Shadow
    -- Pokémon can still be woken because it is itself an active Shadow mon.
    local mon = self.player and self.player.mon
    return isActiveShadow(mon) or false
  end

  BattleState._colosseumMarkParticipationV13 = function(self, battler)
    local mon = battler and battler.mon
    if not (battler and battler.isPlayer and isActiveShadow(mon)) then return nil end
    self._colosseumHeartParticipants = self._colosseumHeartParticipants or {}
    if self._colosseumHeartParticipants[mon] then return nil end
    self._colosseumHeartParticipants[mon] = true
    return reduceHeart(mon, self.data, nil, "BATTLE")
  end

  if not BattleState._colosseumFidelityInstalledV13 then
    BattleState._colosseumFidelityInstalledV13 = true

    -- Cue the player-side dark aura at the exact moment Gen1Recomp starts
    -- growing the Pokémon sprite out of its ball. The battler-switched event
    -- fires earlier (before send-out text/POOF), which could let a 48-frame
    -- aura expire before the Pokémon was actually visible.
    local previousStartGrowIn = BattleState.startGrowIn
    if type(previousStartGrowIn) == "function" then
      BattleState.startGrowIn = function(self, battler, ...)
        local results = { previousStartGrowIn(self, battler, ...) }
        if battler and battler.isPlayer and isActiveShadow(battler.mon) then
          self._colosseumPlayerAuraStartV16 = self.frame or 0
        end
        return unpack(results)
      end
    end

    local previousTryRun = BattleState.tryRun
    BattleState.tryRun = function(self)
      if not BattleState._colosseumShouldCallV13(self) then
        return previousTryRun(self)
      end

      self.phase = "messages"
      self.afterQueue = "menu"
      local mon = self.player and self.player.mon
      local state = shadow(mon)
      self:say(Strings("%s called out to\n%s!", self.game.save.player.name,
        monName(self.game, mon)))

      if state and state.isShadow and state.hyperMode then
        state.hyperMode = false
        local result = reduceHeart(mon, self.data, nil, "CALL")
        self:sayNext(monName(self.game, mon) .. " came to\nits senses!")
        if result and result.threshold then
          self:sayNext("The door to its heart\nopened a little!")
        end
      elseif mon and mon.status == "SLP" then
        mon.status = nil
        self:sayNext(monName(self.game, mon) .. " woke up!")
      else
        self:sayNext("But nothing happened!")
      end

      self:act(function()
        self:executeAction(self.enemy, self.player, self:enemyAction())
      end)
      self:queueResidual(self.player, self.enemy)
      self:act(function() self:endOfTurn() end)
    end

    local previousDrawTextArea = BattleState.drawTextArea
    BattleState.drawTextArea = function(self, ...)
      local results = { previousDrawTextArea(self, ...) }
      if not (love and love.graphics) then return unpack(results) end

      if self.phase == "menu" and not self.safari and not self.demo then
        -- Explicitly repaint the slot both ways. This is intentionally
        -- stronger than merely drawing CALL when needed: an older hot-reload
        -- wrapper may already have painted CALL earlier in the draw chain.
        -- Painting RUN here guarantees a normal lead sees RUN even in the
        -- special Shadow encounter.
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 126, 126, 34, 10)
        love.graphics.setColor(0, 0, 0, 1)
        Font.draw(BattleState._colosseumShouldCallV13(self) and "CALL" or "RUN",
          128, 128)
      end

      -- Shadow Rush has infinite PP in Colosseum. Keep an internal move
      -- instance for Gen1Recomp, but render the original --/-- indicator.
      if self.phase == "moveSelect" and self.player and self.player.curMoves then
        local selected = self.player.curMoves[self.moveIndex or 1]
        if selected and selected.id == SHADOW_MOVE then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.rectangle("fill", 40, 88, 48, 8)
          love.graphics.setColor(0, 0, 0, 1)
          Font.draw("--/--", 40, 88)
        end
      end
      love.graphics.setColor(1, 1, 1, 1)
      return unpack(results)
    end

    local previousUpdate = BattleState.update
    if type(previousUpdate) == "function" then
      BattleState.update = function(self, ...)
        local activeShadow = self.phase == "moveSelect"
          and self.player and isActiveShadow(self.player.mon)
        local input = self.game and self.game.input
        local previousWasPressed = input and input.wasPressed
        if activeShadow then self.moveSwapIndex = nil end
        if activeShadow and type(previousWasPressed) == "function" then
          input.wasPressed = function(obj, key)
            if key == "select" then return false end
            return previousWasPressed(obj, key)
          end
        end
        local results = { pcall(previousUpdate, self, ...) }
        if input and previousWasPressed then input.wasPressed = previousWasPressed end
        local succeeded = table.remove(results, 1)
        if not succeeded then error(results[1], 0) end
        return unpack(results)
      end
    end

    local previousPerformMove = BattleState.performMove
    BattleState.performMove = function(self, user, target, moveInst, isCalled)
      local state = user and shadow(user.mon)
      local moveId = moveInst and moveInst.id

      -- Shadow Rush always obeys. Other moves may produce Colosseum's Hyper
      -- Mode disobedience categories. Trainer/partner targeting is represented
      -- as a lost turn because Gen1Recomp battles have no targetable trainers.
      if user and user.isPlayer and state and state.isShadow
         and state.hyperMode and moveId ~= SHADOW_MOVE and not isCalled then
        local roll = self.rng(1, 100)
        if roll <= 45 then
          return previousPerformMove(self, user, target, moveInst, isCalled)
        elseif roll <= 58 then
          local choices = {}
          for _, candidate in ipairs(user.mon.moves or {}) do
            if candidate.id ~= moveId then choices[#choices + 1] = candidate end
          end
          if #choices > 0 then
            local alternate = choices[self.rng(1, #choices)]
            self:sayNext(monName(self.game, user.mon)
              .. " used a different\nmove instead!")
            return self:performMove(user, target, alternate, true)
          end
          self:sayNext(monName(self.game, user.mon) .. " ignored orders!")
          return
        elseif roll <= 68 then
          if not user.mon.status then
            user.mon.status = "SLP"
            self:sayNext(monName(self.game, user.mon)
              .. " took a nap\nin HYPER MODE!")
          else
            self:sayNext(monName(self.game, user.mon) .. " ignored orders!")
          end
          return
        elseif roll <= 78 then
          self:sayNext(monName(self.game, user.mon)
            .. " hurt itself\nin HYPER MODE!")
          local damage = math.max(1, math.floor((user.mon.stats.hp or 1) / 8))
          self:applyDamage(user, damage)
          if user.mon.hp <= 0 then self:onFaint(user) end
          return
        elseif roll <= 86 then
          self:sayNext(monName(self.game, user.mon)
            .. " tried to use its\nheld item!")
          return
        elseif roll <= 94 then
          self:sayNext(monName(self.game, user.mon)
            .. " lashed out at\nits TRAINER!")
          return
        elseif roll <= 98 then
          self:sayNext(monName(self.game, user.mon)
            .. " went back into\nits BALL!")
          return
        end
        self:sayNext(monName(self.game, user.mon)
          .. " ignored the order!")
        return
      end

      return previousPerformMove(self, user, target, moveInst, isCalled)
    end

    local previousOnFaint = BattleState.onFaint
    if type(previousOnFaint) == "function" then
      BattleState.onFaint = function(self, battler, ...)
        local state = battler and shadow(battler.mon)
        if state then state.hyperMode = false end
        return previousOnFaint(self, battler, ...)
      end
    end
  end

  if not ItemEffects._colosseumFidelityInstalledV13 then
    ItemEffects._colosseumFidelityInstalledV13 = true
    local previousUse = ItemEffects.use
    ItemEffects.use = function(data, save, id, target, battle, ...)
      local state = shadow(target)
      if state and state.isShadow then
        if battle and state.hyperMode and not SCENT_ITEMS[id] then
          return "failed", {
            monName({ data = data }, target)
              .. " won't accept items\nin HYPER MODE!",
          }
        end
        if isRestrictedShadowItem(id) then
          return "failed", { "The door to its heart\nblocks that item." }
        end
      end
      return previousUse(data, save, id, target, battle, ...)
    end
  end
end
