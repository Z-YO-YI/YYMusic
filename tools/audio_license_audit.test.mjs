import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { gzipSync } from 'node:zlib';
import { root } from './design_audit.mjs';

const read = path => readFileSync(join(root, path), 'utf8');
const separator = `\n${'-'.repeat(80)}\n`;
const license = 'Synthetic license text for validator tests.\n';
const hash = text => createHash('sha256').update(text).digest('hex');
const expected = ['alpha', 'beta'].map(name => ({ name, bytes: Buffer.byteLength(license), sha256: hash(license) }));

function checkNotice(text, error, { bytesExpression, expectedEntries = expected } = {}) {
  const compressed = gzipSync(Buffer.isBuffer(text) ? text : Buffer.from(text));
  const helper = join(root, 'tools/audio_license_audit.ps1').replaceAll("'", "''");
  const command = `
    $ErrorActionPreference = 'Stop'
    Set-StrictMode -Version Latest
    . '${helper}'
    $compressed = ${bytesExpression ?? `[Convert]::FromBase64String('${compressed.toString('base64')}')`}
    $expected = '${JSON.stringify(expectedEntries)}' | ConvertFrom-Json
    Assert-YyAudioNotices -Compressed $compressed -ExpectedLicenses @($expected)
    'PASS'
  `;
  const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  const output = result.stdout + result.stderr;
  if (error === null) {
    assert.equal(result.status, 0, output);
    assert.match(output, /PASS/);
  } else {
    assert.notEqual(result.status, 0, output);
    assert.match(output, error);
  }
}

test('audio license ledger pins all six package identities and does not approve a complete release', () => {
  const manifest = JSON.parse(read('docs/legal/just_audio/manifest.json'));
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.coverage, 'six-dart-audio-packages-only');
  assert.equal(manifest.bundleAsset, 'NOTICES.Z');
  assert.equal(manifest.productionWiringApproved, false);
  assert.equal(manifest.releaseApproved, false);
  assert.deepEqual(manifest.packages.map(({ name, version, bytes }) => [name, version, bytes]), [
    ['just_audio', '0.10.6', 12644], ['just_audio_windows', '0.2.3', 1099],
    ['just_audio_platform_interface', '4.6.0', 1097], ['just_audio_web', '0.4.16', 1097],
    ['audio_session', '0.2.4', 1097], ['rxdart', '0.28.0', 11357],
  ]);
  assert.deepEqual(manifest.packages.map(p => p.sha256), [
    '63ce4443e916b27424700d7fe970003add9f54944daf732f2dbcc1d8caf1bbad',
    '5ce607ae5defa5246b2886d696c1b495e8c099fd728421c8ac1bc627b0105d4d',
    ...Array(3).fill('2568490c678ba27cc8a405238637c4ba76adc632232f05dc1c36cbf59381dba4'),
    'c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4',
  ]);
  assert.deepEqual(manifest.packages[0].license, ['MIT', 'Apache-2.0']);
  assert.equal(manifest.nativeEvidence.android.version, '1.4.1');
  assert.equal(manifest.nativeEvidence.android.transitiveNoticeReviewComplete, false);
  assert.deepEqual(manifest.nativeEvidence.windows.additionalBundledPlayerLibraries, []);
  assert.equal(manifest.capabilities.requestHeaders, false);
  assert.equal(manifest.capabilities.proxyForHeaders, false);
  assert.equal(manifest.capabilities.productionAudioConnected, false);
  assert.deepEqual(manifest.sourceFiles.map(p => [p.package, p.path]), [
    ['just_audio', 'android/build.gradle.kts'], ['just_audio_windows', 'windows/CMakeLists.txt'],
  ]);
  assert.match(read('.github/workflows/foundation.yml'), /flutter pub get --enforce-lockfile\n\s+- name: Verify locked audio license sources\n\s+shell: pwsh\n\s+run: .\/tools\/verify_audio_licenses\.ps1 -Mode Source/);
  assert.match(read('tools/verify_android_apk.ps1'), /verify_audio_licenses\.ps1'\) -Mode Android/);
  assert.match(read('tools/verify_windows_bundle.ps1'), /verify_audio_licenses\.ps1'\) -Mode Windows/);
  assert.match(read('tools/verify_audio_licenses.ps1'), /\$Mode -eq 'Source'/);
  assert.match(read('tools/verify_audio_licenses.ps1'), /\$Mode -eq 'Android'/);
  assert(!/Invoke-WebRequest|Invoke-RestMethod|Start-Process|Set-Content|WriteAll/.test(read('tools/verify_audio_licenses.ps1')));
});

test('notice validator accepts separate or deduplicated complete package license groups', () => {
  checkNotice(`alpha\nbeta\n\n${license}${separator}other\n\nOther legal text.`, null);
  checkNotice(`alpha\n\n${license}${separator}beta\n\n${license}`, null);
});

test('notice validator rejects missing, duplicate, mislabeled and altered full texts', () => {
  checkNotice(`alpha\n\n${license}`, /Required audio license package missing/);
  checkNotice(`alpha\nalpha\nbeta\n\n${license}`, /Duplicate audio license package/);
  checkNotice(`alpha\nbeta\n\n${license}${separator}alpha\n\n${license}`, /Duplicate audio license package/);
  checkNotice(`other\n\nalpha\nbeta\n\n${license}`, /Required audio license package missing/);
  checkNotice(`alpha\nbeta\n\n${license.replace('Synthetic', 'synthetic')}`, /Audio license fingerprint mismatch/);
  checkNotice(`alpha\nbeta\n\n${license}`, /Empty audio license manifest/, { expectedEntries: [] });
});

test('notice validator fails closed for invalid compression, UTF-8 and bounded expansion', () => {
  checkNotice(Buffer.from([0xff, 0xfe]), /decompression or UTF-8 validation failed/);
  checkNotice('', /decompression or UTF-8 validation failed/, { bytesExpression: '[byte[]]@(1,2,3,4,5)' });
  checkNotice('', /compressed size limit exceeded/, { bytesExpression: '[byte[]]::new(4MB + 1)' });
  checkNotice('', /decompression or UTF-8 validation failed/, { bytesExpression: `& {
    $output = [IO.MemoryStream]::new()
    $gzip = [IO.Compression.GZipStream]::new($output, [IO.Compression.CompressionLevel]::Fastest, $true)
    try { $gzip.Write([byte[]]::new(16MB + 1)); $gzip.Dispose(); return ,$output.ToArray() }
    finally { $gzip.Dispose(); $output.Dispose() }
  }` });
});

test('actual APK entry point rejects invalid entries and routes case-insensitive modes consistently', () => {
  const script = join(root, 'tools/verify_audio_licenses.ps1').replaceAll("'", "''");
  for (const [count, oversized, mode, expectedError] of [
    [0, false, 'Android', /Missing or duplicate Android NOTICES.Z/],
    [0, false, 'android', /Missing or duplicate Android NOTICES.Z/],
    [0, false, 'aNdRoId', /Missing or duplicate Android NOTICES.Z/],
    [2, false, 'Android', /Missing or duplicate Android NOTICES.Z/],
    [1, true, 'Android', /compressed size limit exceeded/],
  ]) {
    const command = `
      $ErrorActionPreference = 'Stop'
      $fixture = Join-Path ([IO.Path]::GetTempPath()) ('yymusic-notice-test-' + [guid]::NewGuid())
      [void][IO.Directory]::CreateDirectory($fixture)
      try {
        $path = Join-Path $fixture 'fixture.apk'
        $zip = [IO.Compression.ZipFile]::Open($path, 'Create')
        try {
          for ($index = 0; $index -lt ${count}; $index++) {
            $entry = $zip.CreateEntry('assets/flutter_assets/NOTICES.Z')
            $stream = $entry.Open()
            try { $stream.Write([byte[]]::new(${oversized ? '4MB + 1' : '1'})) }
            finally { $stream.Dispose() }
          }
        } finally { $zip.Dispose() }
        & '${script}' -Mode ${mode} -ApkPath $path
      } finally {
        $resolved = [IO.Path]::GetFullPath($fixture)
        $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
        if ([IO.Path]::GetDirectoryName($resolved) -ne $temp -or
            [IO.Path]::GetFileName($resolved) -notlike 'yymusic-notice-test-*') { throw 'Unsafe fixture cleanup' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
      }
    `;
    const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
      encoding: 'utf8', timeout: 30000, windowsHide: true,
    });
    assert.ifError(result.error);
    assert.notEqual(result.status, 0);
    assert.match(result.stdout + result.stderr, expectedError);
  }
});
