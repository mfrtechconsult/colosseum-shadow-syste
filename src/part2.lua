function applyBankedExperience(game, mon)
  local state = shadow(mon)
  local bank = state and math.max(0, math.floor(state.expBank or 0)) or 0
  if bank <= 0 then return 0, mon.level end

  local Growth = require("src.pokemon.Growth")
  local Stats = require("src.pokemon.Stats")
  local def = game.data.pokemon[mon.species]
  local oldLevel = mon.level
  local oldMax = mon.stats and mon.stats.hp or mon.hp
  mon.exp = math.max(0, (mon.exp or 0) + bank)
  mon.level = Growth.levelForExp(def.growthRate, mon.exp,
    (game.data.constants and game.data.constants.levelCap) or 100,
    game.data.growth_rates)
  mon.stats = Stats.calc(def, mon.level, mon.dvs or {}, mon.statExp)
  local gainedMax = math.max(0, (mon.stats.hp or 1) - (oldMax or 1))
  mon.hp = math.min(mon.stats.hp, math.max(1, (mon.hp or 1) + gainedMax))
  state.expBank = 0
  return bank, oldLevel
end

function purify(game, mon)
  local state = shadow(mon)
  if not state or not state.isShadow or (state.heart or 1) > 0 then return false end
  local bank, oldLevel = applyBankedExperience(game, mon)
  state.isShadow = false
  state.purified = true
  state.hyperMode = false
  state.heart = 0
  state.nationalRibbon = true
  state.purifiedAtLevel = mon.level
  mon.nationalRibbon = true
  refreshShadowMoves(mon, game.data)
  return true, bank, oldLevel
end

function refreshPartyShadowMoves(game)
  eachOwnedMon(game.save, function(mon)
    if shadow(mon) then refreshShadowMoves(mon, game.data) end
  end)
end

function stepHeart(game)
  local function advance(mon, action)
    local state = shadow(mon)
    if not (state and state.isShadow) then return end
    state.stepCounter = (state.stepCounter or 0) + 1
    while state.stepCounter >= 256 do
      state.stepCounter = state.stepCounter - 256
      reduceHeart(mon, game.data, nil, action)
    end
  end

  for _, mon in ipairs(game.save.party or {}) do advance(mon, "PARTY") end

  -- Colosseum also opens the heart every 256 steps in Day Care, without
  -- granting the Shadow Pokémon Day Care experience.
  local daycare = game.save.daycare
  if type(daycare) == "table" then
    if daycare.mon then advance(daycare.mon, "DAYCARE") end
    if daycare[1] and type(daycare[1]) == "table" then
      advance(daycare[1], "DAYCARE")
    end
  end
end

function resetEncounter(mod, game)
  removeDemoShadow(game.save)
  mod.save:set("encounter_status", "available")
  mod.save:set("encounter_snapshot", false)
  mod.save:set("snag_machine", true)
end

function ensureStarter(game)
  if #(game.save.party or {}) > 0 then return false end
  local Pokemon = require("src.pokemon.Pokemon")
  local Party = require("src.pokemon.Party")
  local BattleState = require("src.battle.BattleState")
  local mon = Pokemon.new(game.data, "EEVEE", 15)
  mon.nickname = "EEVEE"
  BattleState.stampOT(game.save, mon)
  Party.add(game.save.party, mon)
  if game.save.pokedex then
    game.save.pokedex.seen.EEVEE = true
    game.save.pokedex.owned.EEVEE = true
  end
  return true
end


SHADOW_TEST_KIT = {
  POTION = 5,
  RARE_CANDY = 3,
  THUNDER_STONE = 1,
  TM24 = 1,
}

function grantShadowTestKit(game)
  game.save.inventory = game.save.inventory or {}
  -- Every item exercises a Shadow restriction. POTION tests the Hyper Mode
  -- refusal; the others must be blocked while Shadow and work after
  -- purification. Skip ids absent from unusual host-data builds.
  for id, count in pairs(SHADOW_TEST_KIT) do
    if not game.data.items or game.data.items[id] then
      game.save.inventory[id] = math.max(game.save.inventory[id] or 0, count)
    end
  end
end

function setupPlayer(mod, game)
  local Pokemon = require("src.pokemon.Pokemon")
  local addedStarter = ensureStarter(game)
  mod.save:set("snag_machine", true)
  game.save.inventory = game.save.inventory or {}
  game.save.inventory[SNAG_MACHINE] = 1
  game.save.inventory.POKE_BALL = math.max(game.save.inventory.POKE_BALL or 0, 25)

  grantShadowTestKit(game)

  for _, mon in ipairs(game.save.party or {}) do Pokemon.heal(mon) end
  if not mod.save:get("encounter_status") then
    mod.save:set("encounter_status", "available")
  end
  return addedStarter
end
