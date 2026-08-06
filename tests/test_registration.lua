package.preload["src.battle.BattleState"] = function()
  return {
    newTrainer = function()
      return { enemy = { mon = {} }, enemyParty = { {} } }
    end,
    throwBall = function() end,
    storeCaughtMon = function() end,
    tryRun = function() end,
    drawTextArea = function() end,
    applyDamage = function(_, _, damage) return damage end,
    performMove = function() end,
    askNicknameUI = function() end,
  }
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

print("Registration bootstrap test passed.")
