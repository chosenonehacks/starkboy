param(
    [string]$GodotExecutable = "Godot_v4.7.1-stable_mono_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$buildLabel = (Get-Content -LiteralPath (Join-Path $projectRoot "VERSION") -Raw).Trim()
$steamRoot = Join-Path $projectRoot "build\steam"
$depotRoot = Join-Path $steamRoot "StarkBoy"
$releaseExe = Join-Path $depotRoot "StarkBoy.exe"
$zipPath = Join-Path $steamRoot ("StarkBoy_{0}_Windows_Steam.zip" -f $buildLabel)

if (-not $depotRoot.StartsWith((Join-Path $projectRoot "build\steam"), [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to clean a staging directory outside build\steam."
}

$godot = Get-Command $GodotExecutable -ErrorAction Stop
$template = Join-Path $projectRoot "tmp\export_templates\templates\windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
    throw "Official Godot release template is missing: $template"
}

if (Test-Path -LiteralPath $depotRoot) {
    Remove-Item -LiteralPath $depotRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $depotRoot | Out-Null

$smokeOutput = & $godot.Source --headless --path $projectRoot --script "res://tests/smoke_test.gd" 2>&1
$smokeExitCode = $LASTEXITCODE
$smokeOutput | ForEach-Object { Write-Host $_ }
$smokePassed = ($smokeOutput | Out-String) -match "SMOKE TEST RESULT:\s+PASS"
if (-not $smokePassed) {
    throw "Smoke tests failed; release export aborted."
}
if ($smokeExitCode -ne 0) {
    Write-Warning "Godot smoke runner returned $smokeExitCode despite an explicit PASS result; continuing."
}

& $godot.Source --headless --path $projectRoot --export-release "Windows Desktop" $releaseExe
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $releaseExe)) {
    throw "Godot release export failed."
}

New-Item -ItemType Directory -Force -Path (Join-Path $depotRoot "LICENSES") | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot "THIRD_PARTY_NOTICES.txt") -Destination $depotRoot
Copy-Item -LiteralPath (Join-Path $projectRoot "assets\fonts\OFL.txt") -Destination (Join-Path $depotRoot "LICENSES\OXANIUM_OFL.txt")

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
Compress-Archive -Path (Join-Path $depotRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal
$hash = Get-FileHash -LiteralPath $zipPath -Algorithm SHA256
$hashLine = "{0}  {1}" -f $hash.Hash.ToLowerInvariant(), (Split-Path $zipPath -Leaf)
Set-Content -LiteralPath (Join-Path $steamRoot "SHA256SUMS.txt") -Value $hashLine -Encoding ascii

[pscustomobject]@{
    Executable = $releaseExe
    Zip = $zipPath
    Sha256 = $hash.Hash.ToLowerInvariant()
} | Format-List
