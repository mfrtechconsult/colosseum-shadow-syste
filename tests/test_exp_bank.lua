-- End-to-end Shadow EXP banking and purification regression test.
package.preload["src.battle.Experience"] = function()
  return {
    gainFor = function() return 123 end,
  }
end
package.preload["src.pokemon.Growth"] = function()
  return {
    levelForExp = function(_, exp)
      return exp >= 1000 and 21 or 20
    end,
  }
end
package.preload["src.pokemon.Stats"] = function()
  return {
    calc = function(_, level)
      return { hp = level == 21 and 55 or 50, attack = 1, defense = 1,
               speed = 1, special = 1 }
    end,
  }
end

installBattleRuntime = function() end

dofile("src/part1.lua")
dofile("src/part2.lua")
dofile("src/part9.lua")

local mon = {
  species = "PIKACHU", level = 20, exp = 900, hp = 40,
  stats = { hp = 50 }, dvs = {}, statExp = {}, moves = {}, traded = false,
  colosseumShadow = {
    version = 1, isShadow = true, purified = false,
    nature = "HARDY", heart = 2500, heartMax = 5000, expBank = 0,
  },
}
local battle = {
  kind = "trainer",
  data = { constants = {} },
  enemy = { def = { baseExp = 100 }, mon = { level = 20 } },
}
local gained, why = bankShadowExperience(battle, mon, 1)
assert(gained == 123 and why == "stored", "eligible battle EXP must be banked")
assert(mon.colosseumShadow.expBank == 123, "expBank did not increase")
assert(mon.exp == 900 and mon.level == 20, "banking must not level the Shadow Pokémon")

mon.colosseumShadow.heart = 0
local game = {
  data = {
    pokemon = { PIKACHU = { growthRate = "MEDIUM_FAST" } },
    growth_rates = {}, constants = { levelCap = 100 },
    moves = {
      THUNDERSHOCK = { pp = 30 }, TAIL_WHIP = { pp = 30 },
      THUNDER_WAVE = { pp = 20 }, QUICK_ATTACK = { pp = 30 },
    },
  },
}
local ok, bank, oldLevel = purify(game, mon)
assert(ok and bank == 123 and oldLevel == 20, "purification did not consume the bank")
assert(mon.exp == 1023, "banked EXP was not applied to the real Pokémon")
assert(mon.level == 21, "banked EXP did not recalculate the level")
assert(mon.colosseumShadow.expBank == 0, "bank must clear after purification")
assert(mon.colosseumShadow.purified and not mon.colosseumShadow.isShadow,
  "purification state transition failed")

print("Shadow EXP banking/purification test passed.")
