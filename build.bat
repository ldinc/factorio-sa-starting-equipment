for /f "tokens=* delims=" %%# in ('jq -r ".name" src/info.json') do @(set modname=%%#)
for /f "tokens=* delims=" %%# in ('jq -r ".version" src/info.json') do @(set version=%%#)
echo packing %modname% into %modname%_%version%.zip

tar.exe -a -c -f  %modname%_%version%.zip src