import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

const script = join(root, 'tools/windows_audio_probe.ps1').replaceAll("'", "''");
function fixtureCheck(mutation, expected, { wrongHash = false, omitFile = '', profile = false, wrongCommit = false, https = false, requestHttps = https, invalidHttps = false, sequence = false, requestSequence = sequence, invalidSequence = false, rootRepeat = false, requestRootRepeat = rootRepeat, invalidRoot = false } = {}) {
  const metadataName = rootRepeat ? 'native-root-repeat-build.json' : 'native-audio-build.json';
  // PowerShell fixtures exercise the actual archive guard on all CI hosts.
  const command = `
    $ErrorActionPreference = 'Stop'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('yymusic-probe-test-' + [guid]::NewGuid())
    [void][IO.Directory]::CreateDirectory($fixtureRoot)
    try {
      $sdk = Join-Path $fixtureRoot 'sdk'
      $dll = Join-Path $sdk 'bin/cache/artifacts/engine/windows-x64${profile ? '-profile' : ''}/flutter_windows.dll'
      [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dll))
      [IO.File]::WriteAllText($dll, 'fixture engine')
      $zipPath = Join-Path $fixtureRoot 'fixture.zip'
      $zip = [IO.Compression.ZipFile]::Open($zipPath, 'Create')
      try {
        foreach ($name in @('yymusic.exe', 'flutter_windows.dll', 'just_audio_windows_plugin.dll',
          'data/icudtl.dat', 'data/flutter_assets/AssetManifest.bin'${profile ? `, 'data/app.so', '${metadataName}'` : ''})) {
          if ($name -eq '${omitFile}') { continue }
          $entry = $zip.CreateEntry($name)
          $writer = [IO.StreamWriter]::new($entry.Open())
          try {
            if ($name -eq '${metadataName}') {
              $writer.Write('{"schemaVersion":1,"sourceCommit":"${'1'.repeat(40)}","nativeCommit":"${(wrongCommit ? '2' : '1').repeat(40)}","runtimeMode":"Profile","purpose":"${rootRepeat ? 'isolated-windows-root-repeat-test' : sequence ? 'isolated-native-sequence-test' : https ? 'isolated-audio-source-test' : 'isolated-local-wav-test'}","flutterVersion":"3.47.2"${https ? `,"includeHttps":${invalidHttps ? '"true"' : 'true'}` : ''}${sequence ? `,"includeSequence":${invalidSequence ? '"true"' : 'true'}` : ''}${rootRepeat ? `,"includeRootRepeat":${invalidRoot ? '"true"' : 'true'}` : ''}}')
            } else { $writer.Write('fixture engine') }
          } finally { $writer.Dispose() }
        }
        ${mutation}
      } finally { $zip.Dispose() }
      $hash = (Get-FileHash -LiteralPath $zipPath).Hash.ToLowerInvariant()
      ${wrongHash ? "$hash = '0' * 64" : ''}
      & '${script}' -Mode ValidateArchive -ArchivePath $zipPath -ExpectedArchiveSha256 $hash -FlutterRoot $sdk ${profile ? `-RuntimeMode Profile -NativeCommit '${'1'.repeat(40)}'` : ''} ${requestHttps ? '-IncludeHttps' : ''} ${requestSequence ? '-IncludeSequence' : ''} ${requestRootRepeat ? '-IncludeRootRepeat' : ''}
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
test('Profile probe validates exact AOT identity and rejects Debug kernels or mismatched commits', () => {
  fixtureCheck('', null, { profile: true });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, wrongCommit: true });
  fixtureCheck('', /Invalid Profile AOT bundle/, { profile: true, omitFile: 'data/app.so' });
  fixtureCheck("$null = $zip.CreateEntry('data/flutter_assets/kernel_blob.bin')", /Invalid Profile AOT bundle/, { profile: true });
});
test('Profile packaging refuses execution outside its explicit GitHub diagnostic context', () => {
  const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-File', join(root, 'tools/windows_audio_profile_metadata.ps1')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true, env: { ...process.env, GITHUB_ACTIONS: 'false' },
  });
  assert.ifError(result.error);
  assert.notEqual(result.status, 0);
  assert.match(result.stdout + result.stderr, /Only the manual YYMusic CI diagnostic/);
});
test('HTTPS Profile diagnostics require an exact opt-in mode and reject legacy or malformed metadata', () => {
  fixtureCheck('', null, { profile: true, https: true });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, https: true, requestHttps: false });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, requestHttps: true });
  fixtureCheck('', /Invalid HTTPS probe mode/, { profile: true, https: true, invalidHttps: true });
  fixtureCheck('', /HTTPS probe requires/, { requestHttps: true });
});
test('Windows probe remains isolated, opt-in, timeout-bounded and tied to one real native test', () => {
  const entry = readFileSync(join(root, 'integration_test/windows_audio_probe.dart'), 'utf8');
  const tooling = readFileSync(join(root, 'tools/windows_audio_probe.ps1'), 'utf8');
  assert.match(entry, /kReleaseMode/);
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

test('sequence Profile archives cannot be confused with old WAV/HTTPS/Debug diagnostics', () => {
  fixtureCheck('', null, { profile: true, sequence: true });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, sequence: true, requestSequence: false });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, requestSequence: true });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, sequence: true, wrongCommit: true });
  fixtureCheck('', /Invalid sequence probe mode/, { profile: true, sequence: true, invalidSequence: true });
  fixtureCheck('', /Sequence probe requires/, { requestSequence: true });
  fixtureCheck('', /Sequence probe requires/, { profile: true, sequence: true, requestHttps: true });
});

test('Windows root Profile archives keep their own strict identity and mode', () => {
  fixtureCheck('', null, { profile: true, rootRepeat: true });
  fixtureCheck('', /Invalid Profile AOT bundle/, { profile: true, rootRepeat: true, requestRootRepeat: false });
  fixtureCheck('', /Invalid Profile AOT bundle/, { profile: true, requestRootRepeat: true });
  fixtureCheck('', /Profile bundle identity mismatch/, { profile: true, rootRepeat: true, wrongCommit: true });
  fixtureCheck('', /Invalid Windows root probe mode/, { profile: true, rootRepeat: true, invalidRoot: true });
  fixtureCheck('', /Windows root probe requires/, { requestRootRepeat: true });
  fixtureCheck('', /Windows root probe requires/, { profile: true, rootRepeat: true, requestSequence: true });
  fixtureCheck('', /Windows root probe requires/, { profile: true, rootRepeat: true, requestHttps: true });
});
