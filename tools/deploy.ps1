# deploy.ps1 — Copy build output to MO2 mod folder
# NEVER touches Stock Game/Data/ — MO2 handles virtual filesystem

$ErrorActionPreference = "Stop"

$DistDir = "$PSScriptRoot\..\dist"
$ModDir  = "C:\Modlists\WastelandReborn\mods\[nodelete] LoreOut Custom HUD"

# Ensure mod subdirectories exist
$InterfaceDir = "$ModDir\Interface"
$TexturesDir  = "$ModDir\Textures"

if (-not (Test-Path $InterfaceDir)) {
    New-Item -ItemType Directory -Path $InterfaceDir -Force | Out-Null
    Write-Host "Created: $InterfaceDir" -ForegroundColor Yellow
}

if (-not (Test-Path $TexturesDir)) {
    New-Item -ItemType Directory -Path $TexturesDir -Force | Out-Null
    Write-Host "Created: $TexturesDir" -ForegroundColor Yellow
}

# Deploy SWFs
Write-Host "=== Deploying to MO2 mod folder ===" -ForegroundColor Cyan
Write-Host "Target: $ModDir"
Write-Host ""

$swfCount = 0
if (Test-Path "$DistDir\Interface") {
    $swfs = Get-ChildItem "$DistDir\Interface\*.swf" -ErrorAction SilentlyContinue
    foreach ($swf in $swfs) {
        Copy-Item $swf.FullName -Destination $InterfaceDir -Force
        Write-Host "  Deployed: Interface\$($swf.Name)" -ForegroundColor Green
        $swfCount++
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
Write-Host "DEPLOY COMPLETE: $swfCount SWF(s), $texCount texture(s)" -ForegroundColor Green
