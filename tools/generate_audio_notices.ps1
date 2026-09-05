#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$InventoryPath = 'build/audio-dependencies-debug.json',
    [string]$GradleCache = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.gradle/caches/modules-2/files-2.1'),
    [string]$ApacheLicensePath,
    [switch]$Check
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'audio_license_audit.ps1')
$noticeRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$utf8 = [Text.UTF8Encoding]::new($false, $true)
$inventory = Get-Content -LiteralPath ([IO.Path]::GetFullPath($InventoryPath, $noticeRoot)) -Raw | ConvertFrom-Json
if ($inventory.schemaVersion -ne 1 -or $inventory.variant -cnotin @('debug','profile','release') -or
    $inventory.components.Count -lt 1 -or $inventory.components.Count -gt 200) { throw 'Invalid native audio inventory' }
if ($inventory.variant -ceq 'release') { throw 'Author notice superset from debug/profile; verify release identity with native_audio_notices.mjs' }
$documents = [ordered]@{}
function Add-NoticeDocument([byte[]]$Bytes) {
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt 1MB) { throw 'Invalid legal document size' }
    $sha = [Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData($Bytes))
    $value = $utf8.GetString($Bytes)
    if (!$documents.Contains($sha)) { $documents[$sha] = [ordered]@{ sha256=$sha; bytes=$Bytes.Length; text=$value } }
    return $sha
}
$output = Join-Path $noticeRoot 'assets/legal/android_audio/notices.json'
$apacheBytes = if ($ApacheLicensePath) {
    [IO.File]::ReadAllBytes([IO.Path]::GetFullPath($ApacheLicensePath, $noticeRoot))
} elseif ($Check -and (Test-Path -LiteralPath $output)) {
    $existing = Get-Content -LiteralPath $output -Raw | ConvertFrom-Json
    $canonical = @($existing.documents | Where-Object sha256 -CEQ 'cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30')
    if ($canonical.Count -ne 1) { throw 'Missing pinned source license' }
    $utf8.GetBytes($canonical[0].text)
} else { throw 'Generating new materials requires a pinned ApacheLicensePath' }
$apacheSha = Add-NoticeDocument $apacheBytes
if ($apacheSha -cne 'cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30') {
    throw 'Apache license must match the pinned Media3 source LICENSE'
}
function Read-Pom([string]$Coordinate, [int]$Depth = 0) {
    if ($Depth -gt 8 -or $Coordinate -cnotmatch '^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+$') { throw 'Invalid POM identity or parent chain' }
    $parts = $Coordinate.Split(':')
    $directory = Join-Path $GradleCache ($parts -join '/')
    $pomFiles = @(Get-ChildItem -LiteralPath $directory -Filter ($parts[1]+'-'+$parts[2]+'.pom') -File -Recurse)
    if ($pomFiles.Count -ne 1 -or $pomFiles[0].Length -gt 1MB) { throw 'Missing, duplicate or oversized resolved POM' }
    $bytes = [IO.File]::ReadAllBytes($pomFiles[0].FullName)
    $settings = [Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $reader = [Xml.XmlReader]::Create([IO.StringReader]::new($utf8.GetString($bytes)), $settings)
    $xml = [Xml.XmlDocument]::new()
    $xml.XmlResolver = $null
    try { $xml.Load($reader) } finally { $reader.Dispose() }
    $licenses = @($xml.SelectNodes('/*[local-name()="project"]/*[local-name()="licenses"]/*[local-name()="license"]') | ForEach-Object {
        [ordered]@{ name=$_.SelectSingleNode('*[local-name()="name"]').InnerText; url=$_.SelectSingleNode('*[local-name()="url"]').InnerText }
    })
    $chain = @([ordered]@{ coordinate=$Coordinate; bytes=$bytes.Length; sha256=[Convert]::ToHexStringLower([Security.Cryptography.SHA256]::HashData($bytes)) })
    if ($licenses.Count -eq 0) {
        $parent = $xml.SelectSingleNode('/*[local-name()="project"]/*[local-name()="parent"]')
        if ($null -eq $parent) { throw 'POM has no license or parent' }
        $identity = @('groupId','artifactId','version') | ForEach-Object { $parent.SelectSingleNode('*[local-name()="'+$_+'"]').InnerText }
        $inherited = Read-Pom ($identity -join ':') ($Depth+1)
        $licenses = $inherited.licenses
        $chain += $inherited.chain
    }
    return @{ licenses=$licenses; chain=$chain }
}
function Read-ZipNotices([IO.Compression.ZipArchive]$Zip, [string]$Prefix = '') {
    $result = @()
    foreach ($entry in $Zip.Entries) {
        $name = $entry.FullName
        if ($name -match '(?i)(^|/)([^/]*(license|notice|copying)[^/.]*(\.(txt|md|html))?|AL2\.0|LGPL2\.1)$' -and $entry.Length -gt 0) {
            if ($entry.Length -gt 1MB) { throw 'Oversized embedded notice' }
            $stream = $entry.Open()
            try { $sha = Add-NoticeDocument (Read-YyBoundedBytes -Stream $stream -Limit 1MB) }
            finally { $stream.Dispose() }
            $result += [ordered]@{ path=$Prefix+$name; document=$sha }
        }
        if ($name -ceq 'classes.jar') {
            if ($entry.Length -gt 32MB) { throw 'Oversized nested classes archive' }
            $stream = $entry.Open()
            $memory = [IO.MemoryStream]::new()
            try {
                $nestedBytes = Read-YyBoundedBytes -Stream $stream -Limit 32MB
                $memory.Write($nestedBytes); $memory.Position = 0
                $nested = [IO.Compression.ZipArchive]::new($memory, 'Read', $true)
                try { $result += @(Read-ZipNotices $nested ($name+'!/')) } finally { $nested.Dispose() }
            } finally { $stream.Dispose(); $memory.Dispose() }
        }
    }
    return $result
}
$components = @()
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($component in $inventory.components) {
    if (!$seen.Add($component.coordinate)) { throw 'Duplicate native component' }
    $pom = Read-Pom $component.coordinate
    $licenseDocuments = @()
    $artifactRecords = @()
    foreach ($artifact in $component.artifacts) {
        $file = Get-Item -LiteralPath $artifact.path
        if ($file.Name -cne $artifact.name -or $file.Length -ne $artifact.bytes -or
            (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() -cne $artifact.sha256) {
            throw 'Resolved artifact fingerprint mismatch'
        }
        $zip = [IO.Compression.ZipFile]::OpenRead($file.FullName)
        try { $notices = @(Read-ZipNotices $zip) } finally { $zip.Dispose() }
        $artifactRecords += [ordered]@{ name=$artifact.name; bytes=$artifact.bytes; sha256=$artifact.sha256; notices=$notices }
    }
    foreach ($license in $pom.licenses) {
        if ($license.name -match 'Apache' -and $license.url -match '^https?://(www\.)?apache\.org/licenses/LICENSE-2\.0(\.txt)?/?$') {
            $licenseDocuments += $apacheSha
        } elseif ($component.coordinate -ceq 'org.checkerframework:checker-qual:3.41.0' -and $license.name -ceq 'The MIT License') {
            $checker = @($artifactRecords.notices | Where-Object path -CEQ 'META-INF/LICENSE.txt')
            if ($checker.Count -ne 1) { throw 'Missing exact checker-qual MIT text' }
            $licenseDocuments += $checker[0].document
        } else { throw ('Unreviewed native license for ' + $component.coordinate) }
    }
    $components += [ordered]@{ coordinate=$component.coordinate; declaredLicenses=$pom.licenses; poms=$pom.chain; licenseDocuments=@($licenseDocuments | Sort-Object -Unique); artifacts=$artifactRecords }
}
$orderedDocuments = @($documents.Values | Sort-Object { $_.sha256 } -CaseSensitive)
$bundle = [ordered]@{
    schemaVersion=1
    scope='resolved-android-media3-audio-closure'
    sourceLicenseUrl='https://github.com/androidx/media/blob/c35a9d62baec57118ea898e271ac66819399649b/LICENSE'
    components=$components
    documents=$orderedDocuments
}
$json = (($bundle | ConvertTo-Json -Depth 30) + "`n").Replace("`r`n", "`n")
if ($Check) {
    if (!(Test-Path -LiteralPath $output) -or [IO.File]::ReadAllText($output) -cne $json) { throw 'Native notice bundle differs from resolved source materials' }
} else {
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($output))
    [IO.File]::WriteAllText($output, $json, [Text.UTF8Encoding]::new($false))
}
"PASS: $($components.Count) native audio coordinates and $($orderedDocuments.Count) full legal documents; check=$Check."
