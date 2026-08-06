@echo off
cd /d "%~dp0\.."
texlua tests\check_syntax.lua main.lua
for %%f in (src\part*.lua) do texlua tests\check_syntax.lua "%%f"
texlua tests\check_syntax.lua tests\test_shadow_math.lua
texlua tests\check_syntax.lua tests\test_registration.lua
texlua tests\check_syntax.lua tests\test_purified_summary.lua
texlua tests\test_shadow_math.lua
texlua tests\test_registration.lua
texlua tests\test_purified_summary.lua
