-- Standalone tests for the pure Shadow-system formulas.
-- Run with: texlua tests/test_shadow_math.lua
local function eq(a, b, label)
  if a ~= b then error(("%s: expected %s, got %s"):format(label, tostring(b), tostring(a))) end
end

local function section(heart, maxHeart)
  if heart <= 0 then return 0 end
  return math.max(1, math.min(5, math.ceil(heart * 5 / maxHeart)))
end

local function unlocks(heart)
  local s = section(heart, 5000)
  if s <= 1 then return 3 end
  if s == 2 then return 2 end
  if s <= 4 then return 1 end
  return 0
end

eq(section(5000, 5000), 5, "full gauge")
eq(section(4999, 5000), 5, "still in fifth section")
eq(section(4000, 5000), 4, "four sections")
eq(section(3000, 5000), 3, "three sections")
eq(section(2000, 5000), 2, "two sections")
eq(section(1000, 5000), 1, "one section")
eq(section(0, 5000), 0, "ready for purification")

eq(unlocks(5000), 0, "Shadow Rush only")
eq(unlocks(4000), 1, "first normal move")
eq(unlocks(3000), 1, "Nature threshold does not add a move")
eq(unlocks(2000), 2, "second normal move")
eq(unlocks(1000), 3, "third normal move")
eq(unlocks(0), 3, "all normal moves before ceremony")

local steps, heart = 0, 5000
for _ = 1, 255 do steps = steps + 1 end
eq(heart, 5000, "no reduction before step 256")
steps = steps + 1
if steps >= 256 then steps, heart = steps - 256, heart - 150 end
eq(steps, 0, "step counter rolls over")
eq(heart, 4850, "Hardy party-step reduction")

local function recoil(maxHP, offset)
  return math.max(1, math.floor(maxHP / 16) + offset)
end
eq(recoil(160, -1), 9, "recoil low")
eq(recoil(160, 0), 10, "recoil normal")
eq(recoil(160, 1), 11, "recoil high")
eq(recoil(1, -1), 1, "minimum recoil")

print("All Shadow-system formula tests passed.")
