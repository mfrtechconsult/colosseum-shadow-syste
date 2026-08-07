-- Focused regression tests for the Pokémon Colosseum fidelity pass.
installBattleRuntime = function() end

dofile("src/part1.lua")
dofile("src/part2.lua")
dofile("src/part9.lua")

local function eq(actual, expected, label)
  if actual ~= expected then
    error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
  end
end

local function close(actual, expected, label)
  if math.abs(actual - expected) > 0.000001 then
    error(("%s: expected %.4f, got %.4f"):format(label, expected, actual))
  end
end

local function truthy(value, label)
  if not value then error(label) end
end

local kitGame = {
  data = { items = { POTION={}, RARE_CANDY={}, THUNDER_STONE={}, TM24={} } },
  save = { inventory = {} },
}
grantShadowTestKit(kitGame)
eq(kitGame.save.inventory.POTION, 5, "test-kit Potions")
eq(kitGame.save.inventory.RARE_CANDY, 3, "test-kit Rare Candies")
eq(kitGame.save.inventory.THUNDER_STONE, 1, "test-kit Thunder Stone")
eq(kitGame.save.inventory.TM24, 1, "test-kit TM24")

local count = 0
for nature, row in pairs(HEART_ACTION_VALUES) do
  count = count + 1
  for _, action in ipairs({ "BATTLE", "CALL", "PARTY", "DAYCARE", "SCENT" }) do
    truthy(type(row[action]) == "number" and row[action] > 0,
      nature .. " missing " .. action)
  end
end
eq(count, 25, "all 25 Natures are present")

eq(HEART_ACTION_VALUES.HARDY.BATTLE, 150, "Hardy battle value")
eq(HEART_ACTION_VALUES.DOCILE.CALL, 600, "Docile Call value")
eq(HEART_ACTION_VALUES.TIMID.PARTY, 50, "Timid party value")
eq(HEART_ACTION_VALUES.QUIRKY.DAYCARE, 600, "Quirky Day Care value")
eq(heartActionAmount({ nature = "LONELY" }, "SCENT", 3), 600,
  "Vivid Scent multiplier")

local mon = {
  moves = {},
  colosseumShadow = {
    version = 1, isShadow = true, purified = false,
    nature = "TIMID", heart = 5000, heartMax = 5000,
  },
}
local data = { moves = {} }
local result = reduceHeart(mon, data, nil, "PARTY")
eq(result.amount, 50, "Nature-specific party reduction")
eq(mon.colosseumShadow.heart, 4950, "Heart value after walking")

-- Exact Hyper Mode entry rows: indexes are 5,4,3,2,1,0 remaining bars.
close(hyperRate({ nature = "HARDY", heart = 5000, heartMax = 5000 }),
  0.30, "Hardy five-bar Hyper rate")
close(hyperRate({ nature = "HARDY", heart = 4000, heartMax = 5000 }),
  0.70, "Hardy four-bar Hyper rate")
close(hyperRate({ nature = "HARDY", heart = 0, heartMax = 5000 }),
  0.25, "Hardy empty-gauge Hyper rate")
close(hyperRate({ nature = "TIMID", heart = 0, heartMax = 5000 }),
  0.05, "Timid empty-gauge Hyper rate")
for _, heart in ipairs({ 5000, 4000, 3000, 2000, 1000, 0 }) do
  close(hyperRate({ nature = "JOLLY", heart = heart, heartMax = 5000 }),
    0.50, "Jolly constant Hyper rate")
end

eq(heartMessage({ heart = 5000, heartMax = 5000 }),
  "The door to its heart\nis tightly shut.", "full Heart Gauge message")
eq(heartMessage({ heart = 4500, heartMax = 5000 }),
  "The door to its heart\nis starting to open.", "starting message")
eq(heartMessage({ heart = 3500, heartMax = 5000 }),
  "The door to its heart\nis opening up.", "opening message")
eq(heartMessage({ heart = 2500, heartMax = 5000 }),
  "The door to its heart\nis opening wider.", "wider message")
eq(heartMessage({ heart = 1500, heartMax = 5000 }),
  "The door to its heart\nis nearly open.", "nearly message")
eq(heartMessage({ heart = 500, heartMax = 5000 }),
  "The door to its heart\nis almost fully open.", "almost message")
eq(heartMessage({ heart = 0, heartMax = 5000 }),
  "The door is about to open.\nUndo the final lock!", "ready message")

print("Colosseum fidelity formula tests passed.")
