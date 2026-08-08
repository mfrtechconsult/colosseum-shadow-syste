# Colosseum Shadow System v1.6.0

This release focuses on battle-state correctness, Shadow presentation, and reliable stored EXP behavior before purification.

## Highlights

- `CALL` now depends only on the player's active Shadow Pokémon. An enemy Shadow Pokémon can no longer make `CALL` appear for a normal player Pokémon.
- Player-owned Shadow Pokémon now trigger a `DARK AURA!` presentation when they are actually sent out and become visible in battle.
- Hyper Mode remains visibly indicated during battle and in Shadow summary data.
- Stored EXP now uses Gen1Recomp's own EXP formula and is banked without changing the Pokémon's level or normal EXP before purification.
- `SHADOW DATA` now exposes the current `EXP BANK`, making it possible to verify accumulation before purification.
- Purification still applies stored EXP, removes Shadow-specific behavior, keeps the National Ribbon/history marker, and returns the Pokémon to the normal two-page summary.
- The Researcher provides/restores the testing kit used to validate Shadow restrictions.

## Test kit

The Researcher supplies or restores:

- 25 Poké Balls minimum
- 5 Potions
- 3 Rare Candies
- 1 Thunder Stone
- 1 TM24

These are intended to validate item restrictions before and during Hyper Mode.

## Recommended validation

1. Start the Cipher Peon battle with a normal Pokémon: the command must remain `RUN`, even though the opposing Pikachu is Shadow.
2. Send out the snagged Shadow Pikachu: `DARK AURA!` should play when its sprite appears.
3. Trigger Hyper Mode and confirm the `HYPER` indicator appears.
4. Try a Potion during Hyper Mode: it must be refused.
5. Try Rare Candy, Thunder Stone and TM24 before purification: they must be refused.
6. Open the Heart Gauge far enough to unlock EXP banking, then win a battle and confirm `EXP BANK` increases.
7. Purify Pikachu and confirm the stored EXP is applied and `EXP BANK` resets.
8. Re-open the summary after purification: no Shadow marker or `SHADOW DATA` page should remain.

## Installation

1. Fully close Gen1Recomp.
2. Delete the previous `colosseum_shadow_system` folder.
3. Extract the v1.6.0 `colosseum_shadow_system` folder into Gen1Recomp's `mods` directory.
4. Launch Gen1Recomp and enable the mod from the mod manager.

Existing saves and already-snagged demo Pokémon remain compatible.

## Release assets

- `colosseum_shadow_system_v1.6.0.zip`
- `colosseum_shadow_system_v1.6.0.sha256`

SHA-256 of the ZIP:

`a45fdf197bf6edbbeb65c8d284573416b9db1c15fb288a71349a807d0c20a69d`

## Notes

Gen1Recomp is a Generation I single-battle engine, so a few Colosseum behaviors remain host-engine adaptations. See `COLOSSEUM_FIDELITY.md` for the documented differences.
