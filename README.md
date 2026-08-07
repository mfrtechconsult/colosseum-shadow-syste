# Colosseum Shadow System v1.7.0

A reusable Pokémon Colosseum-style Shadow Pokémon system for Gen1Recomp, with the original Pallet Town vertical slice retained as a playable demonstration.

## v1.7 reusable core

- Shadow state can now be configured per Pokémon instead of being hard-coded to the demo Pikachu.
- `shadowId`, Heart Gauge maximum, Shadow move, unlockable normal moves and post-purification moves can be supplied by another mod.
- Existing v1.6 saves remain compatible; the Pikachu demo values are still the defaults.
- The core is exposed through Gen1Recomp's supported inter-mod `mod.exports` API.
- A total conversion can disable the Pallet demo/test-kit behavior with `setDemoEnabled(false)` while keeping Heart Gauge, Hyper Mode, delayed EXP, restrictions and purification active.
- Generic Snag encounters and double-battle integration are intentionally reported as capabilities still in development rather than being silently emulated by the Pikachu demo path.

## EXP ownership

The Shadow system remains the single owner of delayed Shadow EXP:

- `battle.exp_award` intercepts the normal Gen1Recomp share;
- the exact Gen1Recomp EXP formula is used without mutating the Shadow Pokémon;
- eligible EXP is stored in `state.expBank` only after the appropriate Heart Gauge threshold;
- purification applies the bank, recalculates level/stats and clears the bank.

Consumers such as the Pokémon Colosseum total conversion must **not** implement a second EXP-bank system. They only define the species' ordinary growth curve; this mod owns Shadow-specific EXP behavior.

## Core lifecycle

Snag a Shadow Pokémon, open its five-section Heart Gauge through battle participation, walking, Call, Day Care or Scents, then purify it. Before purification, evolution, Rare Candy, evolution stones, TM/HM teaching, move reordering, nickname and link trade are blocked. Eligible EXP is banked and applied only during purification. Purification removes active Shadow summary behavior while retaining the National Ribbon/history data.

The bundled Pallet Town demo still uses Shadow Pikachu to exercise the complete lifecycle.

See `REUSABLE_API.md` for the inter-mod contract, `INSTALL.md` for the focused demo validation procedure and `COLOSSEUM_FIDELITY.md` for the current Gen1Recomp adaptations.
