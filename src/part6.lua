return function(mod)
  local demoEnabled = true

  registerContent(mod)
  registerCommands(mod)
  registerPalletScripts(mod)
  installBattleRuntime(mod)
  installShadowUIRuntime(mod)
  installPurifiedSummaryLifecycle()

  -- Stable inter-mod surface. Total conversions should consume Shadow behavior
  -- through mod.find("colosseum_shadow_system").exports instead of requiring
  -- this mod's private implementation files.
  mod.exports.apiVersion = 1
  mod.exports.capabilities = {
    configurableShadowState = true,
    heartGauge = true,
    hyperMode = true,
    delayedExperience = true,
    purification = true,
    genericSnag = true,
    doubleBattleAware = false,
  }
  mod.exports.state = shadow
  mod.exports.isActive = isActiveShadow
  mod.exports.section = section
  mod.exports.gauge = gauge
  mod.exports.expBankingEnabled = expBankingEnabled
  mod.exports.refreshMoves = refreshShadowMoves
  mod.exports.configure = configureShadow
  mod.exports.attach = function(mon, data, config)
    return attachShadow(mon, data, config)
  end
  mod.exports.attachForGame = function(game, mon, config)
    assert(game and game.data, "attachForGame requires a live game")
    return attachShadow(mon, game.data, config)
  end
  mod.exports.reduceHeart = reduceHeart
  mod.exports.heartActionAmount = heartActionAmount
  mod.exports.hyperRate = hyperRate
  mod.exports.bankExperience = bankShadowExperience
  mod.exports.purify = purify
  mod.exports.registerTrainerEncounter = registerShadowTrainerEncounter
  mod.exports.unregisterTrainerEncounter = unregisterShadowTrainerEncounter
  mod.exports.trainerEncounter = shadowTrainerEncounter
  mod.exports.setSnagAccessCheck = setSnagAccessCheck
  mod.exports.setDemoEnabled = function(enabled)
    demoEnabled = enabled ~= false
  end
  mod.exports.isDemoEnabled = function() return demoEnabled end

  mod.hooks:wrap("battle.crit", function(next, ctx)
    local mon = ctx and ctx.attacker and ctx.attacker.mon
    local state = shadow(mon)
    local moveId = ctx and ctx.moveId
    if state and moveId == (state.shadowMove or SHADOW_MOVE) and state.hyperMode then
      local rng = ctx.rng or math.random
      -- 232/256 is Colosseum's exact 90.625% Hyper Mode critical rate.
      -- Bypass Gen 1's Speed-based critical formula for this move.
      return rng(0, 255) < 232
    end
    return next(ctx)
  end)

  -- v1.6 presentation lives in battle.overlay, which Gen1Recomp renders
  -- after HUDs and battler sprites. This makes the player-side aura visible
  -- regardless of the classic/SGB draw pipeline used underneath.
  mod.hooks:wrap("battle.overlay", function(next, battle)
    next(battle)
    if not (battle and love and love.graphics) then return end
    local mon = battle.player and battle.player.mon
    local state = shadow(mon)
    if not (state and state.isShadow) then return end

    local start = battle._colosseumPlayerAuraStartV16
    if start == nil then return end
    local age = (battle.frame or 0) - start
    if age < 0 or age >= 48 then return end

    local Font = require("src.render.Font")
    local g = love.graphics
    local cx, cy = 32, 62
    g.setColor(0, 0, 0, 1)
    for i = 0, 9 do
      local angle = (i / 10) * math.pi * 2 + age * 0.18
      local radius = 20 + ((age + i * 5) % 14)
      local x = math.floor(cx + math.cos(angle) * radius)
      local y = math.floor(cy + math.sin(angle) * (radius * 0.72))
      local size = 1 + ((i + age) % 3)
      g.rectangle("fill", x, y, size, size)
    end
    local pulse = 2 + (age % 8)
    g.rectangle("line", cx - 22 - pulse / 2, cy - 22 - pulse / 2,
      44 + pulse, 44 + pulse)
    g.setColor(1, 1, 1, 1)
    g.rectangle("fill", 0, 34, 82, 10)
    g.setColor(0, 0, 0, 1)
    Font.draw("DARK AURA!", 2, 35)
    g.setColor(1, 1, 1, 1)
  end)

  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local originalApply = ctx.applyShare
    ctx.applyShare = function(mon, split, announce)
      local state = shadow(mon)
      if not state or not state.isShadow then
        return originalApply(mon, split, announce)
      end

      if not expBankingEnabled(state) then
        if announce then
          ctx.battle:sayNext("The door to its heart\nblocked the EXP!")
        end
        return
      end

      local gained = select(1, bankShadowExperience(ctx.battle, mon, split)) or 0
      if announce then
        local Strings = require("src.core.Strings")
        ctx.battle:sayNext(Strings("%s gained\n%d EXP. Points!",
          monName(ctx.battle.game, mon), gained))
        ctx.battle:sayNext(Strings("Stored EXP: %d",
          state.expBank or 0))
      end
    end
    return next(ctx)
  end)

  mod.hooks:wrap("evolution.check", function(next, game, mon, evo, trigger)
    if isActiveShadow(mon) then return false end
    return next(game, mon, evo, trigger)
  end)

  mod.events:on("pokemon.caught", function(ev)
    local state = shadow(ev.mon)
    if not state then return end
    refreshShadowMoves(ev.mon, ev.game.data)
    if demoEnabled and state.shadowId == SHADOW_ID then
      mod.save:set("encounter_status", "snagged")
      mod.save:set("encounter_snapshot", false)
    end
  end)

  local function cuePlayerShadowAura(battle, battler)
    if battle and battler and battler.isPlayer and isActiveShadow(battler.mon) then
      battle._colosseumPlayerAuraStartV16 = battle.frame or 0
    end
  end

  local function countParticipation(battle, battler)
    if not battle then return end
    local marker = require("src.battle.BattleState")
      ._colosseumMarkParticipationV13
    local result = marker and marker(battle, battler)
    if result and result.threshold then
      battle:sayNext("The door to its heart\nopened a little!")
    end
  end

  mod.events:on("battle.started", function(ev)
    local battle = ev.battle
    cuePlayerShadowAura(battle, battle and battle.player)
    countParticipation(battle, battle and battle.player)
  end)

  mod.events:on("battle.battler_switched", function(ev)
    -- Aura timing is cued by BattleState:startGrowIn, after the send-out text
    -- and POOF. This event remains responsible for Heart participation only.
    countParticipation(ev.battle, ev.battler)
  end)

  mod.events:on("battle.turn_started", function(ev)
    local battle = ev.battle
    local mon = battle and battle.player and battle.player.mon
    local state = shadow(mon)
    if state and state.isShadow and state.hyperMode
       and battle.rng(0, 255) == 0 then
      state.hyperMode = false
      local result = reduceHeart(mon, battle.data, nil, "NATURAL_RECOVERY")
      battle:sayNext(monName(battle.game, mon)
        .. " came to its senses!")
      if result and result.threshold then
        battle:sayNext("The door to its heart\nopened a little!")
      end
    end
  end)

  mod.events:on("game.ready", function(ev)
    installBattleRuntime(mod)
    refreshPartyShadowMoves(ev.game)
    if not demoEnabled then return end

    -- Existing saves that installed v1.5 after already talking to the
    -- Researcher never re-ran setupPlayer, so they never received the test
    -- items. Grant the v1.6 kit once on load as well as on Researcher talk.
    if not mod.save:get("test_kit_v16", false) then
      grantShadowTestKit(ev.game)
      mod.save:set("test_kit_v16", true)
    end
    local ow = ev.game and ev.game.overworld
    if ow and ow.map and ow.map.id == PALLET then
      ensurePalletNpcs(mod, ev.game, ow)
    end
  end)
end
