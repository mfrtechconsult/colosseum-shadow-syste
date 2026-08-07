# Reusable Shadow API

`colosseum_shadow_system` exposes its supported cross-mod surface through Gen1Recomp's `mod.exports` mechanism.

A consuming mod should declare a manifest dependency once v1.7 is released:

```json
"dependencies": ["colosseum_shadow_system@^1.7"]
```

Then obtain the API from the dependency:

```lua
local shadowMod = assert(mod.find("colosseum_shadow_system"))
local Shadow = shadowMod.exports
assert(Shadow.apiVersion >= 1)
```

## Total-conversion mode

The bundled Pallet Town demonstration remains enabled by default for backwards compatibility.

A total conversion should disable only the demo behavior during its own entry function:

```lua
Shadow.setDemoEnabled(false)
```

This suppresses the demo test-kit and Pallet NPC setup while leaving the reusable Shadow runtime enabled.

## Attaching canonical Shadow data

```lua
local state = Shadow.attachForGame(game, mon, {
  shadowId = "shadow_makuhita",
  heartMax = 3000,
  shadowMove = "SHADOW_RUSH",
  normalMoves = {
    "FOCUS_ENERGY",
    "VITAL_THROW",
    "CROSS_CHOP",
  },
  purifiedMoves = {
    "FORESIGHT",
    "FOCUS_ENERGY",
    "VITAL_THROW",
    "CROSS_CHOP",
  },
})
```

`heartMax` is per encounter and is therefore suitable for the canonical Colosseum Heart Gauge values.

`normalMoves` are the moves progressively restored while the Heart Gauge opens. `purifiedMoves` is the final four-move set after purification. The older single `purificationMove` option is retained for the bundled Pikachu demo and compatibility.

## Exported functions

- `state(mon)` — returns the retained Shadow state or `nil`.
- `isActive(mon)` — true while the Pokémon is still Shadow and not purified.
- `section(state)` — current Heart Gauge section (5 closed → 0 ready to purify).
- `gauge(state)` — compact textual Heart Gauge representation.
- `expBankingEnabled(state)` — whether Colosseum's delayed EXP threshold is open.
- `attach(mon, data, config)` / `attachForGame(game, mon, config)` — attach/configure Shadow state.
- `configure(state, config)` — update reusable per-Pokémon configuration.
- `refreshMoves(mon, data)` — rebuild the currently available move list.
- `reduceHeart(mon, data, baseAmount, action, multiplier)` — open the Heart Gauge using the canonical action tables.
- `heartActionAmount(state, action, multiplier)` — inspect the canonical Nature/action value.
- `hyperRate(state)` — current Hyper Mode entry probability.
- `bankExperience(battle, mon, split)` — store the exact Gen1Recomp EXP share when eligible.
- `purify(game, mon)` — apply banked EXP, final moves and National Ribbon, then close Shadow state.
- `setDemoEnabled(enabled)` — enable/disable only the bundled Pallet demo behavior.

## EXP contract

Consumers must not manually award, subtract or re-bank EXP for active Shadow Pokémon.

The core already wraps `battle.exp_award`, computes the normal Gen1Recomp share, blocks it before the Heart Gauge threshold, stores it in `state.expBank` afterwards and applies it during purification.

A consuming total conversion is responsible only for registering the species' ordinary growth curve (for example `FAST`, `MEDIUM_FAST`, or a custom `FLUCTUATING` curve). The Shadow core then applies the stored amount against that same growth curve during purification.

## Capability flags

`Shadow.capabilities` currently reports:

```lua
{
  configurableShadowState = true,
  heartGauge = true,
  hyperMode = true,
  delayedExperience = true,
  purification = true,
  genericSnag = false,
  doubleBattleAware = false,
}
```

The `false` flags are deliberate. The existing Snag seam is still tied to the bundled demonstration trainer, and the current battle runtime is Gen1Recomp single-battle oriented. Those capabilities should be implemented here first, then consumed by the Colosseum total conversion.
