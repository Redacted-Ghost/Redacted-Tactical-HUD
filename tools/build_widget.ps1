# build_widget.ps1 — Compile LoreOut AS3 widgets → SWF
# Uses Adobe Flex SDK 4.6.0 (proven for Scaleform/FO4)

$ErrorActionPreference = "Stop"

$FlexSDK  = "C:\dev\tools\flex-sdk"
$MxmlcJar = "$FlexSDK\lib\mxmlc.jar"
$Flexlib   = "$FlexSDK\frameworks"
$SrcRoot  = (Resolve-Path "$PSScriptRoot\..\src\as3").Path
$OutDir   = "$PSScriptRoot\..\dist\Interface"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$OutDir = (Resolve-Path $OutDir).Path

# Widget definitions: [MainClass, OutputSWF]
$widgets = @(
    @("loreout\widgets\LoreOutCombatWidget.as", "LoreOutCombatWidget.swf"),
    @("loreout\widgets\LoreOutStatusWidget.as", "LoreOutStatusWidget.swf"),
    @("loreout\widgets\LoreOutHeartbeatWidget.as", "LoreOutHeartbeatWidget.swf"),
    @("loreout\widgets\LoreOutCompassWidget.as", "LoreOutCompassWidget.swf"),
    @("loreout\widgets\LoreOutRadsWidget.as", "LoreOutRadsWidget.swf"),
    @("loreout\widgets\LoreOutAPWidget.as", "LoreOutAPWidget.swf")
)

Write-Host "=== Building LoreOut Widgets ===" -ForegroundColor Cyan
Write-Host "Source root: $SrcRoot"
Write-Host "Output dir:  $OutDir"
Write-Host ""

$success = 0
$fail = 0

foreach ($widget in $widgets) {
    $mainClass = Join-Path $SrcRoot $widget[0]
    $outFile = Join-Path $OutDir $widget[1]

    if (-not (Test-Path $mainClass)) {
        Write-Host "SKIP: $($widget[0]) (not found)" -ForegroundColor Yellow
        continue
    }

    Write-Host "Compiling: $($widget[1])" -ForegroundColor White
    $javaArgs = @(
        "-jar", $MxmlcJar,
        "+flexlib=$Flexlib",
        "-target-player=11.1",
        "-static-link-runtime-shared-libraries=true",
        "-source-path+=$SrcRoot",
        $mainClass,
        "-output", $outFile
    )

    & java @javaArgs 2>&1

    if ($LASTEXITCODE -eq 0) {
        $size = (Get-Item $outFile).Length
        Write-Host "  OK: $($widget[1]) ($size bytes)" -ForegroundColor Green
        $success++
    } else {
        Write-Host "  FAILED: $($widget[1])" -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
if ($fail -eq 0) {
    Write-Host "BUILD SUCCESS: $success widget(s) compiled" -ForegroundColor Green
} else {
    Write-Host "BUILD PARTIAL: $success succeeded, $fail failed" -ForegroundColor Yellow
    exit 1
}
