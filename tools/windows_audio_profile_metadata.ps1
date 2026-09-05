#Requires -Version 7.0
# Invoked only after CI has built the explicit Profile diagnostic entry point.
[CmdletBinding()]
param([switch]$IncludeHttps)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows -or $env:GITHUB_ACTIONS -cne 'true' -or
    $env:GITHUB_REPOSITORY -cne 'Z-YO-YI/YYMusic' -or $env:GITHUB_EVENT_NAME -cne 'workflow_dispatch' -or
    $env:GITHUB_SHA -cnotmatch '^[0-9a-f]{40}$') { throw 'Only the manual YYMusic CI diagnostic may package this probe' }
$probeRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$commit = git -C $probeRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0 -or $commit -cne $env:GITHUB_SHA) { throw 'Probe checkout identity mismatch' }
$bundle = Join-Path $probeRoot 'build/windows/x64/runner/Profile'
if (-not (Test-Path -LiteralPath (Join-Path $bundle 'data/app.so'))) { throw 'Profile AOT application missing' }
if (Test-Path -LiteralPath (Join-Path $bundle 'data/flutter_assets/kernel_blob.bin')) { throw 'Unexpected Debug kernel' }
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or -not $installation) { throw 'Cannot locate the native dependency inspector' }
$dumpbin = Get-ChildItem -LiteralPath (Join-Path $installation 'VC/Tools/MSVC') -Directory |
    Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName 'bin/Hostx64/x64/dumpbin.exe' } |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $dumpbin) { throw 'Native dependency inspector missing' }
foreach ($file in (Get-ChildItem -LiteralPath $bundle -File | Where-Object { $_.Extension -in @('.exe', '.dll') })) {
    $imports = & $dumpbin /DEPENDENTS $file.FullName
    if ($LASTEXITCODE -ne 0) { throw 'Native dependency inspection failed' }
    if (($imports -join "`n") -match '(?i)(?:MSVCP\d+(?:_\d+)?D|VCRUNTIME\d+(?:_\d+)?D|ucrtbased)\.dll') {
        throw 'Profile probe unexpectedly depends on a Debug CRT'
    }
}
[ordered]@{ schemaVersion = 1; sourceCommit = $commit; nativeCommit = $commit; runtimeMode = 'Profile';
    includeHttps = [bool]$IncludeHttps;
    purpose = $(if ($IncludeHttps) { 'isolated-audio-source-test' } else { 'isolated-local-wav-test' });
    flutterVersion = $env:FLUTTER_VERSION } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $bundle 'native-audio-build.json') -Encoding utf8
Write-Output 'PASS: Profile AOT diagnostic identity recorded; no Debug CRT imports'
