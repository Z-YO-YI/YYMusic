#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Source', 'Android', 'Windows')][string]$Mode = 'Source',
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-debug.apk',
    [string]$BundlePath = 'build/windows/x64/runner/Debug'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'audio_license_audit.ps1')
$audioRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifest = Get-Content -LiteralPath (Join-Path $audioRoot 'docs/legal/just_audio/manifest.json') -Raw | ConvertFrom-Json
$requiredNames = @('just_audio', 'just_audio_windows', 'just_audio_platform_interface', 'just_audio_web', 'audio_session', 'rxdart')
if ($manifest.schemaVersion -ne 1 -or $manifest.coverage -cne 'six-dart-audio-packages-only' -or
    $manifest.bundleAsset -cne 'NOTICES.Z' -or
    ($manifest.packages.name -join ',') -cne ($requiredNames -join ',')) { throw 'Unexpected audio license manifest scope' }
$lock = Get-Content -LiteralPath (Join-Path $audioRoot 'pubspec.lock') -Raw
foreach ($package in $manifest.packages) {
    $block = [regex]::Match($lock, '(?m)^  ' + [regex]::Escape($package.name) + ':\r?\n(?:    [^\r\n]*\r?\n)+')
    $versionPattern = '(?m)^    version: "' + [regex]::Escape($package.version) + '"\r?$'
    if (!$block.Success -or $block.Value -cnotmatch $versionPattern -or $package.licenseFile -cne 'LICENSE') {
        throw 'Audio license manifest and lockfile disagree'
    }
}

if ($Mode -ceq 'Source') {
    $config = Get-Content -LiteralPath (Join-Path $audioRoot '.dart_tool/package_config.json') -Raw | ConvertFrom-Json
    $packageRoots = @{}
    foreach ($package in $manifest.packages) {
        $matches = @($config.packages | Where-Object name -CEQ $package.name)
        if ($matches.Count -ne 1) { throw 'Missing or duplicate configured audio package' }
        $uri = [Uri]$matches[0].rootUri
        if (!$uri.IsAbsoluteUri -or !$uri.IsFile -or $uri.Query -or $uri.Fragment) { throw 'Audio package must use a local resolved cache' }
        $packageRoots[$package.name] = $uri.LocalPath
        $path = Join-Path $uri.LocalPath $package.licenseFile
        if ((Get-Item -LiteralPath $path).Length -ne $package.bytes) { throw 'Audio source license length mismatch' }
        Assert-YyLicenseBytes -Bytes ([IO.File]::ReadAllBytes($path)) -Expected $package
    }
    foreach ($source in $manifest.sourceFiles) {
        if (!$packageRoots.ContainsKey($source.package) -or $source.path -notin @('android/build.gradle.kts', 'windows/CMakeLists.txt')) {
            throw 'Unexpected native build evidence path'
        }
        $path = Join-Path $packageRoots[$source.package] $source.path
        if ((Get-Item -LiteralPath $path).Length -ne $source.bytes) { throw 'Audio native build source length mismatch' }
        Assert-YyLicenseBytes -Bytes ([IO.File]::ReadAllBytes($path)) -Expected $source
    }
    'PASS: six locked audio package LICENSE files and two native build sources match audited fingerprints.'
    return
}

if ($Mode -ceq 'Android') {
    $archive = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ApkPath, $audioRoot))
    try {
        $entries = @($archive.Entries | Where-Object FullName -CEQ 'assets/flutter_assets/NOTICES.Z')
        if ($entries.Count -ne 1) { throw 'Missing or duplicate Android NOTICES.Z' }
        if ($entries[0].Length -gt 4MB) { throw 'Audio notice compressed size limit exceeded' }
        $stream = $entries[0].Open()
        try { $compressed = Read-YyBoundedBytes -Stream $stream -Limit 4MB }
        finally { $stream.Dispose() }
    } finally { $archive.Dispose() }
} else {
    $path = Join-Path ([IO.Path]::GetFullPath($BundlePath, $audioRoot)) 'data/flutter_assets/NOTICES.Z'
    if ((Get-Item -LiteralPath $path).Length -gt 4MB) { throw 'Audio notice compressed size limit exceeded' }
    $compressed = [IO.File]::ReadAllBytes($path)
}
Assert-YyAudioNotices -Compressed $compressed -ExpectedLicenses $manifest.packages
"PASS: $Mode NOTICES.Z contains all six audio package licenses with exact source fingerprints."
