#Requires -Version 7.0
# Read-only helpers shared by the source and packaged-notice checks.

function Resolve-YyAudioPackageRoot {
    param([string]$Name, [string]$RootUri, [string]$RepositoryRoot)
    try { $uri = [Uri]::new($RootUri, [UriKind]::RelativeOrAbsolute) }
    catch { throw 'Invalid audio package root URI' }
    if ($Name -ceq 'just_audio_windows') {
        if ($RootUri -match '[?#]') { throw 'Invalid local Windows audio package URI' }
        if (!$uri.IsAbsoluteUri) {
            $configUri = [Uri]::new([IO.Path]::GetFullPath((Join-Path $RepositoryRoot '.dart_tool/package_config.json')))
            $uri = [Uri]::new($configUri, $uri)
        }
        if (!$uri.IsFile -or $uri.Query -or $uri.Fragment) { throw 'Invalid local Windows audio package URI' }
        $expected = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'third_party/just_audio_windows'))
        $actual = [IO.Path]::GetFullPath($uri.LocalPath).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
        $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
        if (!$actual.Equals($expected, $comparison)) { throw 'Windows audio package must resolve to the audited local fork' }
        $cursor = $actual
        while ($cursor) {
            if ((Test-Path -LiteralPath $cursor) -and
                ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw 'Linked Windows audio package root refused'
            }
            $cursor = [IO.Path]::GetDirectoryName($cursor)
        }
        return $actual
    }
    if (!$uri.IsAbsoluteUri -or !$uri.IsFile -or $uri.Query -or $uri.Fragment) {
        throw 'Audio package must use a local resolved cache'
    }
    return $uri.LocalPath
}

function Read-YyBoundedBytes {
    param([IO.Stream]$Stream, [long]$Limit)
    $buffer = [byte[]]::new(65536)
    $output = [IO.MemoryStream]::new()
    try {
        while (($count = $Stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($output.Length + $count -gt $Limit) { throw 'Audio notice size limit exceeded' }
            $output.Write($buffer, 0, $count)
        }
        return ,$output.ToArray()
    } finally { $output.Dispose() }
}

function Assert-YyLicenseBytes {
    param([byte[]]$Bytes, $Expected)
    if ($Expected.sha256 -cnotmatch '^[0-9a-f]{64}$' -or
        $Expected.bytes -lt 1 -or $Expected.bytes -gt 512KB -or
        $Bytes.Length -ne $Expected.bytes -or
        [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant() -cne $Expected.sha256) {
        throw 'Audio license fingerprint mismatch'
    }
}

function Assert-YyAudioNotices {
    param([byte[]]$Compressed, [object[]]$ExpectedLicenses)
    if (!$ExpectedLicenses -or $ExpectedLicenses.Count -eq 0) { throw 'Empty audio license manifest' }
    if ($Compressed.Length -lt 1 -or $Compressed.Length -gt 4MB) { throw 'Audio notice compressed size limit exceeded' }
    $inputStream = [IO.MemoryStream]::new($Compressed, $false)
    $gzipStream = [IO.Compression.GZipStream]::new($inputStream, [IO.Compression.CompressionMode]::Decompress)
    try {
        $bytes = Read-YyBoundedBytes -Stream $gzipStream -Limit 16MB
        $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    } catch {
        throw 'Audio notice decompression or UTF-8 validation failed'
    } finally { $gzipStream.Dispose(); $inputStream.Dispose() }
    $groups = $text.Split("`n" + ('-' * 80) + "`n", [StringSplitOptions]::None)
    if ($groups.Count -gt 10000) { throw 'Audio notice group limit exceeded' }
    $expectedNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($license in $ExpectedLicenses) {
        if ($license.name -cnotmatch '^[a-z][a-z0-9_]*$' -or !$expectedNames.Add($license.name)) {
            throw 'Invalid audio license manifest names'
        }
    }
    if ($expectedNames.Count -eq 0) { throw 'Empty audio license manifest' }
    $found = [Collections.Generic.Dictionary[string, byte[]]]::new([StringComparer]::Ordinal)
    foreach ($group in $groups) {
        $split = $group.IndexOf("`n`n", [StringComparison]::Ordinal)
        if ($split -lt 0) { continue } # SDK notices may contain unattributed sections.
        $names = $group.Substring(0, $split).Split("`n")
        foreach ($name in $names) {
            if (!$expectedNames.Contains($name)) { continue }
            if ($found.ContainsKey($name)) { throw 'Duplicate audio license package' }
            $found.Add($name, [Text.Encoding]::UTF8.GetBytes($group.Substring($split + 2)))
        }
    }
    foreach ($license in $ExpectedLicenses) {
        if (!$found.ContainsKey($license.name)) { throw 'Required audio license package missing' }
        Assert-YyLicenseBytes -Bytes $found[$license.name] -Expected $license
    }
}
