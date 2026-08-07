package.preload["src.battle.BattleState"] = function()
  return {
    newTrainer = function()
      return { enemy = { mon = {} }, enemyParty = { {} } }
    end,
    enter = function(self) self.queue = self.queue or {} end,
    update = function(self)
      self._vanillaSelectSeen = self.game.input:wasPressed("select")
    end,
    throwBall = function() end,
    storeCaughtMon = function() end,
    tryRun = function() end,
    drawTextArea = function() end,
    applyDamage = function(_, _, damage) return damage end,
    performMove = function() end,
    onFaint = function() end,
    askNicknameUI = function() end,
  }
end


package.preload["src.ui.SummaryMenu"] = function()
  return {
    update = function(self) self._vanillaUpdateCalled = true end,
    draw = function(self) self._vanillaDrawCalled = true end,
  }
end

package.preload["src.inventory.ItemEffects"] = function()
  return {
    use = function()
      return "vanilla", { "Vanilla item flow." }
    end,
  }
end

local fakeGameModule = { save = {} }
package.preload["src.core.Game"] = function() return fakeGameModule end
package.preload["src.world.OverworldController"] = function()
  return {
    onStepComplete = function()
      local dc = fakeGameModule.save.daycare
      if dc and dc.mon then dc.steps = (dc.steps or 0) + 1 end
    end,
  }
end


package.preload["src.link.Protocol"] = function()
  local TradeSession = {}
  function TradeSession:canPick() return true end
  function TradeSession:pick(index) return { type = "pick", index = index } end
  return { TradeSession = TradeSession }
end

package.preload["src.mods.Runtime"] = function()
  return { emit = function() end }
end

package.preload["src.core.Strings"] = function()
  return setmetatable({}, {
    __call = function(_, fmt, ...)
      return string.format(fmt, ...)
    end,
  })
end

package.preload["src.render.Font"] = function()
  return { draw = function() end }
end

package.preload["src.render.TextBox"] = function()
  return { new = function() return {} end }
end

-- Verifies that main.lua can be loaded and its complete registration phase
-- can run against the API-2 shapes used by Gen1Recomp.

local registered = {
  type_chart = {}, moves = {}, items = {}, trainers = {},
  commands = {}, map_scripts = {}, hooks = {}, events = {},
}

local function registry(name, base)
  local r = {}
  function r:get(id)
    return base and base[id] or registered[name][id]
  end
  function r:register(id, value)
    assert(type(id) == "string", name .. " id")
    assert(type(value) == "table" or type(value) == "function", name .. " value")
    registered[name][id] = value
  end
  function r:patch(id, value) registered[name][id] = value end
  function r:each()
    return pairs(base or registered[name])
  end
  return r
end

local maps = {
  PALLET_TOWN = { id = "PALLET_TOWN" },
  ROUTE_1 = { id = "ROUTE_1" },
}

local mod = {
  id = "colosseum_shadow_system",
  path = ".",
  content = {
    type_chart = registry("type_chart"),
    moves = registry("moves", {
      TACKLE = {
        id = "TACKLE", name = "TACKLE", type = "NORMAL",
        power = 35, accuracy = 95, pp = 35,
        effect = "NO_ADDITIONAL_EFFECT",
      },
    }),
    items = registry("items"),
    trainers = registry("trainers"),
    commands = registry("commands"),
    map_scripts = registry("map_scripts"),
    maps = registry("maps", maps),
  },
  hooks = {
    wrap = function(_, id, fn)
      assert(type(id) == "string" and type(fn) == "function")
      registered.hooks[id] = fn
    end,
  },
  events = {
    on = function(_, id, fn)
      assert(type(id) == "string" and type(fn) == "function")
      registered.events[id] = fn
    end,
  },
  save = {
    values = {},
    get = function(self, key, default)
      local v = self.values[key]
      if v == nil then return default end
      return v
    end,
    set = function(self, key, value) self.values[key] = value end,
  },
  log = {
    warn = function() end, error = function() end,
    info = function() end,
  },
}

local entry = assert(loadfile("main.lua"))()
assert(type(entry) == "function", "main.lua must return an entry function")
entry(mod)

assert(registered.type_chart.SHADOW, "SHADOW type not registered")
assert(registered.moves.SHADOW_RUSH, "SHADOW RUSH not registered")
assert(registered.items.COLOSSEUM_SNAG_MACHINE, "SNAG MACHINE not registered")
assert(registered.trainers.OPP_COLOSSEUM_CIPHER_PEON, "Cipher trainer not registered")
assert(registered.commands["colosseum:researcher"], "Researcher command missing")
assert(registered.map_scripts.PALLET_TOWN, "Pallet Town scripts missing")
assert(registered.map_scripts.ROUTE_1, "global step script missing")
assert(registered.hooks["battle.crit"], "critical hook missing")
assert(registered.hooks["battle.exp_award"], "EXP hook missing")
assert(registered.hooks["evolution.check"], "evolution hook missing")
assert(registered.events["game.ready"], "game.ready handler missing")
local BattleState = require("src.battle.BattleState")
local SummaryMenu = require("src.ui.SummaryMenu")
assert(BattleState._colosseumShadowUIInstalledV1, "battle reveal UI missing")
assert(SummaryMenu._colosseumShadowUIInstalledV1, "summary UI missing")
assert(SummaryMenu._colosseumPurifiedSummaryV1,
  "post-purification summary lifecycle missing")

local purifiedSummaryMon = {
  colosseumShadow = {
    version = 1, isShadow = false, purified = true, nationalRibbon = true,
  },
}
local purifiedSummary = {
  mon = purifiedSummaryMon, page = 3,
  game = {
    input = { wasPressed = function() return false end },
    stack = { pop = function() end },
  },
}
SummaryMenu.update(purifiedSummary, 0)
assert(purifiedSummary.page == 2 and purifiedSummary._vanillaUpdateCalled,
  "purified Pokémon must immediately return to vanilla two-page navigation")
SummaryMenu.draw(purifiedSummary)
assert(purifiedSummary._vanillaDrawCalled,
  "purified Pokémon must bypass the Shadow renderer")
assert(purifiedSummaryMon.colosseumShadow
       and purifiedSummaryMon.colosseumShadow.nationalRibbon,
  "purification history must remain stored while Shadow UI is hidden")

local shadowMon = {
  colosseumShadow = {
    version = 1, isShadow = true, purified = false,
  },
}
local normalMon = {}
local visibilityBattle = {
  growInScale = function() return nil end,
  fxHidden = function() return false end,
}
local visible = assert(BattleState._colosseumShadowBadgeVisibleV1,
  "Shadow badge visibility helper missing")
visibilityBattle.showEnemyTrainer = true
assert(not visible(visibilityBattle, { mon = shadowMon }, "enemy"),
  "badge must not appear on the enemy trainer portrait")
visibilityBattle.showEnemyTrainer = false
assert(visible(visibilityBattle, { mon = shadowMon }, "enemy"),
  "badge must appear on a visible Shadow enemy")
assert(not visible(visibilityBattle, { mon = normalMon }, "enemy"),
  "badge must not appear on a normal enemy Pokémon")
visibilityBattle.showPlayerBack = true
assert(not visible(visibilityBattle, { mon = shadowMon }, "player"),
  "badge must not appear on the player trainer portrait")
visibilityBattle.showPlayerBack = false
assert(visible(visibilityBattle, { mon = shadowMon }, "player"),
  "badge must appear on a visible player Shadow Pokémon")


assert(registered.events["battle.battler_switched"],
  "battle switch participation handler missing")
assert(BattleState._colosseumFidelityInstalledV13,
  "Colosseum fidelity runtime missing")
assert(BattleState._colosseumShouldCallV13,
  "CALL availability helper missing")
assert(BattleState._colosseumMarkParticipationV13,
  "battle participation helper missing")

local participatingMon = {
  moves = {},
  colosseumShadow = {
    version = 1, isShadow = true, purified = false,
    nature = "HARDY", heart = 5000, heartMax = 5000,
  },
}
local fakeBattle = {
  data = { moves = {} },
  kind = "wild",
  game = { save = { party = { participatingMon } } },
  player = { isPlayer = true, mon = participatingMon },
}
local firstParticipation = BattleState._colosseumMarkParticipationV13(
  fakeBattle, fakeBattle.player)
assert(firstParticipation and firstParticipation.amount == 150,
  "first battle participation must use the Nature table")
assert(participatingMon.colosseumShadow.heart == 4850,
  "battle participation reduction incorrect")
assert(BattleState._colosseumMarkParticipationV13(
  fakeBattle, fakeBattle.player) == nil,
  "the same Pokémon must only count once per battle")
assert(BattleState._colosseumShouldCallV13(fakeBattle),
  "CALL must replace RUN for an active Shadow Pokémon")

fakeBattle.kind = "trainer"
fakeBattle.player.mon = { status = nil }
assert(BattleState._colosseumShouldCallV13(fakeBattle),
  "CALL must replace RUN in trainer battles")
fakeBattle.kind = "wild"
assert(not BattleState._colosseumShouldCallV13(fakeBattle),
  "ordinary wild battles must preserve RUN for Kanto compatibility")
fakeBattle.player.mon.status = "SLP"
assert(BattleState._colosseumShouldCallV13(fakeBattle),
  "CALL must be available to wake a sleeping Pokémon")

local selectInput = {
  wasPressed = function(_, key) return key == "select" end,
}
local reorderBattle = {
  phase = "moveSelect", moveSwapIndex = 2,
  player = { mon = participatingMon },
  game = { input = selectInput },
}
BattleState.update(reorderBattle)
assert(reorderBattle.moveSwapIndex == nil,
  "active Shadow moves must not be reorderable")
assert(reorderBattle._vanillaSelectSeen == false,
  "SELECT must be suppressed for an active Shadow Pokémon")

local Protocol = require("src.link.Protocol")
local trade = setmetatable({ party = { participatingMon } },
  { __index = Protocol.TradeSession })
assert(not trade:canPick(1),
  "active Shadow Pokémon must be unavailable for trading")
assert(trade:pick(1) == nil and trade.error,
  "active Shadow Pokémon trade must be rejected")

local ItemEffects = require("src.inventory.ItemEffects")
local hyperTarget = {
  species = "PIKACHU",
  colosseumShadow = {
    version = 1, isShadow = true, purified = false, hyperMode = true,
  },
}
local result, messages = ItemEffects.use(
  { pokemon = { PIKACHU = { name = "PIKACHU" } } }, {},
  "POTION", hyperTarget, {})
assert(result == "failed" and messages and #messages > 0,
  "items must be refused in Hyper Mode")
hyperTarget.colosseumShadow.hyperMode = false
result = ItemEffects.use({}, {}, "RARE_CANDY", hyperTarget, nil)
assert(result == "failed", "Rare Candy must be blocked before purification")
result = ItemEffects.use({}, {}, "THUNDER_STONE", hyperTarget, nil)
assert(result == "failed", "evolution stones must be blocked before purification")
result = ItemEffects.use({}, {}, "TM24", hyperTarget, nil)
assert(result == "failed", "TMs must be blocked before purification")
result = ItemEffects.use({}, {}, "PP_UP", hyperTarget, nil)
assert(result == "vanilla", "PP UP is not an evolution, level, or move-teaching item")
hyperTarget.colosseumShadow.hyperMode = true
result = ItemEffects.use({}, {}, "VIVID_SCENT", hyperTarget, {})
assert(result == "vanilla", "Scents must remain usable to end Hyper Mode")

assert(registered.events["battle.turn_started"],
  "rare natural Hyper recovery handler missing")
local naturalMon = {
  moves = {}, species = "PIKACHU",
  colosseumShadow = {
    version = 1, isShadow = true, purified = false, hyperMode = true,
    nature = "HARDY", heart = 3000, heartMax = 5000,
  },
}
local naturalBattle = {
  player = { mon = naturalMon }, data = { moves = {} },
  game = { data = { pokemon = { PIKACHU = { name = "PIKACHU" } } } },
  rng = function() return 0 end,
  sayNext = function() end,
}
registered.events["battle.turn_started"]({ battle = naturalBattle })
assert(naturalMon.colosseumShadow.hyperMode == false,
  "1/256 natural recovery must clear Hyper Mode")
assert(naturalMon.colosseumShadow.heart == 2700,
  "natural recovery must open the Heart Gauge")

naturalMon.colosseumShadow.hyperMode = true
local critHook = registered.hooks["battle.crit"]
assert(critHook(function() return false end, {
  attacker = { mon = naturalMon }, moveId = "SHADOW_RUSH",
  rng = function() return 231 end,
}) == true, "Hyper Shadow Rush 232/256 critical boost missing")
assert(critHook(function() return true end, {
  attacker = { mon = naturalMon }, moveId = "SHADOW_RUSH",
  rng = function() return 232 end,
}) == false, "Hyper critical rate must stop exactly at 232/256")

local OverworldState = require("src.world.OverworldController")
assert(OverworldState._colosseumDayCareV13,
  "Day Care fidelity wrapper missing")
local daycareMon = {
  colosseumShadow = {
    version = 1, isShadow = true, purified = false, hyperMode = true,
  },
}
fakeGameModule.save.daycare = { mon = daycareMon, steps = 0 }
OverworldState:onStepComplete()
assert(fakeGameModule.save.daycare.steps == 0,
  "Shadow Pokémon must not gain Day Care EXP")
assert(daycareMon.colosseumShadow.hyperMode == false,
  "Day Care must end Hyper Mode")

print("Registration bootstrap test passed.")
