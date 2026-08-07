# Colosseum Shadow System v1.6.0

A directly playable Pokémon Colosseum-style Shadow Pokémon vertical slice for Gen1Recomp.

## v1.6 reliability fixes

- `CALL` is now strictly tied to the player's active Shadow Pokémon. An enemy Shadow Pokémon never enables it, and the slot is explicitly repainted as `RUN` otherwise.
- The player-side dark aura is triggered at the actual Pokémon grow-in and rendered through Gen1Recomp's post-sprite `battle.overlay` hook.
- Eligible battle EXP is calculated from Gen1Recomp's EXP formula and stored in `expBank` without changing the Shadow Pokémon's level before purification.
- The `SHADOW DATA` page now displays the exact `EXP BANK` amount, or `LOCKED` before the Colosseum threshold is reached.
- Existing saves receive the restriction-test kit once at game load; the Researcher also restores Potion, Rare Candy, Thunder Stone, and TM24.
- Hyper Mode remains visibly marked in battle and on the summary screen.

## Core lifecycle

Snag the demo Shadow Pikachu from the Cipher Peon, open its five-section Heart Gauge through battle participation, walking, Call, Day Care or Scents, then purify it at the Relic Keeper. Before purification, evolution, Rare Candy, evolution stones, TM/HM teaching, move reordering, nickname and link trade are blocked. Eligible EXP is banked and applied only during purification. Purification removes all Shadow summary behavior while retaining the National Ribbon/history data.

See `INSTALL.md` for the focused v1.6 validation procedure and `COLOSSEUM_FIDELITY.md` for adaptations made for Gen1Recomp's single-battle engine.
