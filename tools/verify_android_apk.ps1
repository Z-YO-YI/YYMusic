param([string]$ApkPath = 'build/app/outputs/flutter-apk/app-debug.apk')
$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskApkPath = [IO.Path]::GetFullPath((Join-Path $taskRoot $ApkPath))
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskApkPath)
try {
    $taskFiles = @((Get-ChildItem -LiteralPath (Join-Path $taskRoot 'assets/icons/yymusic') -File).FullName)
    $taskFontManifest = Get-Content -LiteralPath (Join-Path $taskRoot 'assets/fonts/manifest.json') -Raw | ConvertFrom-Json
    $taskFiles += @($taskFontManifest.files | ForEach-Object { Join-Path $taskRoot $_.path })
    if ($taskFiles.Count -ne 48) { throw 'Expected 44 original SVGs and four font/license files' }
    foreach ($taskFile in $taskFiles) {
        $taskRelative = [IO.Path]::GetRelativePath($taskRoot, $taskFile).Replace('\', '/')
        $taskMatches = @($taskArchive.Entries | Where-Object { $_.FullName -ceq "assets/flutter_assets/$taskRelative" })
        if ($taskMatches.Count -ne 1) { throw "Missing or duplicate APK asset: $taskRelative" }
        $taskStream = $taskMatches[0].Open()
        try { $taskDigest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($taskStream)) }
        finally { $taskStream.Dispose() }
        if ($taskDigest -ne (Get-FileHash -LiteralPath $taskFile -Algorithm SHA256).Hash) {
            throw "APK asset differs from audited source: $taskRelative"
        }
    }
    if (@($taskArchive.Entries | Where-Object { $_.FullName -match 'design_reference|sonic_gallery|YYMusic_HTML\.zip|(^|/)\.env($|\.)|\.(jks|keystore|pem|p12|pfx)$' }).Count -gt 0) {
        throw 'Reference, legacy or credential file unexpectedly packaged in APK'
    }
    $taskRejectedMediaKitEntries = @($taskArchive.Entries | Where-Object {
        $_.FullName -match '(^|/)(libmpv\.so|libmediakitandroidhelper\.so)$' -or
        $_.FullName -match 'media_kit'
    })
    if ($taskRejectedMediaKitEntries.Count -gt 0) {
        $taskRejectedNames = $taskRejectedMediaKitEntries.FullName -join ', '
        throw "Rejected media_kit native content unexpectedly packaged in APK: $taskRejectedNames"
    }
    & (Join-Path $PSScriptRoot 'verify_audio_licenses.ps1') -Mode Android -ApkPath $taskApkPath
    & (Join-Path $PSScriptRoot 'verify_native_audio_notices.ps1') -Mode Android -ApkPath $taskApkPath
    Write-Output 'PASS: 48 packaged SVG/font/license files match source bytes; reference/private files and rejected media_kit native content excluded.'
} finally { $taskArchive.Dispose() }
