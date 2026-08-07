-- Purification summary lifecycle.
--
-- Pokémon Colosseum removes the Shadow information page once purification is
-- complete. The saved Shadow record is retained for the National Ribbon and
-- encounter history, but it is hidden from Gen1Recomp's summary renderer so
-- the Pokémon immediately returns to the ordinary two-page summary.

function installPurifiedSummaryLifecycle()
  local ok, SummaryMenu = pcall(require, "src.ui.SummaryMenu")
  if not ok or type(SummaryMenu) ~= "table"
     or SummaryMenu._colosseumPurifiedSummaryV1 then
    return
  end
  SummaryMenu._colosseumPurifiedSummaryV1 = true

  local previousUpdate = SummaryMenu.update
  local previousDraw = SummaryMenu.draw

  local function isPurified(mon)
    local state = shadow(mon)
    return state and state.purified == true and state.isShadow ~= true
  end

  local function withoutShadowRecord(self, fn, ...)
    local mon = self.mon
    local state = mon and mon.colosseumShadow
    if not state then return fn(self, ...) end

    -- Part 7 now rejects non-active Shadow records itself. This extra guard
    -- keeps the ordinary renderer isolated from the retained history record
    -- and protects against other wrappers that inspect that record directly.
    mon.colosseumShadow = nil
    local results = { pcall(fn, self, ...) }
    mon.colosseumShadow = state
    local succeeded = table.remove(results, 1)
    if not succeeded then error(results[1], 0) end
    return unpack(results)
  end

  SummaryMenu.update = function(self, dt)
    if not isPurified(self.mon) then
      return previousUpdate(self, dt)
    end

    -- Also repairs a summary that was already sitting on page 3 when a new
    -- mod version was loaded.
    if (self.page or 1) > 2 then self.page = 2 end
    return withoutShadowRecord(self, previousUpdate, dt)
  end

  SummaryMenu.draw = function(self)
    if not isPurified(self.mon) then
      return previousDraw(self)
    end
    return withoutShadowRecord(self, previousDraw)
  end
end
