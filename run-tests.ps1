<#
.SYNOPSIS
    Runs the in-game FactorioTest suites for freeplay_starting_equipment on Windows 11.

.DESCRIPTION
    Default: headless Factorio in Docker (Docker Desktop). Tests tagged "needs-player" are skipped,
    because a headless game has no players.

    -Graphics: prepares a separate test profile in .factorio-test-data\ (factorio-test mod, a link to
    your mod, mod-list.json, config.ini) and starts your installed Factorio with it. Start a new game,
    click the test-tube button (top left), pick the mod and press "Reload mods and run tests".
    With a player in the game, every test runs, including "needs-player". Your normal Factorio
    profile, saves and mods are not touched. No Node.js needed.

    Both modes first lint the mod:
      - luacheck (config: .luacheckrc): undefined/misspelled globals, unused variables, ...
        Uses luacheck.exe if it is on PATH, otherwise the luacheck Docker image.
      - typecheck (Docker): Lua Language Server against the Factorio API of -FactorioVersion,
        catches typos like player.get_main_inventry, defines.events.on_player_joind_game.
    Tests still run when lint finds issues, but the final result is a failure.
    -LintOnly only lints, -NoLint skips it.

    Both modes need the factorio-test mod zip. If docker\factorio-test_*.zip is missing, the script
    downloads it from the mod portal using the login the game saved in
    %APPDATA%\Factorio\player-data.json.

    Works in Windows PowerShell 5.1 (built into Windows 11) and PowerShell 7.

.EXAMPLE
    .\run-tests.ps1
.EXAMPLE
    .\run-tests.ps1 -LintOnly
.EXAMPLE
    .\run-tests.ps1 -Filter give_items -Bail -NoLint
.EXAMPLE
    .\run-tests.ps1 -Graphics
.EXAMPLE
    .\run-tests.ps1 -Graphics -FactorioPath "D:\Games\Factorio_Experimental\bin\x64\factorio.exe"
.EXAMPLE
    .\run-tests.ps1 -Rebuild -FactorioVersion 2.1.20
.EXAMPLE
    .\run-tests.ps1 -ModDir path\to\other\mod

.NOTES
    If scripts are blocked: powershell -ExecutionPolicy Bypass -File .\run-tests.ps1
#>
[CmdletBinding()]
param(
    # Start your installed Factorio with a test profile instead of Docker (runs needs-player tests too).
    [switch]$Graphics,
    # Only run luacheck, no tests.
    [switch]$LintOnly,
    # Skip luacheck.
    [switch]$NoLint,
    # Rebuild the Docker image from scratch (normally it is rebuilt from cache on every run).
    [switch]$Rebuild,
    # Stop after the first failing test.
    [switch]$Bail,
    # Lua pattern(s): only run tests whose full name matches one of them.
    [string[]]$Filter = @(),
    # Factorio version for the Docker image (and for picking the factorio-test release).
    [string]$FactorioVersion = "2.1.20",
    # factorio-test-cli version (npm).
    [string]$CliVersion = "3.6.0",
    # Graphics mode only: path to factorio.exe. Default: build.config.json (unstable, then stable),
    # then the usual Steam / Program Files locations.
    [string]$FactorioPath,
    # Additional factorio-test CLI flags, e.g. -ExtraArgs "--log-passed-tests"
    [string[]]$ExtraArgs = @(),
    # Mod folder (the one with info.json), relative to this script or absolute.
    [string]$ModDir = "src"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = $PSScriptRoot
if ([System.IO.Path]::IsPathRooted($ModDir)) {
    $ModPath = $ModDir
}
else {
    $ModPath = Join-Path $Root $ModDir
}
$DockerDir = Join-Path $Root "docker"
$LocalDataDir = Join-Path $Root ".factorio-test-data"
$script:ExitCode = 1

function Write-Step([string]$Text) {
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Stop-WithError([string]$Text) {
    Write-Host "ERROR: $Text" -ForegroundColor Red
    exit 2
}

# Runs a native command without PowerShell 5.1 turning its stderr into terminating errors.
function Invoke-Native([scriptblock]$Command) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Command | Out-Host
    }
    finally {
        $ErrorActionPreference = $previous
    }
    return $LASTEXITCODE
}

function Get-JsonProperty($Object, [string]$Name) {
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    return $null
}

function Get-FactorioTestZip {
    $existing = Get-ChildItem -Path $DockerDir -Filter "factorio-test_*.zip" -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -Last 1
    if ($existing) {
        return $existing.FullName
    }

    Write-Step "factorio-test mod zip not found in docker\, downloading it from the mod portal"
    $manual = "Or download factorio-test 3.x from https://mods.factorio.com/mod/factorio-test and put the zip into $DockerDir"

    $playerData = Join-Path $env:APPDATA "Factorio\player-data.json"
    if (-not (Test-Path $playerData)) {
        Stop-WithError "$playerData not found (start Factorio once and log in).`n$manual"
    }

    $pd = Get-Content $playerData -Raw | ConvertFrom-Json
    $user = Get-JsonProperty $pd "service-username"
    $token = Get-JsonProperty $pd "service-token"
    if (-not $user -or -not $token) {
        Stop-WithError "No mod portal login saved in $playerData (log in once in the game's Mods screen).`n$manual"
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $info = Invoke-RestMethod -Uri "https://mods.factorio.com/api/mods/factorio-test"

    $gameMajorMinor = (($FactorioVersion -split "\.")[0..1]) -join "."
    $release = @($info.releases) |
        Where-Object {
            (Get-JsonProperty $_.info_json "factorio_version") -eq $gameMajorMinor -and
            [version]$_.version -ge [version]"3.0.0"
        } |
        Sort-Object { [version]$_.version } |
        Select-Object -Last 1
    if (-not $release) {
        Stop-WithError "No factorio-test release >= 3.0.0 for Factorio $gameMajorMinor on the mod portal.`n$manual"
    }

    $target = Join-Path $DockerDir $release.file_name
    $query = "username=$([uri]::EscapeDataString($user))&token=$([uri]::EscapeDataString($token))"
    Invoke-WebRequest -Uri "https://mods.factorio.com$($release.download_url)?$query" -OutFile $target -UseBasicParsing
    Write-Host "    saved $($release.file_name)"
    return $target
}

# Order matters: name filters must come before --tag-blacklist (it takes several values)
# and before --bail (it takes an optional count).
function Get-TestArgs([bool]$SkipPlayerTests) {
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($f in $Filter) { $list.Add($f) }
    if ($SkipPlayerTests) { $list.Add("--tag-blacklist"); $list.Add("needs-player") }
    if ($Bail) { $list.Add("--bail") }
    foreach ($a in $ExtraArgs) { $list.Add($a) }
    return $list.ToArray()
}

function Test-DockerRunning {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
    return (Invoke-Native { docker info *> $null }) -eq 0
}

# Returns luacheck's exit code (0 = clean, 1 = warnings, 2 = errors, 3+ = luacheck failed).
function Invoke-Luacheck {
    $target = $ModDir -replace "\\", "/"
    Push-Location $Root
    try {
        if (Get-Command luacheck -ErrorAction SilentlyContinue) {
            Write-Step "Linting $ModDir with luacheck"
            $code = Invoke-Native { luacheck $target }
        }
        elseif ([System.IO.Path]::IsPathRooted($ModDir)) {
            Write-Host "    luacheck skipped: -ModDir outside the repo needs luacheck.exe on PATH" -ForegroundColor Yellow
            return 0
        }
        elseif (Test-DockerRunning) {
            Write-Step "Linting $ModDir with luacheck (Docker)"
            $code = Invoke-Native { docker compose run --rm -T lint $target }
        }
        else {
            Write-Host "    luacheck skipped: put luacheck.exe on PATH or start Docker Desktop" -ForegroundColor Yellow
            return 0
        }
    }
    finally {
        Pop-Location
    }

    if ($code -eq 0) {
        Write-Host "    luacheck: no issues" -ForegroundColor Green
    }
    else {
        Write-Host "    luacheck: issues found (exit code $code)" -ForegroundColor Yellow
    }
    return $code
}

# Returns 0 = no problems, 1 = problems found, other = typecheck could not run.
function Invoke-TypeCheck {
    if ([System.IO.Path]::IsPathRooted($ModDir)) {
        Write-Host "    typecheck skipped: -ModDir outside the repo" -ForegroundColor Yellow
        return 0
    }
    if (-not (Test-DockerRunning)) {
        Write-Host "    typecheck skipped: start Docker Desktop to type-check against the Factorio API" -ForegroundColor Yellow
        return 0
    }

    Push-Location $Root
    try {
        Write-Step "Type-checking $ModDir against the Factorio $FactorioVersion API"
        $buildArgs = @("compose", "build", "typecheck")
        if ($Rebuild) { $buildArgs += "--no-cache" }
        if ((Invoke-Native { docker @buildArgs }) -ne 0) {
            Write-Host "    typecheck image build failed (see above)" -ForegroundColor Red
            return 3
        }
        $target = $ModDir -replace "\\", "/"
        $code = Invoke-Native { docker compose run --rm -T typecheck $target }
    }
    finally {
        Pop-Location
    }

    if ($code -eq 0) {
        Write-Host "    typecheck: no problems" -ForegroundColor Green
    }
    else {
        Write-Host "    typecheck: problems found (exit code $code)" -ForegroundColor Yellow
    }
    return $code
}

function Invoke-Lint {
    $luacheckCode = Invoke-Luacheck
    $typecheckCode = Invoke-TypeCheck
    if ($luacheckCode -ne 0) { return $luacheckCode }
    return $typecheckCode
}

function Invoke-DockerTests {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Stop-WithError "docker not found. Install Docker Desktop (https://www.docker.com/products/docker-desktop/) or use -Graphics."
    }
    if (-not (Test-DockerRunning)) {
        Stop-WithError "Docker is not running. Start Docker Desktop and try again."
    }

    [void](Get-FactorioTestZip)

    # Relative paths are resolved by compose next to docker-compose.yml.
    if ([System.IO.Path]::IsPathRooted($ModDir)) {
        $env:MOD_DIR = $ModPath
    }
    else {
        $env:MOD_DIR = "./" + ($ModDir -replace "\\", "/")
    }

    Push-Location $Root
    try {
        # Always build: it is cached (seconds) and picks up any Dockerfile change.
        Write-Step "Building test image (Factorio $FactorioVersion, factorio-test-cli $CliVersion)"
        $buildArgs = @("compose", "build", "tests")
        if ($Rebuild) { $buildArgs += "--no-cache" }
        if ((Invoke-Native { docker @buildArgs }) -ne 0) {
            Stop-WithError "docker compose build failed."
        }

        Write-Step "Checking that Docker can see the mod folder"
        $visible = Invoke-Native { docker compose run --rm -T --entrypoint sh tests -c "test -f /mod/info.json" }
        if ($visible -ne 0) {
            Stop-WithError ("Docker cannot see $ModPath inside the container (/mod has no info.json).`n" +
                "  - Docker Desktop > Settings > General: enable 'Use the WSL 2 based engine'`n" +
                "    (or with Hyper-V: Settings > Resources > File sharing, add the drive/folder)`n" +
                "  - 'docker context ls': the active context must be Docker Desktop (desktop-linux),`n" +
                "    not Docker/Podman inside a WSL distro, which cannot see Windows paths like D:\`n" +
                "  - network drives, subst/virtual drives and OneDrive-only folders cannot be mounted")
        }

        # Any args replace the image's default CMD, so the needs-player blacklist is always passed.
        $testArgs = Get-TestArgs $true
        Write-Step "Running tests in headless Factorio $FactorioVersion (needs-player tests skipped)"
        $script:ExitCode = Invoke-Native { docker compose run --rm -T tests @testArgs }
    }
    finally {
        Pop-Location
    }
}

function Find-FactorioExe {
    if ($FactorioPath) {
        if (-not (Test-Path $FactorioPath)) { Stop-WithError "factorio.exe not found at $FactorioPath" }
        return $FactorioPath
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    $buildConfig = Join-Path $Root "build.config.json"
    if (Test-Path $buildConfig) {
        $factorio = Get-JsonProperty (Get-Content $buildConfig -Raw | ConvertFrom-Json) "factorio"
        if ($factorio -is [string]) {
            $candidates.Add((Join-Path $factorio "bin\x64\factorio.exe"))
        }
        elseif ($factorio) {
            foreach ($branch in @("unstable", "stable")) {
                $dir = Get-JsonProperty $factorio $branch
                if ($dir) { $candidates.Add((Join-Path $dir "bin\x64\factorio.exe")) }
            }
        }
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates.Add((Join-Path ${env:ProgramFiles(x86)} "Steam\steamapps\common\Factorio\bin\x64\factorio.exe"))
    }
    if ($env:ProgramFiles) {
        $candidates.Add((Join-Path $env:ProgramFiles "Factorio\bin\x64\factorio.exe"))
    }

    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    Stop-WithError "factorio.exe not found. Pass -FactorioPath ""D:\...\bin\x64\factorio.exe"""
}

function Set-ModLink([string]$Link, [string]$Target) {
    $item = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
    if ($item) {
        $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if (-not $isLink) {
            Stop-WithError "$Link exists and is a real folder, not a link. Remove it yourself and rerun."
        }
        # Deletes only the link itself, never the files it points to.
        [IO.Directory]::Delete($Link, $false)
    }
    New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
}

function Invoke-GraphicsTests {
    $exe = Find-FactorioExe
    $modName = (Get-Content (Join-Path $ModPath "info.json") -Raw | ConvertFrom-Json).name

    Write-Step "Preparing test profile in $LocalDataDir"
    $modsDir = Join-Path $LocalDataDir "mods"
    New-Item -ItemType Directory -Force -Path $modsDir | Out-Null

    $zip = Get-FactorioTestZip
    $zipTarget = Join-Path $modsDir (Split-Path $zip -Leaf)
    if (-not (Test-Path $zipTarget)) {
        Get-ChildItem -Path $modsDir -Filter "factorio-test_*.zip" | Remove-Item -Force
        Copy-Item $zip $zipTarget
    }

    # Link (junction, no admin needed) so edits in the mod folder are live after "Reload mods".
    Set-ModLink (Join-Path $modsDir $modName) $ModPath

    # Same mod set as the Docker run: base + factorio-test + your mod, DLC off.
    $modList = @{ mods = @(
            @{ name = "base"; enabled = $true },
            @{ name = "factorio-test"; enabled = $true },
            @{ name = $modName; enabled = $true },
            @{ name = "space-age"; enabled = $false },
            @{ name = "quality"; enabled = $false },
            @{ name = "elevated-rails"; enabled = $false },
            @{ name = "recycler"; enabled = $false }
        )
    }
    $modList | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $modsDir "mod-list.json") -Encoding Ascii

    $configIni = Join-Path $LocalDataDir "config.ini"
    @(
        "; generated by run-tests.ps1",
        "[path]",
        "read-data=__PATH__executable__/../../data",
        "write-data=$LocalDataDir",
        "",
        "[general]",
        "locale="
    ) | Set-Content -Path $configIni -Encoding Ascii

    if ($Filter.Count -gt 0 -or $Bail -or $ExtraArgs.Count -gt 0) {
        Write-Host "    note: -Filter/-Bail/-ExtraArgs apply to the Docker run only" -ForegroundColor Yellow
    }

    Write-Step "Starting $exe"
    Start-Process -FilePath $exe -ArgumentList @("-c", """$configIni""", "--mod-directory", """$modsDir""")

    Write-Host ""
    Write-Host "In Factorio:" -ForegroundColor Cyan
    Write-Host "  1. Single player > New game (any scenario, e.g. Freeplay)"
    Write-Host "  2. Click the test-tube button in the top-left corner"
    Write-Host "  3. 'Run tests for mod:' $modName  ->  'Reload mods and run tests'"
    Write-Host "  4. After editing Lua files, press 'Reload mods and run tests' again"
    Write-Host ""
    $script:ExitCode = 0
}

if (-not (Test-Path (Join-Path $ModPath "info.json"))) {
    Stop-WithError "No info.json in $ModPath (use -ModDir to point at the mod folder)"
}

if ($LintOnly -and $NoLint) {
    Stop-WithError "-LintOnly and -NoLint cannot be combined."
}

$env:FACTORIO_VERSION = $FactorioVersion
$env:FACTORIO_TEST_CLI_VERSION = $CliVersion

$lintCode = 0
if (-not $NoLint) {
    $lintCode = Invoke-Lint
}
if ($LintOnly) {
    exit $lintCode
}

if ($Graphics) {
    Invoke-GraphicsTests
    if ($lintCode -ne 0) {
        Write-Host "Note: lint found issues (see above)." -ForegroundColor Yellow
        exit $lintCode
    }
    exit $script:ExitCode
}

Invoke-DockerTests

if ($script:ExitCode -eq 0 -and $lintCode -eq 0) {
    Write-Host "Lint clean, tests passed." -ForegroundColor Green
    exit 0
}
if ($script:ExitCode -eq 0) {
    Write-Host "Tests passed, but lint found issues (see luacheck/typecheck output above)." -ForegroundColor Red
    exit 1
}
Write-Host "Tests failed (exit code $($script:ExitCode))." -ForegroundColor Red
if ($lintCode -ne 0) {
    Write-Host "Lint found issues too (see luacheck/typecheck output above)." -ForegroundColor Red
}
exit $script:ExitCode
