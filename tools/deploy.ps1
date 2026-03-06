# deploy.ps1 — Copy build output to MO2 mod folder
# NEVER touches Stock Game/Data/ — MO2 handles virtual filesystem

$ErrorActionPreference = "Stop"

$DistDir = "$PSScriptRoot\..\dist"
$ModDir  = "C:\Modlists\WastelandReborn\mods\[nodelete] LoreOut Custom HUD"

# Ensure mod subdirectories exist
$InterfaceDir     = "$ModDir\Interface"
$ScriptsDir       = "$ModDir\Scripts"
$TexturesDir      = "$ModDir\Textures"
$FallUILayoutDir  = "$ModDir\Interface\FallUI HUD\Importable HUD Layouts"
$MCMPresetDir     = "$ModDir\MCM\Settings\Presets"

foreach ($dir in @($InterfaceDir, $ScriptsDir, $TexturesDir, $FallUILayoutDir, $MCMPresetDir)) {
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

# Deploy FallUI HUD layout presets
$layoutCount = 0
$layoutSrc = "$DistDir\Interface\FallUI HUD\Importable HUD Layouts"
if (Test-Path $layoutSrc) {
    $layouts = Get-ChildItem "$layoutSrc\*.ini" -ErrorAction SilentlyContinue
    foreach ($layout in $layouts) {
        Copy-Item $layout.FullName -Destination $FallUILayoutDir -Force
        Write-Host "  Deployed: Interface\FallUI HUD\Importable HUD Layouts\$($layout.Name)" -ForegroundColor Green
        $layoutCount++
    }
}

# Deploy MCM presets
$mcmCount = 0
$mcmSrc = "$DistDir\MCM\Settings\Presets"
if (Test-Path $mcmSrc) {
    $presets = Get-ChildItem "$mcmSrc\*.ini" -ErrorAction SilentlyContinue
    foreach ($preset in $presets) {
        Copy-Item $preset.FullName -Destination $MCMPresetDir -Force
        Write-Host "  Deployed: MCM\Settings\Presets\$($preset.Name)" -ForegroundColor Green
        $mcmCount++
    }
}

# Deploy MCM configs (e.g. GhostHUD MCM menu)
$mcmConfigCount = 0
$mcmConfigSrc = "$DistDir\MCM\Config"
if (Test-Path $mcmConfigSrc) {
    $configDirs = Get-ChildItem $mcmConfigSrc -Directory -ErrorAction SilentlyContinue
    foreach ($configDir in $configDirs) {
        $destDir = "$ModDir\MCM\Config\$($configDir.Name)"
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        $configFiles = Get-ChildItem $configDir.FullName -File -ErrorAction SilentlyContinue
        foreach ($cf in $configFiles) {
            Copy-Item $cf.FullName -Destination $destDir -Force
            Write-Host "  Deployed: MCM\Config\$($configDir.Name)\$($cf.Name)" -ForegroundColor Green
            $mcmConfigCount++
        }
    }
}

Write-Host ""
Write-Host "DEPLOY COMPLETE: $espCount ESP(s), $swfCount SWF(s), $pexCount PEX(s), $texCount texture(s), $layoutCount layout(s), $mcmCount MCM preset(s), $mcmConfigCount MCM config(s)" -ForegroundColor Green
