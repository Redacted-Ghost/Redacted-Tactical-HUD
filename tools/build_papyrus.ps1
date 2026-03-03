# build_papyrus.ps1 — Compile Papyrus .psc → .pex
# Uses the Creation Kit PapyrusCompiler with FO4 base scripts + HUDFramework imports
#
# NOTE: PapyrusCompiler resolves script paths relative to the IMPORT directories.
# We must pass the script filename (not full path) and include SrcDir in -i= imports,
# OR cd to SrcDir first. We use Push-Location approach for reliability.

$ErrorActionPreference = "Stop"

$Compiler   = "C:\steam games\steam\steamapps\common\Fallout 4\Papyrus Compiler\PapyrusCompiler.exe"
$FlagsFile  = "C:\steam games\steam\steamapps\common\Fallout 4\Data\Scripts\Source\Institute_Papyrus_Flags.flg"
$BaseImport = "C:\steam games\steam\steamapps\common\Fallout 4\Data\Scripts\Source"

# Resolve relative paths to absolute
$ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$HFImport    = Join-Path $ProjectRoot "tmp\hf_pex"
$SrcDir      = Join-Path $ProjectRoot "src\papyrus"
$OutDir      = Join-Path $ProjectRoot "dist\Scripts"

# Mod API imports (Lighthouse, F4SE, etc.)
$LighthouseImport = "C:\Modlists\WastelandReborn\mods\Lighthouse Papyrus Extender\Scripts\Source"
$F4SEImport       = "C:\Modlists\WastelandReborn\mods\Fallout 4 Script Extender (F4SE)\Scripts\Source"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

Write-Host "=== Building Papyrus Scripts ===" -ForegroundColor Cyan
Write-Host "Compiler: $Compiler"
Write-Host "Source:   $SrcDir"
Write-Host "Imports:  $SrcDir;$BaseImport;$HFImport;$LighthouseImport;$F4SEImport"
Write-Host "Output:   $OutDir"
Write-Host ""

$scripts = Get-ChildItem "$SrcDir\*.psc" -ErrorAction SilentlyContinue
$success = 0
$fail = 0

# IMPORTANT: PapyrusCompiler derives script name from relative path.
# We must cd to SrcDir and pass just the filename, not the full path.
$savedLocation = Get-Location
Set-Location $SrcDir

foreach ($script in $scripts) {
    Write-Host "Compiling: $($script.Name)" -ForegroundColor White

    # F4SE imports BEFORE base game so extended Actor.psc/InstanceData.psc take priority
    $importPath = ".;$F4SEImport;$BaseImport;$HFImport;$LighthouseImport"
    $result = & $Compiler "$($script.Name)" "-i=$importPath" "-o=$OutDir" "-f=$FlagsFile" 2>&1
    $result | ForEach-Object { Write-Host "  $_" }

    if ($LASTEXITCODE -eq 0) {
        $pexName = [System.IO.Path]::ChangeExtension($script.Name, ".pex")
        $pexPath = Join-Path $OutDir $pexName
        if (Test-Path $pexPath) {
            $size = (Get-Item $pexPath).Length
            Write-Host "  OK: $pexName ($size bytes)" -ForegroundColor Green
        }
        $success++
    } else {
        Write-Host "  FAILED: $($script.Name)" -ForegroundColor Red
        $fail++
    }
}

Set-Location $savedLocation

Write-Host ""
if ($fail -eq 0) {
    Write-Host "BUILD SUCCESS: $success script(s) compiled" -ForegroundColor Green
} else {
    Write-Host "BUILD PARTIAL: $success succeeded, $fail failed" -ForegroundColor Yellow
    exit 1
}
