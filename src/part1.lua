-- Colosseum Shadow System v1.7.0-dev
--
-- Reusable Shadow core plus the original Pallet Town demonstration.
-- All player-facing content is deliberately written in English.
--
-- The demo constants below remain defaults for backwards compatibility.
-- Reusable consumers should pass per-Pokémon configuration to attachShadow().

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

-- Demo defaults. Part 9 replaces the compatibility Heart/Hyper fallbacks with
-- verified Colosseum Nature/action tables before gameplay begins.
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
  if not id then return nil end
  local def = data and data.moves and data.moves[id]
  return { id = id, pp = def and def.pp or 0 }
end

local function configuredNormalMoves(state)
  if state and type(state.normalMoves) == "table" and #state.normalMoves > 0 then
    return state.normalMoves
  end
  return NORMAL_MOVES
end

local function configuredPurifiedMoves(state)
  if state and type(state.purifiedMoves) == "table" and #state.purifiedMoves > 0 then
    return state.purifiedMoves
  end
  local out = copy(configuredNormalMoves(state))
  out[#out + 1] = (state and state.purificationMove) or PURIFICATION_MOVE
  return out
end

function refreshShadowMoves(mon, data)
  local state = shadow(mon)
  if not state then return end
  if state.purified or not state.isShadow then
    local moves = {}
    for _, id in ipairs(configuredPurifiedMoves(state)) do
      if id then moves[#moves + 1] = moveSlot(data, id) end
    end
    mon.moves = moves
    return
  end

  local moves = { moveSlot(data, state.shadowMove or SHADOW_MOVE) }
  local normalMoves = configuredNormalMoves(state)
  for i = 1, math.min(unlockedNormalMoves(state), #normalMoves) do
    moves[#moves + 1] = moveSlot(data, normalMoves[i])
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

function configureShadow(state, config)
  if not state or type(config) ~= "table" then return state end
  if config.shadowId ~= nil then state.shadowId = config.shadowId end
  if config.shadowMove ~= nil then state.shadowMove = config.shadowMove end
  if config.normalMoves ~= nil then state.normalMoves = copy(config.normalMoves) end
  if config.purifiedMoves ~= nil then state.purifiedMoves = copy(config.purifiedMoves) end
  if config.purificationMove ~= nil then state.purificationMove = config.purificationMove end
  if config.nature ~= nil then state.nature = config.nature end
  if config.heartMax ~= nil then
    local nextMax = math.max(1, math.floor(config.heartMax))
    local oldMax = math.max(1, math.floor(state.heartMax or HEART_MAX))
    local oldHeart = math.max(0, math.floor(state.heart or oldMax))
    state.heartMax = nextMax
    if config.preserveHeartFraction == true then
      state.heart = math.max(0, math.min(nextMax,
        math.floor((oldHeart / oldMax) * nextMax + 0.5)))
    elseif config.resetHeart == true then
      state.heart = nextMax
    else
      state.heart = math.max(0, math.min(nextMax, oldHeart))
    end
  end
  return state
end

function attachShadow(mon, data, config)
  local existing = shadow(mon)
  if existing then
    configureShadow(existing, config)
    refreshShadowMoves(mon, data)
    return existing
  end

  config = config or {}
  local personality = personalityFrom(mon)
  local heartMax = math.max(1, math.floor(config.heartMax or HEART_MAX))
  local state = {
    version = 1,
    shadowId = config.shadowId or SHADOW_ID,
    isShadow = true,
    purified = false,
    hyperMode = false,
    personality = personality,
    nature = config.nature or NATURES[(personality % #NATURES) + 1],
    heart = heartMax,
    heartMax = heartMax,
    stepCounter = 0,
    expBank = 0,
    nationalRibbon = false,
    shadowMove = config.shadowMove or SHADOW_MOVE,
    normalMoves = copy(config.normalMoves or NORMAL_MOVES),
    purificationMove = config.purificationMove or PURIFICATION_MOVE,
    purifiedMoves = config.purifiedMoves and copy(config.purifiedMoves) or nil,
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
  state.heart = math.max(0, (state.heart or state.heartMax or HEART_MAX) - amount)
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
