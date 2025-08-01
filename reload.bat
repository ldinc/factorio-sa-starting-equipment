@echo off

set "branch=stable"

if /i "%target%"=="unstable" (
  set "branch=unstable"
)

set "mp=.factorio.%branch%"
for /f "tokens=* delims=" %%# in ('jq -r "%mp%" build.config.json') do set "target=%%#"

goft.exe -b -o "%target%mods\\"

call "%target%bin\x64\factorio.exe"