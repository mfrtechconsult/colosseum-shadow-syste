# Installation and test procedure

## Install

1. Use a current Gen1Recomp build based on the `dev` mod API.
2. Fully close Gen1Recomp.
3. Delete the previous `colosseum_shadow_system` folder.
4. Extract the new folder directly into Gen1Recomp's `mods` directory.
5. Launch Gen1Recomp and enable **Colosseum Shadow System** with **F10**.
6. Load a game and enter Pallet Town.

The final path must look like:

```text
Gen1Recomp/
└── mods/
    └── colosseum_shadow_system/
        ├── manifest.json
        ├── main.lua
        ├── src/
        └── README.md
```

Existing saves and already-snagged demo Pikachu are retained.

## Main v1.5 test

1. Talk to the **Researcher**. Confirm the TEST KIT includes Potion, Rare
   Candy, Thunder Stone, and TM24, then fight the **Cipher Peon**.
2. Confirm the dark-aura reveal appears after Pikachu is sent out.
3. Confirm the SHADOW badge appears only beside the visible Shadow Pokémon.
4. Snag Pikachu with a Poké Ball.
5. Inspect it: pages 1 and 2 show the SHADOW marker; page 2 shows Shadow Rush
   as `--/--` and locked moves as `????`; page 3 shows **SHADOW DATA**.
6. Enter a normal Trainer battle with a normal awake lead: `RUN` must remain.
   Switch to Shadow Pikachu: `CALL` must then replace `RUN`.
7. Switch Shadow Pikachu into battle, switch it out, then send it back in.
   The same dark-aura send-out cue should play each time it becomes visible.
   Its Heart Gauge must receive the battle reduction only on the first entry.
8. Use Shadow Rush until Hyper Mode starts. Confirm a persistent `HYPER` marker
   appears in battle and on summary pages 1/2; page 3 must show `HYPER MODE`.
   Then test a recovered normal move for possible disobedience.
9. In Hyper Mode, try a Potion on Pikachu: it must be refused. Choose `CALL`:
   Hyper Mode must end and the Heart Gauge must open according to its Nature.
10. In a normal wild battle with a normal awake lead, confirm `RUN` remains
    available. With Shadow Pikachu active, confirm `CALL` replaces it.
11. Try Rare Candy, Thunder Stone, TM24, move reordering with SELECT, and a
    link trade selection: each must be blocked before purification.
12. Put Pikachu in Day Care and walk. It must open its Heart Gauge every 256
    steps but gain no Day Care EXP; Day Care also ends Hyper Mode.
13. Use Vivid Scent at the Relic Keeper to accelerate the remaining gauge.
14. At an empty gauge, confirm `PURIFY READY`, then purify. Confirm the
    full-screen purification ceremony plays before the result text.
15. Verify stored EXP, possible level gains, Quick Attack replacing Shadow
    Rush, the nickname prompt, and the National Ribbon message.
16. Inspect the purified Pokémon immediately: it must use the ordinary
    two-page summary, with no SHADOW marker or SHADOW DATA page.
17. Save, fully restart Gen1Recomp, and inspect it again; the third page must
    still be absent.

## Repeat the demo

Talk to the Researcher after the target is snagged or purified and accept the
reset prompt. The demo target is removed from party/PC and becomes available
again.

## Troubleshooting

- **No new NPCs:** leave Pallet Town and return. In developer mode, F5 also
  reloads mods.
- **Old interface behavior remains:** fully close the game before replacing
  the mod; hot reload cannot unwind every already-installed runtime wrapper.
- **No Poké Ball or test item:** talk to the Researcher again.
- **Target was knocked out:** talk to the Cipher Peon for a rematch.
- **Another mod changes battle, bag, summary, trade, or Day Care internals:**
  temporarily disable it. This mod declares `engine_internals` because those
  seams are not all available as stable public hooks yet.
