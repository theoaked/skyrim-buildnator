# Buildnator mod build pipeline:
#   gen-data -> esp generator (Mutagen) -> Papyrus compile -> deploy to game Data
# PowerShell 5.1 compatible. Run from anywhere: .\mod\build.ps1
param(
    [switch]$NoDeploy,
    [switch]$Zip
)

$ErrorActionPreference = "Stop"
$modRoot = $PSScriptRoot
$gameDir = "C:\Program Files (x86)\Steam\steamapps\common\Skyrim Special Edition"
$outDir = Join-Path $modRoot "out"
$scriptsOut = Join-Path $outDir "Scripts"

New-Item -ItemType Directory -Force $outDir | Out-Null
New-Item -ItemType Directory -Force $scriptsOut | Out-Null
New-Item -ItemType Directory -Force (Join-Path $modRoot "generated") | Out-Null

# --- 1. Generate data layer from js/data.js (single source of truth) ---
$genData = Join-Path $modRoot "tools\gen-data.js"
if (Test-Path $genData) {
    Write-Host "== gen-data.js ==" -ForegroundColor Cyan
    node $genData
    if ($LASTEXITCODE -ne 0) { throw "gen-data.js failed" }
}

# --- 2. Build Buildnator.esp with the Mutagen generator ---
Write-Host "== esp generator ==" -ForegroundColor Cyan
$esp = Join-Path $outDir "Buildnator.esp"
dotnet run --project (Join-Path $modRoot "Generator") -c Release -- $esp (Join-Path $modRoot "generated\data.json") (Join-Path $gameDir "Data\Skyrim.esm")
if ($LASTEXITCODE -ne 0) { throw "esp generator failed" }

# --- 3. Compile Papyrus scripts ---
Write-Host "== papyrus compile ==" -ForegroundColor Cyan
$compiler = Join-Path $gameDir "Papyrus Compiler\PapyrusCompiler.exe"
$gameSources = Join-Path $gameDir "Data\Source\Scripts"
# Source\Imports holds compile-time-only declarations (SKSE natives) - they are
# imported but never compiled to pex, so SKSE's own runtime scripts stay intact.
$imports = "$(Join-Path $modRoot 'Source\Imports');$(Join-Path $modRoot 'Source\Scripts');$(Join-Path $modRoot 'generated');$gameSources"

$sources = @(Get-ChildItem (Join-Path $modRoot "Source\Scripts") -Filter *.psc)
$sources += @(Get-ChildItem (Join-Path $modRoot "generated") -Filter *.psc -ErrorAction SilentlyContinue)
foreach ($psc in $sources) {
    & $compiler $psc.FullName "-f=TESV_Papyrus_Flags.flg" "-i=$imports" "-o=$scriptsOut" -quiet
    if ($LASTEXITCODE -ne 0) { throw "Papyrus compile failed: $($psc.Name)" }
    Write-Host "  compiled $($psc.Name)"
}

# --- 4. Deploy to game Data (dev iteration) ---
if (-not $NoDeploy) {
    Write-Host "== deploy ==" -ForegroundColor Cyan
    $dataDir = Join-Path $gameDir "Data"
    Copy-Item $esp $dataDir -Force
    New-Item -ItemType Directory -Force (Join-Path $dataDir "Scripts") | Out-Null
    Copy-Item (Join-Path $scriptsOut "*.pex") (Join-Path $dataDir "Scripts") -Force
    New-Item -ItemType Directory -Force (Join-Path $dataDir "Seq") | Out-Null
    Copy-Item (Join-Path $outDir "Seq\*.seq") (Join-Path $dataDir "Seq") -Force
    Write-Host "  copied to $dataDir"

    # Activate the plugin if the load order file doesn't know it yet.
    $pluginsTxt = Join-Path $env:LOCALAPPDATA "Skyrim Special Edition\Plugins.txt"
    if (Test-Path $pluginsTxt) {
        $lines = Get-Content $pluginsTxt
        if (-not ($lines -match "Buildnator\.esp")) {
            Add-Content $pluginsTxt "*Buildnator.esp"
            Write-Host "  activated in Plugins.txt"
        }
    } else {
        Write-Host "  NOTE: $pluginsTxt not found - enable Buildnator.esp in your mod manager." -ForegroundColor Yellow
    }
}

# --- 5. Distributable zip (Vortex-installable) ---
if ($Zip) {
    Write-Host "== package ==" -ForegroundColor Cyan
    $stage = Join-Path $outDir "stage"
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Force (Join-Path $stage "Scripts") | Out-Null
    New-Item -ItemType Directory -Force (Join-Path $stage "Seq") | Out-Null
    Copy-Item $esp $stage
    Copy-Item (Join-Path $scriptsOut "*.pex") (Join-Path $stage "Scripts")
    Copy-Item (Join-Path $outDir "Seq\*.seq") (Join-Path $stage "Seq")
    $distDir = Join-Path (Split-Path $modRoot) "dist"
    New-Item -ItemType Directory -Force $distDir | Out-Null
    $zipPath = Join-Path $distDir "buildnator-mod.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path "$stage\*" -DestinationPath $zipPath
    Write-Host "  wrote $zipPath"
}

Write-Host "BUILD OK" -ForegroundColor Green
