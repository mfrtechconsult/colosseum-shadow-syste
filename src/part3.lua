function occupiedCells(ow)
  local occupied = {}
  local function mark(x, y) occupied[tostring(x) .. ":" .. tostring(y)] = true end
  if ow.player then mark(ow.player.cellX, ow.player.cellY) end
  for _, npc in ipairs(ow.npcs or {}) do mark(npc.cellX, npc.cellY) end
  return occupied
end

function suitableCell(ow, occupied, x, y)
  local map = ow.map
  if not map:inBounds(x, y) or not map:isWalkableCell(x, y) then return false end
  if map:warpAtCell(x, y) then return false end
  if map.signAtCell and map:signAtCell(x, y) then return false end
  if occupied[tostring(x) .. ":" .. tostring(y)] then return false end
  local exits = 0
  for _, d in ipairs({ {1,0}, {-1,0}, {0,1}, {0,-1} }) do
    local nx, ny = x + d[1], y + d[2]
    if map:inBounds(nx, ny) and map:isWalkableCell(nx, ny) then exits = exits + 1 end
  end
  return exits >= 2
end

function pickNpcCells(ow, count)
  local occupied = occupiedCells(ow)
  local out = {}
  local preferred = {
    { 5, 8 }, { 7, 8 }, { 9, 8 }, { 11, 8 },
    { 5, 10 }, { 7, 10 }, { 9, 10 }, { 11, 10 },
    { 6, 12 }, { 8, 12 }, { 10, 12 }, { 12, 12 },
  }
  local function take(x, y)
    if #out >= count then return end
    if suitableCell(ow, occupied, x, y) then
      out[#out + 1] = { x, y }
      occupied[tostring(x) .. ":" .. tostring(y)] = true
    end
  end
  for _, p in ipairs(preferred) do take(p[1], p[2]) end
  for y = 2, ow.map.heightCells - 3 do
    for x = 2, ow.map.widthCells - 3 do take(x, y) end
  end
  return out
end

NPC_SPECS = {
  {
    name = "MOD_COLO_RESEARCHER", sprite = "SPRITE_SCIENTIST",
    text = "TEXT_COLO_RESEARCHER", range = "DOWN",
  },
  {
    name = "MOD_COLO_CIPHER", sprite = "SPRITE_ROCKET",
    text = "TEXT_COLO_CIPHER", range = "LEFT",
  },
  {
    name = "MOD_COLO_MONITOR", sprite = "SPRITE_GYM_GUIDE",
    text = "TEXT_COLO_MONITOR", range = "UP",
  },
  {
    name = "MOD_COLO_RELIC", sprite = "SPRITE_MR_FUJI",
    text = "TEXT_COLO_RELIC", range = "RIGHT",
  },
}

function ensurePalletNpcs(mod, game, ow)
  if not ow or not ow.map or ow.map.id ~= PALLET then return end
  local present = {}
  for _, npc in ipairs(ow.npcs or {}) do
    if npc.def and npc.def.name then present[npc.def.name] = true end
  end
  local missing = {}
  for _, spec in ipairs(NPC_SPECS) do
    if not present[spec.name] then missing[#missing + 1] = spec end
  end
  if #missing == 0 then return end

  local cells = pickNpcCells(ow, #missing)
  for i, spec in ipairs(missing) do
    local cell = cells[i]
    if cell then
      ow:addRuntimeObject(PALLET, {
        name = spec.name,
        sprite = spec.sprite,
        x = cell[1], y = cell[2],
        movement = "STAY",
        range = spec.range,
        text = spec.text,
      }, mod.id)
    else
      mod.log:error("No free Pallet Town cell for %s", spec.name)
    end
  end
end

function registerContent(mod)
  mod.content.type_chart:register("SHADOW", {
    name = "SHADOW",
    category = "physical",
  })

  local baseMove = copy(mod.content.moves:get("TACKLE"))
  baseMove.id = SHADOW_MOVE
  baseMove.name = "SHADOW RUSH"
  baseMove.type = "SHADOW"
  baseMove.power = 90
  baseMove.accuracy = 100
  baseMove.pp = 64
  baseMove.category = "physical"
  baseMove.anim = "TAKE_DOWN"
  mod.content.moves:register(SHADOW_MOVE, baseMove)

  mod.content.items:register(SNAG_MACHINE, {
    id = SNAG_MACHINE,
    name = "SNAG MACHINE",
    price = 0,
    keyItem = true,
    tossable = false,
  })

  mod.content.trainers:register(TRAINER_ID, {
    id = TRAINER_ID,
    name = "CIPHER PEON",
    basePic = "OPP_ROCKET",
    baseMoney = 15,
    parties = {
      { { level = 15, species = "PIKACHU" } },
    },
  })
end

