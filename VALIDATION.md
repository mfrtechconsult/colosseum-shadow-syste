# Validation report

Validated on 2026-08-06.

## Automated checks

- `main.lua` syntax: PASS
- All `src/part*.lua` syntax checks: PASS
- `tests/test_shadow_math.lua` syntax: PASS
- `tests/test_registration.lua` syntax: PASS
- Heart Gauge threshold tests: PASS
- 256-step counter tests: PASS
- Shadow Rush recoil tests: PASS
- API 2 registration bootstrap: PASS
- Shadow battle badge visibility tests: PASS
- Active Shadow summary keeps page 3: PASS
- Purified summary returns to two pages: PASS
- Purified summary uses the vanilla renderer: PASS
- Stale page 3 normalization after hot reload: PASS
- ZIP integrity test: PASS
- SHA-256 verification: PASS

## Scope of validation

The checks validate Lua syntax, formula behavior, content registration, hook
registration, script registration, summary navigation, package structure, and
archive integrity.

A complete graphical playthrough still requires the user's own current
Gen1Recomp installation and its private ROM-derived cache. No ROM or extracted
Pokémon assets are included in this package.
