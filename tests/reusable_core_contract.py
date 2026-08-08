#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    part5 = (ROOT / "src/part5.lua").read_text(encoding="utf-8")
    part6 = (ROOT / "src/part6.lua").read_text(encoding="utf-8")
    part9 = (ROOT / "src/part9.lua").read_text(encoding="utf-8")
    api = (ROOT / "REUSABLE_API.md").read_text(encoding="utf-8")

    assert "SHADOW_TRAINER_ENCOUNTERS" in part5
    assert "registerShadowTrainerEncounter" in part5
    assert "partySlot = math.max(0" in part5
    assert "shadow.snagged" in part5
    assert "self.oppClass" in part5
    assert "SNAG_ACCESS_CHECK" in part5

    assert "genericSnag = true" in part6
    assert "doubleBattleAware = false" in part6
    assert "registerTrainerEncounter = registerShadowTrainerEncounter" in part6
    assert "setSnagAccessCheck = setSnagAccessCheck" in part6

    # Delayed Shadow EXP remains in this reusable dependency, not the total
    # conversion. Both interception and bank logic must stay present.
    assert 'mod.hooks:wrap("battle.exp_award"' in part6
    assert "function bankShadowExperience" in part9
    assert "state.expBank" in part9

    assert "zero-based party slots" in api
    assert "genericSnag = true" in api
    assert "doubleBattleAware = false" in api

    print("OK - reusable Shadow core contract passed")


if __name__ == "__main__":
    main()
