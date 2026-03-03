# deploy.ps1 — Copy build output to MO2 mod folder
# NEVER touches Stock Game/Data/ — MO2 handles virtual filesystem

$ErrorActionPreference = "Stop"

$DistDir = "$PSScriptRoot\..\dist"
$ModDir  = "C:\Modlists\WastelandReborn\mods\[nodelete] LoreOut Custom HUD"

# Ensure mod subdirectories exist
$InterfaceDir = "$ModDir\Interface"
$ScriptsDir   = "$ModDir\Scripts"
$TexturesDir  = "$ModDir\Textures"

foreach ($dir in @($InterfaceDir, $ScriptsDir, $TexturesDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created: $dir" -ForegroundColor Yellow
    }
}

Write-Host "=== Deploying to MO2 mod folder ===" -ForegroundColor Cyan
Write-Host "Target: $ModDir"
Write-Host ""

# Deploy ESP (plugin file goes in mod root)
$espCount = 0
$esps = Get-ChildItem "$DistDir\*.esp" -ErrorAction SilentlyContinue
foreach ($esp in $esps) {
    Copy-Item $esp.FullName -Destination $ModDir -Force
    Write-Host "  Deployed: $($esp.Name)" -ForegroundColor Green
    $espCount++
}

# Deploy SWFs
$swfCount = 0
if (Test-Path "$DistDir\Interface") {
    $swfs = Get-ChildItem "$DistDir\Interface\*.swf" -ErrorAction SilentlyContinue
    foreach ($swf in $swfs) {
        Copy-Item $swf.FullName -Destination $InterfaceDir -Force
        Write-Host "  Deployed: Interface\$($swf.Name)" -ForegroundColor Green
        $swfCount++
    }
}

# Deploy PEX scripts
$pexCount = 0
if (Test-Path "$DistDir\Scripts") {
    $pexes = Get-ChildItem "$DistDir\Scripts\*.pex" -ErrorAction SilentlyContinue
    foreach ($pex in $pexes) {
        Copy-Item $pex.FullName -Destination $ScriptsDir -Force
        Write-Host "  Deployed: Scripts\$($pex.Name)" -ForegroundColor Green
        $pexCount++
    }
}

# Deploy textures (if any)
$texCount = 0
if (Test-Path "$DistDir\Textures") {
    $textures = Get-ChildItem "$DistDir\Textures\*" -ErrorAction SilentlyContinue
    foreach ($tex in $textures) {
        Copy-Item $tex.FullName -Destination $TexturesDir -Force
        Write-Host "  Deployed: Textures\$($tex.Name)" -ForegroundColor Green
        $texCount++
    }
}

Write-Host ""
Write-Host "DEPLOY COMPLETE: $espCount ESP(s), $swfCount SWF(s), $pexCount PEX(s), $texCount texture(s)" -ForegroundColor Green
