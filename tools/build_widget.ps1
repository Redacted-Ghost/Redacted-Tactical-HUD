# build_widget.ps1 — Compile LoreOutTestWidget AS3 → SWF
# Uses Adobe Flex SDK 4.6.0 (proven for Scaleform/FO4)

$ErrorActionPreference = "Stop"

$FlexSDK   = "C:\dev\tools\flex-sdk"
$MxmlcJar  = "$FlexSDK\lib\mxmlc.jar"
$Flexlib    = "$FlexSDK\frameworks"
$SrcRoot   = "$PSScriptRoot\..\src\as3"
$OutDir    = "$PSScriptRoot\..\dist\Interface"
$OutFile   = "$OutDir\LoreOutTestWidget.swf"
$MainClass = "$SrcRoot\loreout\widgets\LoreOutTestWidget.as"

# Ensure output directory exists
if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

Write-Host "=== Building LoreOutTestWidget.swf ===" -ForegroundColor Cyan
Write-Host "Source: $MainClass"
Write-Host "Output: $OutFile"
Write-Host ""

$args = @(
    "-jar", $MxmlcJar,
    "+flexlib=$Flexlib",
    "-target-player=11.1",
    "-static-link-runtime-shared-libraries=true",
    "-source-path+=$SrcRoot",
    $MainClass,
    "-output", $OutFile
)

& java @args

if ($LASTEXITCODE -eq 0) {
    $size = (Get-Item $OutFile).Length
    Write-Host ""
    Write-Host "BUILD SUCCESS: $OutFile ($size bytes)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "BUILD FAILED (exit code $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}
