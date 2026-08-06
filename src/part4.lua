function registerCommands(mod)
  local function show(ctx, text)
    require("src.script.Commands").show_text(ctx, text)
  end

  mod.content.commands:register("colosseum:researcher", {
    foreground = true,
    fn = function(ctx)
      local Commands = require("src.script.Commands")
      local status = mod.save:get("encounter_status", "available")
      if status == "snagged" or status == "purified" then
        Commands.ask(ctx,
          "RESEARCHER: Reset the\nSHADOW POKéMON demo?\nThe demo target will\nbe removed.")
        if ctx.lastCheck then
          resetEncounter(mod, ctx.game)
          setupPlayer(mod, ctx.game)
          show(ctx, "The demonstration\nhas been reset.\fTalk to the CIPHER\nPEON to begin.")
          return
        end
      end

      local added = setupPlayer(mod, ctx.game)
      local text = "RESEARCHER: This is\na SNAG MACHINE.\f"
        .. "It converts ordinary\nBALLS into SNAG BALLS\nagainst SHADOW POKéMON."
      if added then
        text = text .. "\fYou had no POKéMON,\nso take this EEVEE\nfor the field test."
      end
      text = text .. "\fYour party is healed.\nYou now have at least\n25 POKé BALLS."
      show(ctx, text)
    end,
  })

  mod.content.commands:register("colosseum:check_demo", {
    foreground = true,
    fn = function(ctx)
      ctx.lastCheck = mod.save:get("encounter_status", "available") == "available"
    end,
  })

  mod.content.commands:register("colosseum:after_demo", {
    foreground = true,
    fn = function(ctx)
      local result = ctx.lastBattleResult
      if result == "caught" then
        mod.save:set("encounter_status", "snagged")
        mod.save:set("encounter_snapshot", false)
        show(ctx, "SNAG COMPLETE!\fThe SHADOW POKéMON\nwas transferred to\nyour party or PC.")
      elseif result == "win" then
        show(ctx, "The SHADOW POKéMON\nwas knocked out.\fThe CIPHER PEON will\nrestore it for a rematch.")
      elseif result == "lose" then
        show(ctx, "The field test failed.\nYour target remains\navailable.")
      else
        show(ctx, "The target remains\navailable for another\ntest.")
      end
    end,
  })

  mod.content.commands:register("colosseum:monitor", {
    foreground = true,
    fn = function(ctx)
      local status = mod.save:get("encounter_status", "available")
      local mon, location = findDemoShadow(ctx.save)
      if not mon then
        local label = status == "available" and "READY TO SNAG" or string.upper(status)
        show(ctx, "SHADOW POKéMON LIST\f"
          .. "No. 001  PIKACHU\nSTATUS: " .. label
          .. "\fTalk to the CIPHER\nPEON for the encounter.")
        return
      end

      local state = shadow(mon)
      local nature = natureVisible(state) and state.nature or "????"
      local mode = state.hyperMode and "HYPER MODE" or "NORMAL"
      local stateLabel = state.purified and "PURIFIED" or "SNAGGED"
      show(ctx, "SHADOW POKéMON LIST\f"
        .. "No. 001  " .. monName(ctx.game, mon)
        .. "\nSTATUS: " .. stateLabel
        .. "\nLOCATION: " .. string.upper(location or "UNKNOWN")
        .. "\fHEART " .. gauge(state)
        .. "\nNATURE: " .. nature
        .. "\nMODE: " .. mode
        .. "\nSTORED EXP: " .. tostring(state.expBank or 0))
    end,
  })

  mod.content.commands:register("colosseum:relic", {
    foreground = true,
    fn = function(ctx)
      local Commands = require("src.script.Commands")
      local Screens = require("src.ui.Screens")
      local mon = findDemoShadow(ctx.save)
      if not mon then
        show(ctx, "RELIC KEEPER: Bring me\na snagged SHADOW\nPOKéMON.")
        return
      end

      local state = shadow(mon)
      if state.purified then
        show(ctx, "This POKéMON has\nalready opened the\ndoor to its heart.")
        return
      end

      if (state.heart or 0) > 0 then
        Commands.ask(ctx,
          "Use a VIVID SCENT?\nIt quickly opens the\nheart for this demo.")
        if not ctx.lastCheck then
          show(ctx, "Walk, battle, CALL,\nor return when ready.")
          return
        end
        state.hyperMode = false
        local result = reduceHeart(mon, ctx.game.data, 1000, "VIVID_SCENT")
        local text = monName(ctx.game, mon) .. "'s heart\nopened wider!\fHEART "
          .. gauge(state)
        if result and result.threshold then
          text = text .. "\fA new ability became\navailable."
        end
        if state.heart == 0 then
          text = text .. "\fThe final lock can now\nbe undone."
        end
        show(ctx, text)
        return
      end

      Commands.ask(ctx,
        "The door to its heart\nis open.\nPurify this POKéMON?")
      if not ctx.lastCheck then return end

      local ok, bank, oldLevel = purify(ctx.game, mon)
      if not ok then
        show(ctx, "Purification failed.")
        return
      end
      mod.save:set("encounter_status", "purified")
      local text = monName(ctx.game, mon) .. " opened the\ndoor to its heart!"
        .. "\fSHADOW RUSH was\nreplaced by\nQUICK ATTACK."
      if bank and bank > 0 then
        text = text .. "\fIt received " .. tostring(bank)
          .. " stored EXP."
        if mon.level > oldLevel then
          text = text .. "\nIt grew to Lv." .. tostring(mon.level) .. "!"
        end
      end
      text = text .. "\fIt received the\nNATIONAL RIBBON."
      show(ctx, text)

      Commands.ask(ctx, "Give it a nickname?")
      if ctx.lastCheck then
        local runner = ctx.runner
        Screens.push(ctx.game, "NamingScreen", {
          title = "NICKNAME?",
          maxLen = 10,
          onDone = function(name)
            if name and #name > 0 then mon.nickname = name end
            runner:resume()
          end,
        })
        runner:yield()
      end
    end,
  })
end

function registerPalletScripts(mod)
  local palletScript = {
    talk = {
      TEXT_COLO_RESEARCHER = { { "colosseum:researcher" } },
      TEXT_COLO_CIPHER = {
        { "colosseum:check_demo" },
        { "jump_if_false", "gone" },
        { "show_text",
          "CIPHER PEON: This\nPIKACHU belongs to us!\f"
          .. "Try taking it with\nyour little machine!" },
        { "start_battle", "trainer", TRAINER_ID, 1 },
        { "colosseum:after_demo" },
        { "jump", "end" },
        { "label", "gone" },
        { "show_text",
          "CIPHER PEON: The test\ntarget is gone.\f"
          .. "Ask the RESEARCHER\nto reset the demo." },
      },
      TEXT_COLO_MONITOR = { { "colosseum:monitor" } },
      TEXT_COLO_RELIC = { { "colosseum:relic" } },
    },
    onEnter = function(game, ow)
      ensurePalletNpcs(mod, game, ow)
      refreshPartyShadowMoves(game)
    end,
    onStep = function(game)
      stepHeart(game)
    end,
    priority = 100,
  }
  mod.content.map_scripts:register(PALLET, palletScript)

  -- Heart-opening steps are global, not restricted to the demonstration map.
  for mapId in mod.content.maps:each() do
    if mapId ~= PALLET then
      mod.content.map_scripts:register(mapId, {
        onStep = function(game) stepHeart(game) end,
        priority = -100,
      })
    end
  end
end

