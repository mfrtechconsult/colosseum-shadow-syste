# Pokémon Colosseum fidelity notes

## Directly reproduced rules

- Five Heart Gauge sections and the original progression messages.
- Original Colosseum Nature/action reductions for battle, Call, party walking,
  Day Care walking, and Joy Scent; Excite and Vivid use 2× and 3× multipliers.
- One battle-participation reduction per Shadow Pokémon per battle.
- One independent walking trigger per Pokémon every 256 steps.
- First normal move after the first section, Nature and EXP after the second,
  second normal move after the third, and third normal move after the fourth.
- Shadow Rush remains until the purification ceremony and does not consume PP.
- Shadow Rush recoil is based on maximum HP with the original ±1 variation.
- Hyper Mode is entered only while attempting Shadow Rush and consumes the
  turn that triggered it.
- Hyper Mode entry rates use the Nature/Heart-stage table.
- Hyper Shadow Rush critical chance is 232/256 (90.625%).
- Call wakes sleep, ends Hyper Mode, opens the heart, and otherwise wastes a
  turn.
- Hyper Mode prevents item use on that Pokémon and ends on fainting, Call,
  Scent, Day Care, or rare natural recovery.
- EXP is unavailable at first, then banked without changing level until
  purification. Stat EXP is not banked.
- No evolution, Rare Candy, evolution stone, TM/HM teaching, move reordering,
  nickname, or link trade before purification.
- Day Care gives Heart progress but no level/EXP progress.
- Purification applies stored EXP, removes Shadow Rush, permits naming, and
  stores the National Ribbon marker.

## Engine adaptations

- **Summary layout:** Colosseum replaces the EXP area with the Heart Gauge.
  Gen1Recomp's compact two-page status screen has no equivalent area, so an
  active Shadow Pokémon receives a third SHADOW DATA page. That page is removed
  after purification.
- **Battle format:** Colosseum is predominantly double battle. Gen1Recomp is a
  single-battle engine, so disobedience outcomes that target the player's
  partner or a trainer are represented as a lost turn and matching text.
- **Run/Call compatibility:** all Trainer battles use CALL. Normal Kanto wild
  encounters retain RUN unless the active Pokémon is Shadow or asleep; this
  prevents the mod from making ordinary Kanto exploration inescapable.
- **Demo purification:** the Relic Keeper NPC represents the Relic Stone flow.
- **Demo target:** Pikachu is a custom test target and uses a 5000-point full
  gauge. Original Colosseum species had species-specific full-gauge values.
- **Friendship:** Gen1Recomp does not expose the Generation III friendship
  lifecycle used by Colosseum, so only stored EXP is applied at purification.
- **Hyper disobedience weights:** the original outcome categories are present,
  but their internal weighting is adapted to Gen1Recomp's single-battle action
  model. Entry rates, critical rate, restrictions, persistence, and exit rules
  are reproduced separately.
