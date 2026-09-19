import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import { pathToFileURL } from 'node:url';
import test from 'node:test';
import { root } from './design_audit.mjs';

const vendor = join(root, 'third_party/just_audio_windows');
const read = path => readFileSync(join(vendor, path), 'utf8');
const sha = text => createHash('sha256').update(text).digest('hex');
const patch = '        // YYMusic: publish the real rebased index even if the current item is unchanged.\n        broadcastState();\n';

test('Windows range removal publishes actual state before acknowledgement without restarting', () => {
  const handler = read('windows/player.hpp').split('method_call.method_name().compare("concatenatingRemoveRange")')[1]
    .split('method_call.method_name().compare("concatenatingMove")')[0];
  assert.match(handler, /items\.RemoveAt\(startIndex\);[\s\S]*?broadcastState\(\);\s*return result->Success/);
  assert.equal(handler.split('broadcastState();').length - 1, 1);
  assert.doesNotMatch(handler, /seek|\.Play\(|\.Pause\(|loadSource|CurrentItemIndex\([^)]/);
});

test('local Windows plugin reconstructs all published bytes except the explicit patch and final LF', () => {
  const manifest = JSON.parse(read('upstream.json'));
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.name, 'just_audio_windows');
  assert.equal(manifest.version, '0.2.3');
  assert.equal(manifest.archiveUrl, 'https://pub.dev/api/archives/just_audio_windows-0.2.3.tar.gz');
  assert.equal(manifest.archiveSha256, '7d80dfa02a2189f1c26673a56f4d8584a306d3f22735302be6111e9578a40318');
  assert.equal(manifest.sourceFiles.length, 12);
  for (const source of manifest.sourceFiles) {
    assert.match(source.path, /^[\w./-]+$/);
    assert(!source.path.includes('..'));
    let content = read(source.path);
    if (source.path === 'windows/player.hpp') {
      assert.equal(content.split(patch).length - 1, 1);
      content = content.replace(patch, '');
    }
    assert.equal(source.finalLfAdded, source.path === 'CHANGELOG.md');
    if (source.finalLfAdded) {
      assert(content.endsWith('\n'));
      content = content.slice(0, -1);
    }
    assert.equal(sha(content), source.sha256, source.path);
  }
  const files = readdirSync(vendor, { recursive: true, withFileTypes: true })
    .filter(entry => entry.isFile()).map(entry => relative(vendor, join(entry.parentPath, entry.name)).replaceAll('\\', '/')).sort();
  assert.deepEqual(files, [...manifest.sourceFiles.map(source => source.path), 'UPSTREAM.md', 'upstream.json'].sort());
  assert.match(readFileSync(join(root, 'pubspec.yaml'), 'utf8'), /just_audio_windows:\s*\n\s+path: third_party\/just_audio_windows/);
});

function rootCheck(name, uri, error) {
  const command = `
    $ErrorActionPreference = 'Stop'
    . '${join(root, 'tools/audio_license_audit.ps1').replaceAll("'", "''")}'
    Resolve-YyAudioPackageRoot -Name '${name}' -RootUri '${uri.replaceAll("'", "''")}' -RepositoryRoot '${root.replaceAll("'", "''")}'
  `;
  const result = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  if (error) {
    assert.notEqual(result.status, 0);
    assert.match(result.stderr + result.stdout, error);
  } else {
    assert.equal(result.status, 0, result.stderr);
    assert(result.stdout.trim().length > 0);
  }
}

test('audio source root accepts only the audited relative or absolute local Windows package', () => {
  rootCheck('just_audio_windows', '../third_party/just_audio_windows', null);
  rootCheck('just_audio_windows', pathToFileURL(vendor).href, null);
  rootCheck('just_audio_windows', '../other/just_audio_windows', /audited local fork/);
  rootCheck('just_audio_windows', '../third_party/just_audio_windows-evil', /audited local fork/);
  rootCheck('just_audio_windows', 'https://example.invalid/package', /Invalid local Windows/);
  rootCheck('just_audio_windows', '../third_party/just_audio_windows?secret=fixture', /Invalid local Windows/);
  rootCheck('just_audio_windows', '../third_party/just_audio_windows#fixture', /Invalid local Windows/);
});

test('other locked audio packages still reject relative and remote roots', () => {
  rootCheck('just_audio', '../third_party/just_audio_windows', /local resolved cache/);
  rootCheck('just_audio', 'https://example.invalid/package', /local resolved cache/);
  rootCheck('just_audio', pathToFileURL(vendor).href, null);
});
