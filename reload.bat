call build.bat

for /f "tokens=* delims=" %%# in ('jq -r ".factorio" build.config.json') do @(set target=%%#)

echo copy to %target%
move %modname%_%version%.zip %target%mods\

@REM @REM start steam://rungameid/427520
call %target%bin\x64\factorio.exe