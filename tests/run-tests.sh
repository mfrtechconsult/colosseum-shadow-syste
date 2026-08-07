#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
texlua tests/check_syntax.lua main.lua
for file in src/part*.lua; do texlua tests/check_syntax.lua "$file"; done
texlua tests/check_syntax.lua tests/test_shadow_math.lua
texlua tests/check_syntax.lua tests/test_registration.lua
texlua tests/check_syntax.lua tests/test_purified_summary.lua
texlua tests/check_syntax.lua tests/test_fidelity.lua
texlua tests/check_syntax.lua tests/test_purification_animation.lua
texlua tests/test_shadow_math.lua
texlua tests/test_registration.lua
texlua tests/test_purified_summary.lua
texlua tests/test_fidelity.lua
texlua tests/test_purification_animation.lua
