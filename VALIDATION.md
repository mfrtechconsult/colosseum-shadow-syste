# Validation report

Validated on 2026-08-07.

## Automated checks

- Loader and all ten `src/part*.lua` files: syntax PASS
- All test files: syntax PASS
- Five Heart Gauge thresholds and move unlocks: PASS
- All 25 Nature/action records: PASS
- Joy/Vivid Scent multiplier behavior: PASS
- All six Hyper Mode probability stages: PASS
- Exact 232/256 Hyper critical boundary: PASS
- Individual 256-step counter: PASS
- Once-per-Pokémon battle participation: PASS
- Active-Pokémon CALL availability rules, including enemy-Shadow isolation: PASS
- Hyper item refusal and Scent exception: PASS
- Rare Candy, evolution stone, and TM/HM restrictions: PASS
- Move-reordering restriction: PASS
- Link-trade restriction: PASS
- Day Care EXP suppression and Hyper recovery: PASS
- Rare natural Hyper recovery: PASS
- Shadow battle badge visibility: PASS
- Player-owned Shadow send-out aura bootstrap: PASS
- Hyper Mode battle indicator bootstrap: PASS
- Researcher restriction-test kit grants: PASS
- Active Shadow third summary page: PASS
- Purified summary returns to vanilla two-page behavior: PASS
- Stale page 3 normalization after hot reload: PASS
- Purified summary bypasses Shadow UI at the primary summary wrapper: PASS
- Purification animation bridge / headless fallback: PASS
- API 2 registration bootstrap: PASS
- Packaged ZIP re-extraction and complete test suite: PASS

## Scope and limitation

The checks validate syntax, formulas, runtime wrapper installation, content and
hook registration, menu restrictions, state transitions, summary navigation,
purification-ceremony control flow, and package structure.

A complete graphical playthrough still requires the user's current
Gen1Recomp installation and private ROM-derived cache. No ROM or extracted
Pokémon assets are included. The purification ceremony and battle aura visual
timing/placement remain subject to in-game validation.
