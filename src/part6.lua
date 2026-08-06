return function(mod)
  registerContent(mod)
  registerCommands(mod)
  registerPalletScripts(mod)
  installBattleRuntime(mod)
  installShadowUIRuntime(mod)

  mod.hooks:wrap("battle.crit", function(next, ctx)
    local mon = ctx and ctx.attacker and ctx.attacker.mon
    local state = shadow(mon)
    local moveId = ctx and ctx.moveId
    if moveId == SHADOW_MOVE and state and state.hyperMode then
      local rng = ctx.rng or math.random
      if rng(0, 255) < 230 then return true end
    end
    return next(ctx)
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

      local Experience = require("src.battle.Experience")
      local clone = copy(mon)
      local _, gained = Experience.apply(ctx.battle.data, clone,
        ctx.battle.enemy.def, ctx.battle.enemy.mon.level,
        ctx.battle.kind == "trainer", split, mon.traded)
      state.expBank = (state.expBank or 0) + (gained or 0)
      if announce then
        local Strings = require("src.core.Strings")
        ctx.battle:sayNext(Strings("%s gained\n%d EXP. Points!",
          monName(ctx.battle.game, mon), gained or 0))
        ctx.battle:sayNext("The EXP. was stored\nuntil purification.")
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
    if state and state.shadowId == SHADOW_ID then
      mod.save:set("encounter_status", "snagged")
      mod.save:set("encounter_snapshot", false)
      refreshShadowMoves(ev.mon, ev.game.data)
    end
  end)

  mod.events:on("battle.started", function(ev)
    local battle = ev.battle
    local mon = battle and battle.player and battle.player.mon
    if isActiveShadow(mon) then
      local result = reduceHeart(mon, battle.data, 500, "BATTLE_ENTRY")
      if result and result.threshold then
        battle:sayNext("The door to its heart\nopened a little!")
      end
    end
  end)

  mod.events:on("battle.turn_started", function(ev)
    local battle = ev.battle
    local mon = battle and battle.player and battle.player.mon
    local state = shadow(mon)
    if state and state.isShadow and state.hyperMode
       and battle.rng(0, 255) == 0 then
      state.hyperMode = false
      battle:sayNext(monName(battle.game, mon)
        .. " came to its senses!")
    end
  end)

  mod.events:on("game.ready", function(ev)
    installBattleRuntime(mod)
    refreshPartyShadowMoves(ev.game)
    local ow = ev.game and ev.game.overworld
    if ow and ow.map and ow.map.id == PALLET then
      ensurePalletNpcs(mod, ev.game, ow)
    end
  end)
end
