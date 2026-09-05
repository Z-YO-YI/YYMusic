param([string]$BundlePath = 'build/windows/x64/runner/Debug')
$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskBundlePath = [IO.Path]::GetFullPath((Join-Path $taskRoot $BundlePath))
$taskRootPrefix = $taskRoot + [IO.Path]::DirectorySeparatorChar
if (-not $taskBundlePath.StartsWith($taskRootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Windows bundle path must remain inside the YYMusic checkout'
}
if (-not (Test-Path -LiteralPath $taskBundlePath -PathType Container)) {
    throw "Windows bundle directory does not exist: $BundlePath"
}

foreach ($taskRequiredPath in @(
    'yymusic.exe',
    'flutter_windows.dll',
    'data/flutter_assets/AssetManifest.bin'
)) {
    $taskResolvedPath = Join-Path $taskBundlePath $taskRequiredPath
    if (-not (Test-Path -LiteralPath $taskResolvedPath -PathType Leaf)) {
        throw "Required Windows bundle file is missing: $taskRequiredPath"
    }
}

$taskRejectedFiles = @(Get-ChildItem -LiteralPath $taskBundlePath -Recurse -File | Where-Object {
    $_.Name -match '^(?:libmpv(?:-2)?\.dll|media_kit.*)$' -or
    $_.FullName -match '[\\/]media_kit[^\\/]*[\\/]'
})
if ($taskRejectedFiles.Count -gt 0) {
    $taskRejectedNames = @($taskRejectedFiles | ForEach-Object {
        [IO.Path]::GetRelativePath($taskBundlePath, $_.FullName).Replace('\', '/')
    }) -join ', '
    throw "Rejected media_kit native content unexpectedly packaged in Windows bundle: $taskRejectedNames"
}

$taskFileCount = @(Get-ChildItem -LiteralPath $taskBundlePath -Recurse -File).Count
Write-Output "PASS: Windows bundle contains $taskFileCount files and no rejected media_kit native content."
