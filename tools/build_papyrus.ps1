# build_papyrus.ps1 — Compile Papyrus .psc → .pex
# Uses the Creation Kit PapyrusCompiler with FO4 base scripts + HUDFramework imports

$ErrorActionPreference = "Stop"

$Compiler   = "C:\steam games\steam\steamapps\common\Fallout 4\Papyrus Compiler\PapyrusCompiler.exe"
$FlagsFile  = "C:\steam games\steam\steamapps\common\Fallout 4\Data\Scripts\Source\Institute_Papyrus_Flags.flg"
$BaseImport = "C:\steam games\steam\steamapps\common\Fallout 4\Data\Scripts\Source"
$HFImport   = "$PSScriptRoot\..\tmp\hf_pex"
$SrcDir     = "$PSScriptRoot\..\src\papyrus"
$OutDir     = "$PSScriptRoot\..\dist\Scripts"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

Write-Host "=== Building Papyrus Scripts ===" -ForegroundColor Cyan
Write-Host "Compiler: $Compiler"
Write-Host "Output:   $OutDir"
Write-Host ""

$scripts = Get-ChildItem "$SrcDir\*.psc" -ErrorAction SilentlyContinue
$success = 0
$fail = 0

foreach ($script in $scripts) {
    Write-Host "Compiling: $($script.Name)" -ForegroundColor White
    & $Compiler $script.FullName "-i=$BaseImport;$HFImport" "-o=$OutDir" "-f=$FlagsFile" 2>&1

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

Write-Host ""
if ($fail -eq 0) {
    Write-Host "BUILD SUCCESS: $success script(s) compiled" -ForegroundColor Green
} else {
    Write-Host "BUILD PARTIAL: $success succeeded, $fail failed" -ForegroundColor Yellow
    exit 1
}
