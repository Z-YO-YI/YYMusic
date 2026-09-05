import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const script = join(root, 'tools/windows_audio_probe.ps1').replaceAll("'", "''");
function fixtureCheck(mutation, expected, { wrongHash = false, omitFile = '' } = {}) {
  // PowerShell fixtures exercise the actual archive guard on all CI hosts.
  const command = `
    $ErrorActionPreference = 'Stop'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('yymusic-probe-test-' + [guid]::NewGuid())
    [void][IO.Directory]::CreateDirectory($fixtureRoot)
    try {
      $sdk = Join-Path $fixtureRoot 'sdk'
      $dll = Join-Path $sdk 'bin/cache/artifacts/engine/windows-x64/flutter_windows.dll'
      [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dll))
      [IO.File]::WriteAllText($dll, 'fixture engine')
      $zipPath = Join-Path $fixtureRoot 'fixture.zip'
      $zip = [IO.Compression.ZipFile]::Open($zipPath, 'Create')
      try {
        foreach ($name in @('yymusic.exe', 'flutter_windows.dll', 'just_audio_windows_plugin.dll',
          'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin')) {
          if ($name -eq '${omitFile}') { continue }
          $entry = $zip.CreateEntry($name)
          $writer = [IO.StreamWriter]::new($entry.Open())
          try { $writer.Write('fixture engine') } finally { $writer.Dispose() }
        }
        ${mutation}
      } finally { $zip.Dispose() }
      $hash = (Get-FileHash -LiteralPath $zipPath).Hash.ToLowerInvariant()
      ${wrongHash ? "$hash = '0' * 64" : ''}
      & '${script}' -Mode ValidateArchive -ArchivePath $zipPath -ExpectedArchiveSha256 $hash -FlutterRoot $sdk
    } finally {
      # Only delete the resolved, uniquely named fixture directly beneath temp.
      $resolved = [IO.Path]::GetFullPath($fixtureRoot)
      $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
      if ([IO.Path]::GetDirectoryName($resolved) -ne $tempRoot -or
        [IO.Path]::GetFileName($resolved) -notlike 'yymusic-probe-test-*') { throw 'Unsafe fixture cleanup' }
      Remove-Item -LiteralPath $resolved -Recurse -Force
    }
  `;
  const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null);
  const output = result.stdout + result.stderr;
  if (expected === null) assert.equal(result.status, 0, output);
  else {
    assert.notEqual(result.status, 0, output);
    assert.match(output, expected);
  }
}

test('Windows probe accepts a complete, hash-matched runtime without executing it', () => fixtureCheck('', null));
test('Windows probe rejects archive traversal and Windows path aliases', () => {
  for (const path of ['../escape.dll', 'C:/escape.dll', 'data/CON.txt', 'data/trailing.', 'data//empty']) {
    fixtureCheck(`$null = $zip.CreateEntry('${path}')`, /Unsafe/);
  }
});
test('Windows probe rejects duplicate paths, collisions, links and retired native content', () => {
  fixtureCheck("$null = $zip.CreateEntry('YYMUSIC.EXE')", /Duplicate archive path/);
  fixtureCheck("$null = $zip.CreateEntry('data')", /file\/directory collision/);
  fixtureCheck("$entry = $zip.CreateEntry('linked'); $entry.ExternalAttributes = -1610612736", /links or special files refused/);
  fixtureCheck("$null = $zip.CreateEntry('libmpv-2.dll')", /rejected archive path/);
});
test('Windows probe rejects an SDK engine mismatch', () => {
  fixtureCheck("[IO.File]::WriteAllText($dll, 'different engine')", /does not match the local SDK/);
});
test('Windows probe rejects changed fingerprints and incomplete native bundles', () => {
  fixtureCheck('', /Archive SHA-256 mismatch/, { wrongHash: true });
  fixtureCheck('', /Required native bundle file missing/, { omitFile: 'just_audio_windows_plugin.dll' });
});
test('Windows probe remains isolated, opt-in, timeout-bounded and tied to one real native test', () => {
  const entry = readFileSync(join(root, 'integration_test/windows_audio_probe.dart'), 'utf8');
  const tooling = readFileSync(join(root, 'tools/windows_audio_probe.ps1'), 'utf8');
  assert.match(entry, /!kDebugMode/);
  assert.match(entry, /!Platform\.isWindows/);
  assert.match(entry, /YYMUSIC_WINDOWS_AUDIO_PROBE/);
  assert.match(entry, /native_poc\.main\(\)/);
  assert.match(entry, /allTestsPassed\.future\.timeout/);
  assert.match(tooling, /git -C \$probeRoot diff --quiet \$nativeCommit HEAD -- windows pubspec\.yaml pubspec\.lock/);
  assert.match(tooling, /-WindowStyle Hidden/);
  assert.match(tooling, /\$process\.WaitForExit\(1000\)/);
  assert.match(tooling, /\$process\.Kill\(\)/);
  assert.doesNotMatch(tooling, /Set-Service|Set-ItemProperty|Remove-Item|Invoke-RestMethod|git push/);
  assert.doesNotMatch(readFileSync(join(root, 'lib/main.dart'), 'utf8'), /windows_audio_probe/);
});
