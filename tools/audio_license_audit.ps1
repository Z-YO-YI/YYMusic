#Requires -Version 7.0
# Read-only helpers shared by the source and packaged-notice checks.

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
