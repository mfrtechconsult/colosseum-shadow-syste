# Colosseum Shadow System v1.1.1

A directly playable Shadow Pokémon vertical slice for Gen1Recomp.

The mod is entirely in English in-game and places four test NPCs outside in
Pallet Town. It does not replace any original Pallet Town NPC.

## Pallet Town test NPCs

- **Researcher** — gives the Snag Machine, restores at least 25 Poké Balls,
  heals the party, and supplies a level 15 Eevee when the player has no
  Pokémon. After the demo, the Researcher can reset it.
- **Cipher Peon** — starts a Trainer battle against a Shadow Pikachu.
- **Shadow Monitor operator** — optional debug display for encounter state.
  Normal progression tracking is available directly from the Pokémon summary
  screen in the party or PC.
- **Relic Keeper** — applies Vivid Scent for fast testing and performs
  purification once the Heart Gauge reaches zero.

NPC positions are chosen dynamically from free, walkable Pallet Town cells.
This prevents the mod from overwriting vanilla NPCs or blindly overlapping
another mod's runtime objects.

## Implemented test cycle

1. Obtain the Snag Machine and Poké Balls.
2. Fight a Cipher Peon.
3. Throw a normal Ball at the Trainer's Shadow Pikachu.
4. The Snag Machine converts the Ball and uses the normal Ball catch formula.
5. On success, the exact enemy instance joins the party or PC.
6. Open its heart through walking, battle entry, Call, or Vivid Scent.
7. Trigger and clear Hyper Mode.
8. Store EXP after the Nature threshold.
9. Purify at the Relic Keeper.
10. Replace Shadow Rush, apply stored EXP, unlock naming, and award the
    National Ribbon marker.

## Mechanics included

- Animated dark-aura reveal and a SHADOW badge shown only while the actual
  Shadow battler sprite is visible.
- A third SHADOW DATA page in the normal Pokémon summary screen, including
  Heart Gauge, Nature visibility, Hyper Mode, unlocked moves, walking progress,
  and stored EXP.
- Shadow type with neutral effectiveness.
- Shadow Rush: 90 power, 100 accuracy, no consumed PP, recoil based on
  maximum HP, and an additional Hyper Mode critical roll.
- Five-section Heart Gauge.
- Move unlocking at the Colosseum thresholds.
- Hidden Nature until the appropriate threshold.
- Per-Pokémon 256-step opening counter on every map.
- Hyper Mode entry, disobedience, natural recovery, Call, and persistence.
- Trainer-Pokémon capture through the Snag Machine.
- No nickname before purification.
- No evolution before purification.
- Delayed EXP banking and application.
- Purification and National Ribbon state.
- Party and PC persistence through ordinary Gen1Recomp saves.
- Rematch after a knockout and full demo reset.

## Accuracy note

The overall state machine and gameplay flow follow Pokémon Colosseum. The
exact per-Nature Heart Gauge coefficients and all hidden Hyper Mode outcome
weights are not publicly documented with enough certainty to claim
bit-perfect parity. They are isolated in `main.lua` so verified constants can
replace them without redesigning the system. No unverified value is labelled
as exact.
