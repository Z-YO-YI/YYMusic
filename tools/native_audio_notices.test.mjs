import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';
import { auditNativeNotices, validateNativeInventory, validateNativeNotices } from './native_audio_notices.mjs';

const read = path => readFileSync(join(root, path), 'utf8');
const manifest = JSON.parse(read('docs/legal/just_audio/native_manifest.json'));
const bytes = readFileSync(join(root, manifest.bundle.path));
const clone = value => structuredClone(value);
function validateChanged(change, expected) {
  const bundle = JSON.parse(bytes);
  change(bundle);
  const encoded = Buffer.from(JSON.stringify(bundle));
  const revised = clone(manifest);
  revised.bundle.bytes = encoded.length;
  revised.bundle.sha256 = createHash('sha256').update(encoded).digest('hex');
  assert.throws(() => validateNativeNotices(encoded, revised), expected);
}

test('native notice materials cover 51 resolved coordinates and complete source/embedded documents', () => {
  const bundle = auditNativeNotices();
  assert.equal(bundle.components.length, 51);
  assert.equal(bundle.documents.length, 3);
  assert.equal(bundle.components.filter(c => c.coordinate.startsWith('androidx.media3:')).length, 10);
  const checker = bundle.components.find(c => c.coordinate.startsWith('org.checkerframework:checker-qual:'));
  assert(bundle.documents.find(d => d.sha256 === checker.licenseDocuments[0]).text.includes('Copyright 2004-present'));
  const failure = bundle.components.find(c => c.coordinate.startsWith('com.google.guava:failureaccess:'));
  assert.equal(failure.poms[1].coordinate, 'com.google.guava:guava-parent:26.0-android');
  assert(!/C:\\\\Users|D:\\\\codex|\.gradle\/caches|Bearer |ghp_/.test(bytes.toString()));
  assert.match(read('pubspec.yaml'), /- assets\/legal\/android_audio\/notices\.json/);
  assert.match(read('.github/workflows/foundation.yml'), /tools\/generate_audio_notices\.ps1 -Check/);
  assert.match(read('.github/workflows/foundation.yml'), /native_audio_notices\.mjs build\/audio-dependencies-debug\.json/);
  assert.match(read('tools/verify_android_apk.ps1'), /verify_native_audio_notices\.ps1'\) -Mode Android/);
  assert.match(read('tools/verify_windows_bundle.ps1'), /verify_native_audio_notices\.ps1'\) -Mode Windows/);
});

test('native source coverage fails on missing/duplicate versions, artifacts and source fingerprints', () => {
  const bundle = auditNativeNotices();
  const inventory = { schemaVersion: 1, variant: 'debug', components: clone(bundle.components) };
  validateNativeInventory(inventory, bundle, manifest);
  for (const change of [
    v => v.components.pop(),
    v => v.components.push(clone(v.components[0])),
    v => { v.components[0].coordinate += '.changed'; },
    v => { v.components.find(c => c.artifacts.length).artifacts[0].sha256 = '0'.repeat(64); },
  ]) {
    const changed = clone(inventory); change(changed);
    assert.throws(() => validateNativeInventory(changed, bundle, manifest));
  }
  inventory.variant = 'arbitrary';
  assert.throws(() => validateNativeInventory(inventory, bundle, manifest), /Invalid resolved/);
});

test('release variant excludes exactly three inspected annotation coordinates, never arbitrary missing dependencies', () => {
  const bundle = auditNativeNotices();
  assert.deepEqual(manifest.variantExcludedCoordinates.release, [
    'com.google.code.findbugs:jsr305:3.0.2',
    'com.google.errorprone:error_prone_annotations:2.41.0',
    'org.checkerframework:checker-qual:3.41.0',
  ]);
  const inventory = {schemaVersion:1, variant:'release', components:clone(bundle.components).filter(c => !manifest.variantExcludedCoordinates.release.includes(c.coordinate))};
  assert.equal(inventory.components.length,48);
  validateNativeInventory(inventory,bundle,manifest);
  inventory.variant='debug';
  assert.throws(() => validateNativeInventory(inventory,bundle,manifest), /differ/);
  inventory.variant='release'; inventory.components.pop();
  assert.throws(() => validateNativeInventory(inventory,bundle,manifest), /differ/);
});

test('native complete-text validator rejects altered bodies, missing provenance and private paths', () => {
  const changed = Buffer.from(bytes); changed[changed.length - 4] ^= 1;
  assert.throws(() => validateNativeNotices(changed, manifest), /fingerprint mismatch/);
  validateChanged(b => { b.documents[0].text += 'changed'; }, /document fingerprint mismatch/);
  validateChanged(b => { b.documents.pop(); }, /Missing referenced/);
  validateChanged(b => { b.components[0].poms = []; }, /Missing native POM/);
  validateChanged(b => { b.components[0].licenseDocuments = []; }, /Missing complete native license/);
  validateChanged(b => { b.components.find(c => c.artifacts.length).artifacts[0].path = '/private/cache'; }, /Private cache path/);
  validateChanged(b => { b.components.pop(); }, /coordinate count/);
  const approved = clone(manifest); approved.releaseApproved = true;
  assert.throws(() => validateNativeNotices(bytes, approved), /must not approve/);
});

test('native actual package checker accepts exact bytes and rejects missing, duplicate and modified assets', () => {
  const script = join(root, 'tools/verify_native_audio_notices.ps1').replaceAll("'", "''");
  const asset = join(root, manifest.bundle.path).replaceAll("'", "''");
  for (const [mode, count, altered, success] of [
    ['android',1,false,true], ['aNdRoId',0,false,false], ['Android',2,false,false],
    ['Android',1,true,false], ['windows',1,false,true], ['Windows',0,false,false], ['Windows',1,true,false],
  ]) {
    const command = `
      $ErrorActionPreference='Stop'
      $fixture=Join-Path ([IO.Path]::GetTempPath()) ('yymusic-native-notices-'+[guid]::NewGuid())
      [void][IO.Directory]::CreateDirectory($fixture)
      try {
        $body=[IO.File]::ReadAllBytes('${asset}')
        ${altered ? '$body[100]=$body[100] -bxor 1' : ''}
        if ('${mode}' -eq 'Android') {
          $path=Join-Path $fixture 'fixture.apk'
          $zip=[IO.Compression.ZipFile]::Open($path,'Create')
          try { for ($i=0;$i -lt ${count};$i++) {
            $stream=$zip.CreateEntry('assets/flutter_assets/assets/legal/android_audio/notices.json').Open()
            try {$stream.Write($body)} finally {$stream.Dispose()}
          }} finally {$zip.Dispose()}
          & '${script}' -Mode '${mode}' -ApkPath $path
        } else {
          $path=Join-Path $fixture 'data/flutter_assets/assets/legal/android_audio/notices.json'
          [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))
          ${count ? '[IO.File]::WriteAllBytes($path,$body)' : ''}
          & '${script}' -Mode '${mode}' -BundlePath $fixture
        }
      } finally {
        $resolved=[IO.Path]::GetFullPath($fixture)
        $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
        if ([IO.Path]::GetDirectoryName($resolved) -ne $temp -or [IO.Path]::GetFileName($resolved) -notlike 'yymusic-native-notices-*') {throw 'Unsafe fixture cleanup'}
        Remove-Item -LiteralPath $resolved -Recurse -Force
      }
    `;
    const result = spawnSync('pwsh', ['-NoProfile','-NonInteractive','-EncodedCommand',Buffer.from(command,'utf16le').toString('base64')], {
      encoding:'utf8', timeout:30000, windowsHide:true,
    });
    assert.ifError(result.error);
    if (success) assert.equal(result.status,0,result.stdout+result.stderr);
    else assert.notEqual(result.status,0,result.stdout+result.stderr);
  }
});
