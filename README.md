# Colosseum Shadow System v1.4.0

A directly playable Pokémon Colosseum-style Shadow Pokémon vertical slice for
Gen1Recomp. All player-facing mod text is written in English.

Four runtime NPCs are placed on free walkable cells in Pallet Town. Vanilla
NPCs and map objects are not replaced.

## Pallet Town test NPCs

- **Researcher** — gives the Snag Machine, restores Poké Balls, heals the
  party, supplies a level 15 Eevee when needed, and resets the demo.
- **Cipher Peon** — starts a Trainer battle against a Shadow Pikachu.
- **Shadow Monitor operator** — optional debug/status display.
- **Relic Keeper** — applies Vivid Scent and performs purification when the
  Heart Gauge reaches zero.

## Test cycle

1. Obtain the Snag Machine from the Researcher.
2. Fight the Cipher Peon and Snag the Shadow Pikachu with a normal Poké Ball.
3. Inspect the Pokémon's third **SHADOW DATA** summary page.
4. Open its heart through battle participation, walking, Call, Day Care, or
   Vivid Scent.
5. Trigger Hyper Mode with Shadow Rush and end it with Call, Scent, fainting,
   Day Care, or the rare natural recovery roll.
6. Bank EXP after the correct Heart Gauge threshold.
7. Empty the gauge and purify the Pokémon at the Relic Keeper.
8. Apply stored EXP, replace Shadow Rush, unlock naming, and award the
   National Ribbon marker.
9. After purification, the Pokémon immediately returns to the ordinary
   two-page summary with no Shadow badge or SHADOW DATA page.

## Colosseum fidelity

- Exact 25-Nature values for battle participation, Call, party walking,
  Day Care walking, and Scents.
- Individual 256-step Heart counters for party and Day Care Pokémon.
- A Pokémon receives the battle-participation reduction once per battle,
  including when first sent out after a switch.
- Correct Heart thresholds for normal-move recovery, Nature reveal, EXP
  banking, and purification readiness.
- Locked moves remain visible as `????` with `??/??` PP.
- Shadow Rush stays available until purification, consumes no PP, renders
  `--/--`, has 90 power, and uses max-HP recoil with the Colosseum variation.
- Nature- and Heart-stage-specific Hyper Mode entry rates.
- Hyper Shadow Rush uses a 232/256 critical rate (90.625%).
- Hyper Mode may cause disobedience on non-Shadow Rush moves and blocks bag
  items used on that Pokémon, while Scents remain valid.
- Call replaces Run in Trainer battles and whenever it is needed by the active
  Pokémon in a wild battle. Call wakes sleep or ends Hyper Mode and otherwise
  wastes the turn.
- Hyper Mode ends on fainting, Call, Scent, Day Care, or rare natural recovery.
- Shadow Pokémon cannot use Rare Candy, evolution stones, TMs/HMs, evolve,
  reorder moves, receive a nickname, or be selected for link trade.
- Shadow Pokémon receive no normal battle EXP before the correct threshold;
  eligible EXP is stored and applied during purification.
- Day Care opens the Heart Gauge but grants no Day Care EXP to a Shadow
  Pokémon.
- Purification retains the National Ribbon/history data while removing all
  Shadow-specific summary behavior.

## Purification ceremony in v1.4.0

- Purification now opens a dedicated full-screen ceremony inspired by
  Gen1Recomp's evolution movie.
- The Pokémon sprite pulses while dark rings collapse toward it, then its
  Shadow state is removed at the visual climax and its normal cry plays.
- Purified Pokémon are now gated by `isActiveShadow()` at the summary layer
  itself, so the SHADOW marker and third SHADOW DATA page cannot survive
  purification merely because the National Ribbon/history record is retained.

## Deliberate host-game adaptations

Gen1Recomp is a Generation I single-battle engine, while Pokémon Colosseum is
a Generation III double-battle game. The unavoidable adaptations are recorded
in `COLOSSEUM_FIDELITY.md`. Most visibly, Shadow information uses a third
summary page instead of replacing the EXP area, and trainer/partner-targeting
Hyper disobedience outcomes are represented as lost-turn messages.

The demo target is Pikachu, which was not a Shadow Pokémon in the original
Colosseum roster. Its full Heart Gauge value of 5000 is therefore a test value;
the Nature/action reductions and thresholds themselves follow Colosseum.
