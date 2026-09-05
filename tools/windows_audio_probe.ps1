#Requires -Version 7.0
# Local diagnostic only. Never publishes or changes an installed application.
[CmdletBinding()]
param(
    [ValidateSet('ValidateArchive', 'Prepare', 'PrepareProfile', 'Run')][string]$Mode = 'ValidateArchive',
    [string]$ArchivePath,
    [string]$ExpectedArchiveSha256 = 'de1a70bc15352cd8699a928eebb261913753e68a8c75dbe1f065733caba54290',
    [string]$FlutterRoot,
    [string]$OutputDirectory,
    [ValidateSet('Debug', 'Profile')][string]$RuntimeMode = 'Debug',
    [string]$NativeCommit = '4db58997ffe16a62da204344578a5f4b7fd9c320'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$probeRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if ($NativeCommit -cnotmatch '^[0-9a-f]{40}$') { throw 'Expected native commit must be exact' }

function Assert-NoLinks([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw 'Reparse points are not allowed in probe paths'
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}

function Assert-OutputPath {
    if (-not $OutputDirectory) { throw 'A new directory beneath checkout/build is required' }
    $script:outputPath = [IO.Path]::GetFullPath($OutputDirectory)
    $prefix = [IO.Path]::GetFullPath((Join-Path $probeRoot 'build')) + [IO.Path]::DirectorySeparatorChar
    if (-not $outputPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Probe output must remain beneath checkout/build'
    }
    Assert-NoLinks $outputPath
}

function Get-Inventory([string]$Path) {
    @(Get-ChildItem -LiteralPath $Path -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
        Assert-NoLinks $_.FullName
        [ordered]@{
            path = [IO.Path]::GetRelativePath($Path, $_.FullName).Replace('\', '/')
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
}

if ($Mode -eq 'Run') {
    if (-not $IsWindows) { throw 'Native probe requires Windows' }
    Assert-OutputPath
    $manifest = Get-Content -LiteralPath (Join-Path $outputPath 'manifest.json') -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.nativeCommit -cne $nativeCommit -or
        $manifest.sourceCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $manifest.runtimeMode -cne $RuntimeMode) { throw 'Invalid probe manifest' }
    $runtime = Join-Path $outputPath 'runtime'
    $before = Get-Inventory $runtime
    if (($before | ConvertTo-Json -Depth 5 -Compress) -cne ($manifest.files | ConvertTo-Json -Depth 5 -Compress)) {
        throw 'Prepared runtime inventory has changed; refusing execution'
    }
    $resultPath = Join-Path $runtime 'native-audio-poc-result.json'
    if (Test-Path -LiteralPath $resultPath) { throw 'Existing probe result refused' }
    foreach ($name in @('stdout.log', 'stderr.log', 'process-result.json')) {
        if (Test-Path -LiteralPath (Join-Path $outputPath $name)) { throw 'Existing run evidence refused; prepare a new directory' }
    }
    $renderCount = @(Get-PnpDevice -Class AudioEndpoint -Status OK | Where-Object {
        $_.InstanceId -like 'SWD\MMDEVAPI\{0.0.0.*'
    }).Count
    if ($renderCount -lt 1 -or (Get-Service Audiosrv).Status -ne 'Running' -or
        (Get-Service AudioEndpointBuilder).Status -ne 'Running') { throw 'No active Windows render endpoint' }
    Write-Output "Windows render endpoints: $renderCount"
    $process = Start-Process -FilePath (Join-Path $runtime 'yymusic.exe') -WorkingDirectory $runtime `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outputPath 'stdout.log') `
        -RedirectStandardError (Join-Path $outputPath 'stderr.log')
    try {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        while (-not $process.WaitForExit(1000)) {
            if ($watch.Elapsed.TotalSeconds -gt 210) {
                # Only the exact child process created above is stopped.
                $process.Kill()
                $process.WaitForExit()
                throw 'Native probe timed out; local logs retained'
            }
        }
        $process.Refresh()
        $probeExit = $process.ExitCode
        [ordered]@{ sourceCommit = $manifest.sourceCommit; nativeCommit = $nativeCommit; runtimeMode = $RuntimeMode;
            exitCode = $probeExit; elapsedMs = $watch.ElapsedMilliseconds; renderEndpoints = $renderCount } |
            ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outputPath 'process-result.json') -Encoding utf8
    } finally { $process.Dispose() }
    if (-not (Test-Path -LiteralPath $resultPath) -or (Get-Item -LiteralPath $resultPath).Length -gt 8192) {
        throw 'Native probe did not produce a bounded result; local logs retained'
    }
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    if ($result.schemaVersion -ne 1 -or $result.sourceCommit -cne $manifest.sourceCommit -or
        $result.nativeCommit -cne $nativeCommit -or $result.platform -cne 'windows' -or
        $result.passed -isnot [bool] -or -not $result.passed -or $result.testCount -ne 1 -or
        $result.diagnosticId -cne 'native-poc.passed' -or $probeExit -ne 0) {
        throw 'Native probe failed; inspect the ignored local result and logs'
    }
    $metrics = [ordered]@{}
    foreach ($key in @('loadMs', 'firstProgressMs', 'seekMs', 'durationMs')) {
        $value = $result.nativeMetrics.$key
        if ($value -isnot [long] -and $value -isnot [int]) { throw 'Invalid native timing type' }
        if ($value -lt 0 -or $value -gt 20000) { throw 'Invalid native timing range' }
        $metrics[$key] = $value
    }
    if ($metrics.durationMs -lt 2900 -or $metrics.durationMs -gt 3100) { throw 'Invalid native duration' }
    $after = @(Get-Inventory $runtime | Where-Object { $_.path -cne 'native-audio-poc-result.json' })
    if (($before | ConvertTo-Json -Depth 5 -Compress) -cne ($after | ConvertTo-Json -Depth 5 -Compress)) {
        throw 'Runtime files changed during execution'
    }
    # Emit only whitelisted data, never the raw result or native logs.
    [ordered]@{ passed = $true; sourceCommit = $manifest.sourceCommit; nativeCommit = $nativeCommit;
        runtimeMode = $RuntimeMode; renderEndpoints = $renderCount; exitCode = $probeExit; nativeMetrics = $metrics } | ConvertTo-Json -Compress
    return
}

if (-not $ArchivePath -or -not $FlutterRoot -or $ExpectedArchiveSha256 -cnotmatch '^[0-9a-f]{64}$') {
    throw 'Archive, pinned SHA-256 and Flutter SDK are required'
}
Assert-NoLinks $ArchivePath
if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ine $ExpectedArchiveSha256) {
    throw 'Archive SHA-256 mismatch'
}
$engineDirectory = if ($RuntimeMode -eq 'Profile') { 'windows-x64-profile' } else { 'windows-x64' }
$sdkDll = Join-Path $FlutterRoot "bin/cache/artifacts/engine/$engineDirectory/flutter_windows.dll"
$sdkHash = (Get-FileHash -LiteralPath $sdkDll -Algorithm SHA256).Hash
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($ArchivePath))
try {
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $filePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    [long]$expanded = 0
    if ($archive.Entries.Count -gt 5000) { throw 'Archive entry limit exceeded' }
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName
        if (-not $name -or $name.Contains('\') -or $name.StartsWith('/') -or
            $name -match '[<>:"|?*\x00-\x1f]' -or $name -match '(?i)(?:^|/)(?:media_kit[^/]*|libmpv[^/]*)') {
            throw 'Unsafe or rejected archive path'
        }
        $parts = $name.TrimEnd('/').Split('/')
        foreach ($part in $parts) {
            if (-not $part -or $part -in @('.', '..') -or $part -match '[. ]$' -or
                $part -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)') {
                throw 'Unsafe archive path component'
            }
        }
        $unixType = ($entry.ExternalAttributes -shr 16) -band 0xf000
        if ($unixType -notin @(0, 0x8000, 0x4000) -or ($entry.ExternalAttributes -band 0x400)) {
            throw 'Archive links or special files refused'
        }
        if (-not $paths.Add($name.TrimEnd('/'))) { throw 'Duplicate archive path' }
        if (-not $name.EndsWith('/')) { [void]$filePaths.Add($name) }
        $expanded += $entry.Length
        if ($expanded -gt 1GB) { throw 'Archive expanded size limit exceeded' }
    }
    foreach ($name in $paths) {
        $parent = $name
        while ($parent.Contains('/')) {
            $parent = $parent.Substring(0, $parent.LastIndexOf('/'))
            if ($filePaths.Contains($parent)) { throw 'Archive file/directory collision' }
        }
    }
    foreach ($required in @('yymusic.exe', 'flutter_windows.dll', 'just_audio_windows_plugin.dll',
        'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin')) {
        if (-not $filePaths.Contains($required)) { throw 'Required native bundle file missing' }
    }
    $engineEntry = $archive.Entries | Where-Object { $_.FullName -ieq 'flutter_windows.dll' }
    $stream = $engineEntry.Open()
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { $engineHash = [Convert]::ToHexString($hasher.ComputeHash($stream)) }
    finally { $stream.Dispose(); $hasher.Dispose() }
    if ($engineHash -cne $sdkHash) { throw 'Flutter native runtime does not match the local SDK' }
    if ($RuntimeMode -eq 'Profile') {
        if (-not $filePaths.Contains('data/app.so') -or -not $filePaths.Contains('native-audio-build.json') -or
            $filePaths.Contains('data/flutter_assets/kernel_blob.bin')) { throw 'Invalid Profile AOT bundle' }
        $metadataEntry = $archive.Entries | Where-Object { $_.FullName -ceq 'native-audio-build.json' }
        if ($metadataEntry.Length -gt 4096) { throw 'Profile metadata exceeds limit' }
        $reader = [IO.StreamReader]::new($metadataEntry.Open())
        try { $metadata = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        if ($metadata.schemaVersion -ne 1 -or $metadata.sourceCommit -cne $nativeCommit -or
            $metadata.nativeCommit -cne $nativeCommit -or $metadata.runtimeMode -cne 'Profile' -or
            $metadata.purpose -cne 'isolated-local-wav-test' -or $metadata.flutterVersion -cne '3.47.2') {
            throw 'Profile bundle identity mismatch'
        }
    }
    if ($Mode -eq 'ValidateArchive') { Write-Output 'PASS: archive paths, fingerprint and SDK runtime match'; return }

    if (-not $IsWindows) { throw 'Probe preparation requires Windows' }
    Assert-OutputPath
    if (Test-Path -LiteralPath $outputPath) { throw 'Probe preparation requires a new output directory' }
    if ($Mode -eq 'PrepareProfile') {
        if ($RuntimeMode -cne 'Profile') { throw 'Profile preparation requires Profile mode' }
        $sourceCommit = $nativeCommit
    } else {
        if ($RuntimeMode -cne 'Debug' -or $NativeCommit -cne '4db58997ffe16a62da204344578a5f4b7fd9c320' -or
            $ExpectedArchiveSha256 -cne 'de1a70bc15352cd8699a928eebb261913753e68a8c75dbe1f065733caba54290') {
            throw 'Debug preparation requires the pinned GitHub artifact'
        }
        $status = @(git -C $probeRoot status --porcelain)
        if ($LASTEXITCODE -ne 0 -or $status.Count) { throw 'Commit the probe source before preparing its runtime' }
        $sourceCommit = git -C $probeRoot rev-parse HEAD
        if ($LASTEXITCODE -ne 0 -or $sourceCommit -cnotmatch '^[0-9a-f]{40}$') { throw 'Cannot identify probe source' }
        git -C $probeRoot diff --quiet $nativeCommit HEAD -- windows pubspec.yaml pubspec.lock
        if ($LASTEXITCODE -ne 0) { throw 'Native source or dependency drift; obtain a fresh matching GitHub bundle' }
    }
    $runtime = Join-Path $outputPath 'runtime'
    [void][IO.Directory]::CreateDirectory($runtime)
    foreach ($entry in $archive.Entries) {
        if (($Mode -eq 'Prepare' -and $entry.FullName.StartsWith('data/flutter_assets/', [StringComparison]::OrdinalIgnoreCase)) -or
            $entry.FullName.EndsWith('/')) { continue }
        $target = Join-Path $runtime $entry.FullName
        [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $false)
    }
} finally { $archive.Dispose() }
if ($Mode -eq 'PrepareProfile') {
    [ordered]@{ schemaVersion = 1; sourceCommit = $sourceCommit; nativeCommit = $nativeCommit; runtimeMode = $RuntimeMode;
        archiveSha256 = $ExpectedArchiveSha256; files = @(Get-Inventory $runtime) } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputPath 'manifest.json') -Encoding utf8
    Write-Output "PASS: unmodified Profile diagnostic prepared; source=native=$sourceCommit"
    return
}
$nativeBefore = Get-Inventory $runtime
$assetDirectory = Join-Path $runtime 'data/flutter_assets'
Push-Location $probeRoot
try {
    & (Join-Path $FlutterRoot 'bin/flutter.bat') build bundle --debug --no-pub --target-platform=windows-x64 `
        --target=integration_test/windows_audio_probe.dart "--asset-dir=$assetDirectory" `
        --dart-define=YYMUSIC_WINDOWS_AUDIO_PROBE=true "--dart-define=YYMUSIC_PROBE_SOURCE_COMMIT=$sourceCommit" `
        "--dart-define=YYMUSIC_PROBE_NATIVE_COMMIT=$nativeCommit" `
        --dart-define=INTEGRATION_TEST_SHOULD_REPORT_RESULTS_TO_NATIVE=false
    if ($LASTEXITCODE -ne 0) { throw 'Probe Dart bundle build failed' }
} finally { Pop-Location }
foreach ($file in $nativeBefore) {
    if ((Get-FileHash -LiteralPath (Join-Path $runtime $file.path)).Hash -ine $file.sha256) {
        throw 'Native bundle bytes changed while preparing Dart assets'
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $runtime 'data/flutter_assets/kernel_blob.bin'))) {
    throw 'Probe kernel missing'
}
$manifest = [ordered]@{ schemaVersion = 1; sourceCommit = $sourceCommit; nativeCommit = $nativeCommit; runtimeMode = $RuntimeMode;
    archiveSha256 = $ExpectedArchiveSha256; files = @(Get-Inventory $runtime) }
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $outputPath 'manifest.json') -Encoding utf8
Write-Output "PASS: isolated diagnostic prepared; source=$sourceCommit native=$nativeCommit"
