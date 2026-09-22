@echo off
setlocal

@REM usage: reload.bat [stable|unstable]   (default: stable)
set "branch=stable"

if /i "%~1"=="unstable" (
  set "branch=unstable"
)

set "mp=.factorio.%branch%"
for /f "tokens=* delims=" %%# in ('jq -r "%mp%" build.config.json') do set "target=%%#"

goft.exe -b -x tests -o "%target%mods\\"

@REM start steam://rungameid/427520
call "%target%bin\x64\factorio.exe"
