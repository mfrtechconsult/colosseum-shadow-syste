# Installation and test procedure

## Install

1. Fully close Gen1Recomp.
2. Delete the previous `colosseum_shadow_system` folder.
3. Extract the new folder directly into Gen1Recomp's `mods` directory.
4. Launch Gen1Recomp and enable **Colosseum Shadow System** with **F10**.

Existing saves and already-snagged demo Pokémon remain compatible.

## Focused v1.6 test

1. Check the Bag after loading: v1.6 grants Potion, Rare Candy, Thunder Stone and TM24 once to existing saves. Talking to the Researcher also restores the kit.
2. Fight the Cipher Peon with a normal Pokémon active. The bottom-right command must visibly be **RUN**, not CALL, even while enemy Shadow Pikachu is present.
3. Snag Pikachu, then enter another battle and switch it in. `CALL` must replace RUN only while Pikachu is active.
4. When Shadow Pikachu actually emerges from its Ball, the player-side dark-aura effect and `DARK AURA!` label must appear. Switching it out and back in must replay the cue.
5. Hyper Mode must show `HYPER`; Potion must be refused in Hyper Mode and CALL must clear it.
6. Before purification, Rare Candy, Thunder Stone and TM24 must be refused.
7. Open the Heart Gauge until the third page shows a numeric **EXP BANK** rather than `LOCKED`. Defeat at least one enemy with Pikachu participating. The stored amount must increase above zero and Pikachu must not level yet.
8. Purify it. The purification result must apply/report the stored EXP; any resulting level gain must occur only now.
9. After purification, only the ordinary two summary pages must remain.

If EXP BANK still reads `LOCKED`, receiving zero stored EXP is expected: Colosseum does not start banking EXP until the Nature/EXP Heart Gauge threshold has been opened.
