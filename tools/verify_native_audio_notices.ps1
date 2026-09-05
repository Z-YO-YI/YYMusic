#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet('Source','Android','Windows')][string]$Mode = 'Source',
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-debug.apk',
    [string]$BundlePath = 'build/windows/x64/runner/Debug'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'audio_license_audit.ps1')
$noticeRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$manifest = Get-Content -LiteralPath (Join-Path $noticeRoot 'docs/legal/just_audio/native_manifest.json') -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.scope -cne 'resolved-android-media3-audio-closure' -or
    $manifest.bundle.path -cne 'assets/legal/android_audio/notices.json' -or $manifest.releaseApproved -ne $false) {
    throw 'Unexpected native notice scope'
}
$source = Join-Path $noticeRoot $manifest.bundle.path
$sourceBytes = [IO.File]::ReadAllBytes($source)
Assert-YyLicenseBytes -Bytes $sourceBytes -Expected $manifest.bundle
if ($Mode -eq 'Android') {
    $zip = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ApkPath, $noticeRoot))
    try {
        $entries = @($zip.Entries | Where-Object FullName -CEQ ('assets/flutter_assets/'+$manifest.bundle.path))
        if ($entries.Count -ne 1 -or $entries[0].Length -ne $manifest.bundle.bytes) { throw 'Missing, duplicate or changed native notice asset' }
        $stream = $entries[0].Open()
        try { $bytes = Read-YyBoundedBytes -Stream $stream -Limit 2MB } finally { $stream.Dispose() }
    } finally { $zip.Dispose() }
    Assert-YyLicenseBytes -Bytes $bytes -Expected $manifest.bundle
} elseif ($Mode -eq 'Windows') {
    $path = Join-Path ([IO.Path]::GetFullPath($BundlePath, $noticeRoot)) ('data/flutter_assets/'+$manifest.bundle.path)
    if ((Get-Item -LiteralPath $path).Length -ne $manifest.bundle.bytes) { throw 'Changed native notice asset size' }
    Assert-YyLicenseBytes -Bytes ([IO.File]::ReadAllBytes($path)) -Expected $manifest.bundle
}
"PASS: $Mode native audio notice asset matches reviewed complete materials."
