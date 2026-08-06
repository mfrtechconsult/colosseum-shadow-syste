-- Colosseum Shadow System v1.3.0
--
-- Directly playable vertical slice for Gen1Recomp.
-- All player-facing content is deliberately written in English.
--
-- The mod uses the public content/script APIs for data and Pallet Town NPCs.
-- The current Gen1Recomp release does not expose trainer-Pokémon capture or
-- command-menu replacement as public hooks, so those two seams are installed
-- through the declared engine_internals permission, in the same style as the
-- official Nuzlocke mod.

MOD_ID = "colosseum_shadow_system"
TRAINER_ID = "OPP_COLOSSEUM_CIPHER_PEON"
SHADOW_MOVE = "SHADOW_RUSH"
SNAG_MACHINE = "COLOSSEUM_SNAG_MACHINE"
SHADOW_ID = "PALLET_SHADOW_PIKACHU"
PALLET = "PALLET_TOWN"
HEART_MAX = 5000

NATURES = {
  "HARDY", "LONELY", "BRAVE", "ADAMANT", "NAUGHTY",
  "BOLD", "DOCILE", "RELAXED", "IMPISH", "LAX",
  "TIMID", "HASTY", "SERIOUS", "JOLLY", "NAIVE",
  "MODEST", "MILD", "QUIET", "BASHFUL", "RASH",
  "CALM", "GENTLE", "SASSY", "CAREFUL", "QUIRKY",
}

-- Part 9 replaces the compatibility fallbacks below with the verified
-- Colosseum Nature/action and Hyper Mode tables before gameplay begins.

NORMAL_MOVES = { "THUNDERSHOCK", "TAIL_WHIP", "THUNDER_WAVE" }
PURIFICATION_MOVE = "QUICK_ATTACK"

function copy(value, seen)
  if type(value) ~= "table" then return value end
  seen = seen or {}
  if seen[value] then return seen[value] end
  local out = {}
  seen[value] = out
  for k, v in pairs(value) do out[copy(k, seen)] = copy(v, seen) end
  return out
end

function shadow(mon)
  local state = mon and mon.colosseumShadow
  if type(state) == "table" and state.version == 1 then return state end
  return nil
end

function isActiveShadow(mon)
  local state = shadow(mon)
  return state and state.isShadow == true and state.purified ~= true
end

function section(state)
  if not state or (state.heart or 0) <= 0 then return 0 end
  return math.max(1, math.min(5,
    math.ceil((state.heart or HEART_MAX) * 5 / (state.heartMax or HEART_MAX))))
end

function unlockedNormalMoves(state)
  local s = section(state)
  if s <= 1 then return 3 end
  if s == 2 then return 2 end
  if s <= 4 then return 1 end
  return 0
end

function natureVisible(state)
  return section(state) <= 3
end

function expBankingEnabled(state)
  return section(state) <= 3
end

function gauge(state)
  local open = 5 - section(state)
  if section(state) == 0 then open = 5 end
  return "[" .. string.rep("-", open) .. string.rep("#", 5 - open) .. "]"
end

function monName(game, mon)
  if not mon then return "POKéMON" end
  local def = game and game.data and game.data.pokemon[mon.species]
  return mon.nickname or (def and def.name) or mon.species or "POKéMON"
end

function moveSlot(data, id)
  local def = data and data.moves and data.moves[id]
  return { id = id, pp = def and def.pp or 0 }
end

function refreshShadowMoves(mon, data)
  local state = shadow(mon)
  if not state then return end
  if state.purified or not state.isShadow then
    mon.moves = {
      moveSlot(data, NORMAL_MOVES[1]),
      moveSlot(data, NORMAL_MOVES[2]),
      moveSlot(data, NORMAL_MOVES[3]),
      moveSlot(data, PURIFICATION_MOVE),
    }
    return
  end

  local moves = { moveSlot(data, SHADOW_MOVE) }
  for i = 1, unlockedNormalMoves(state) do
    moves[#moves + 1] = moveSlot(data, NORMAL_MOVES[i])
  end
  mon.moves = moves
end

function personalityFrom(mon)
  local dvs = mon.dvs or {}
  return ((dvs.attack or 0) * 4096
        + (dvs.defense or 0) * 256
        + (dvs.speed or 0) * 16
        + (dvs.special or 0)) % 2147483647
end

function attachShadow(mon, data)
  if shadow(mon) then
    refreshShadowMoves(mon, data)
    return shadow(mon)
  end
  local personality = personalityFrom(mon)
  local state = {
    version = 1,
    shadowId = SHADOW_ID,
    isShadow = true,
    purified = false,
    hyperMode = false,
    personality = personality,
    nature = NATURES[(personality % #NATURES) + 1],
    heart = HEART_MAX,
    heartMax = HEART_MAX,
    stepCounter = 0,
    expBank = 0,
    nationalRibbon = false,
  }
  mon.colosseumShadow = state
  refreshShadowMoves(mon, data)
  return state
end

function reduceHeart(mon, data, baseAmount, action)
  local state = shadow(mon)
  if not state or not state.isShadow then return nil end
  local amount = math.max(1, math.floor(baseAmount or 1))
  local before = section(state)
  state.heart = math.max(0, (state.heart or HEART_MAX) - amount)
  local after = section(state)
  state.lastHeartAction = action
  refreshShadowMoves(mon, data)
  return { amount = amount, before = before, after = after,
           threshold = after < before, ready = state.heart == 0 }
end

function hyperRate() return 0 end

function eachOwnedMon(save, fn)
  for _, mon in ipairs(save.party or {}) do fn(mon, "party") end
  for _, box in ipairs(save.boxes or {}) do
    for _, mon in ipairs(box or {}) do fn(mon, "box") end
  end
  local daycare = save.daycare
  if type(daycare) == "table" then
    if daycare.mon then fn(daycare.mon, "daycare") end
    if daycare[1] and type(daycare[1]) == "table" then fn(daycare[1], "daycare") end
  end
end

function findDemoShadow(save)
  local found, location
  eachOwnedMon(save, function(mon, where)
    local state = shadow(mon)
    if not found and state and state.shadowId == SHADOW_ID then
      found, location = mon, where
    end
  end)
  return found, location
end

function removeDemoShadow(save)
  for i = #(save.party or {}), 1, -1 do
    local state = shadow(save.party[i])
    if state and state.shadowId == SHADOW_ID then table.remove(save.party, i) end
  end
  for _, box in ipairs(save.boxes or {}) do
    for i = #box, 1, -1 do
      local state = shadow(box[i])
      if state and state.shadowId == SHADOW_ID then table.remove(box, i) end
    end
  end
  if type(save.daycare) == "table" then
    local state = shadow(save.daycare.mon)
    if state and state.shadowId == SHADOW_ID then save.daycare.mon = nil end
  end
end
