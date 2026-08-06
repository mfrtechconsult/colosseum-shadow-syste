# Installation and test procedure

## Install

1. Use a current Gen1Recomp build based on the `dev` mod API.
2. Extract the folder named `colosseum_shadow_system`.
3. Put that folder directly inside Gen1Recomp's `mods` directory.
4. Launch Gen1Recomp.
5. Open the mod manager with **F10**.
6. Enable **Colosseum Shadow System**.
7. Load a game and enter Pallet Town.

The final path must look like:

```text
Gen1Recomp/
└── mods/
    └── colosseum_shadow_system/
        ├── manifest.json
        ├── main.lua
        └── README.md
```

When using a packaged build whose mods live in the user-data folder, open the
mod manager and use its mods-folder shortcut rather than guessing the path.

## First test

1. Talk to the **Scientist/Researcher**.
2. Talk to the **Rocket/Cipher Peon**.
3. During the Trainer battle, choose **ITEM** and throw a Poké Ball.
4. The bottom-right command is **CALL** during this battle.
5. After a successful Snag, talk to the **Gym Guide/Monitor operator**.
6. Put Shadow Pikachu in the party.
7. Use Shadow Rush until Hyper Mode occurs, then choose **CALL**.
8. Talk repeatedly to the **Mr. Fuji/Relic Keeper** and use Vivid Scent.
9. Once the gauge is empty, talk again to purify Pikachu.
10. Talk to the Monitor to confirm `PURIFIED`.

## Repeat the demo

Talk to the Researcher after the target is snagged or purified. Accept the
reset prompt. The demo Shadow Pikachu is removed from the party/PC and the
Cipher Peon becomes available again.

## Troubleshooting

- **No new NPCs:** leave Pallet Town and return. In developer mode, F5 also
  reloads mods.
- **No Poké Ball in the bag:** talk to the Researcher again.
- **Target was knocked out:** talk to the Cipher Peon again for a rematch.
- **The party was empty:** the Researcher supplies a test Eevee.
- **Another mod changes battle internals:** temporarily disable that mod.
  This version declares `engine_internals` because Gen1Recomp does not yet
  expose Trainer capture and command-menu replacement as stable public hooks.
