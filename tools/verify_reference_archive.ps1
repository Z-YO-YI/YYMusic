# Read-only integrity check. Never execute or normalize files from the archive.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$auditRoot = Split-Path -Parent $PSScriptRoot
$archivePath = Join-Path $auditRoot 'design_reference/YYMusic_HTML.zip'
$exportPath = [IO.Path]::GetFullPath((Join-Path $auditRoot 'design_reference/figma_export'))
$exportPrefix = $exportPath + [IO.Path]::DirectorySeparatorChar
$archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($archiveHash -ne 'd75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee') {
    throw 'Archive fingerprint differs from the audited source.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$verified = 0
try {
    foreach ($entry in $archive.Entries) {
        if ([string]::IsNullOrEmpty($entry.Name)) { continue }
        $targetPath = [IO.Path]::GetFullPath((Join-Path $exportPath $entry.FullName))
        if (-not $targetPath.StartsWith($exportPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Archive entry escapes the reference directory: $($entry.FullName)"
        }
        if (-not $seen.Add($targetPath)) { throw "Duplicate archive target: $($entry.FullName)" }
        if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
            throw "Missing extracted reference: $($entry.FullName)"
        }
        $entryStream = $entry.Open()
        $hasher = [Security.Cryptography.SHA256]::Create()
        try {
            $entryHash = [BitConverter]::ToString($hasher.ComputeHash($entryStream)).Replace('-', '')
        } finally {
            $hasher.Dispose()
            $entryStream.Dispose()
        }
        $fileInfo = Get-Item -LiteralPath $targetPath
        $fileHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
        if ($fileInfo.Length -ne $entry.Length -or $fileHash -ne $entryHash) {
            throw "Extracted reference differs from ZIP bytes: $($entry.FullName)"
        }
        $verified++
    }
    $extracted = @(Get-ChildItem -LiteralPath $exportPath -File -Recurse -Force)
    if ($extracted.Count -ne $verified -or $verified -ne 24) {
        throw "Unexpected file count: ZIP=$verified, extracted=$($extracted.Count), expected=24"
    }
    Write-Output "PASS: all $verified extracted files match the original ZIP byte-for-byte."
} finally {
    $archive.Dispose()
}
