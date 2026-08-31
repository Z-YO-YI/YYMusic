import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { appendFileSync, copyFileSync, cpSync, mkdirSync, mkdtempSync, realpathSync, rmSync, unlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join } from 'node:path';
import test from 'node:test';
import { root } from './design_audit.mjs';

function fixture(t) {
  const temporaryParent = realpathSync(tmpdir());
  const directory = mkdtempSync(join(temporaryParent, 'yymusic-reference-'));
  t.after(() => {
    // Remove only this test's resolved, uniquely named temporary directory.
    const target = realpathSync(directory);
    assert.equal(dirname(target), temporaryParent);
    assert(basename(target).startsWith('yymusic-reference-'));
    rmSync(target, { recursive: true, force: true });
  });
  mkdirSync(join(directory, 'tools'));
  mkdirSync(join(directory, 'design_reference'));
  copyFileSync(join(root, 'tools/verify_reference_archive.ps1'), join(directory, 'tools/verify_reference_archive.ps1'));
  copyFileSync(join(root, 'design_reference/YYMusic_HTML.zip'), join(directory, 'design_reference/YYMusic_HTML.zip'));
  cpSync(join(root, 'design_reference/figma_export'), join(directory, 'design_reference/figma_export'), { recursive: true });
  return directory;
}

function verify(directory) {
  const quotedRoot = directory.replaceAll("'", "''");
  const command = `
    $ErrorActionPreference = 'Stop'
    $caseRoot = '${quotedRoot}'
    if ($IsWindows) {
      # Unix dotfiles are hidden automatically; simulate that on Windows too.
      Get-ChildItem -LiteralPath (Join-Path $caseRoot 'design_reference/figma_export') -File -Recurse -Force |
        Where-Object { $_.Name.StartsWith('.') } |
        ForEach-Object { $_.Attributes = $_.Attributes -bor [IO.FileAttributes]::Hidden }
    }
    & (Join-Path $caseRoot 'tools/verify_reference_archive.ps1')
  `;
  const result = spawnSync('pwsh', ['-NoLogo', '-NoProfile', '-NonInteractive', '-OutputFormat', 'Text', '-EncodedCommand', Buffer.from(command, 'utf16le').toString('base64')], {
    encoding: 'utf8', timeout: 30000, windowsHide: true,
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null);
  return { status: result.status, output: result.stdout + result.stderr };
}

test('archive verifier includes all 24 original files, including hidden dotfiles', t => {
  const result = verify(fixture(t));
  assert.equal(result.status, 0, result.output);
  assert.match(result.output, /PASS: all 24 extracted files match/);
});

test('archive verifier rejects altered hidden-file bytes', t => {
  const directory = fixture(t);
  appendFileSync(join(directory, 'design_reference/figma_export/.gitattributes'), '\n');
  const result = verify(directory);
  assert.notEqual(result.status, 0);
  assert.match(result.output, /Extracted reference differs from ZIP bytes:.*\.gitattributes/);
});

test('archive verifier rejects a missing hidden reference file', t => {
  const directory = fixture(t);
  unlinkSync(join(directory, 'design_reference/figma_export/.gitattributes'));
  const result = verify(directory);
  assert.notEqual(result.status, 0);
  assert.match(result.output, /Missing extracted reference:.*\.gitattributes/);
});

test('archive verifier rejects extra hidden files rather than ignoring them', t => {
  const directory = fixture(t);
  writeFileSync(join(directory, 'design_reference/figma_export/.unexpected-reference'), 'test fixture only');
  const result = verify(directory);
  assert.notEqual(result.status, 0);
  assert.match(result.output, /Unexpected file count: ZIP=24, extracted=25, expected=24/);
});

test('archive verifier rejects a changed ZIP before comparing extracted files', t => {
  const directory = fixture(t);
  appendFileSync(join(directory, 'design_reference/YYMusic_HTML.zip'), 'test mutation');
  const result = verify(directory);
  assert.notEqual(result.status, 0);
  assert.match(result.output, /Archive fingerprint differs from the audited source/);
});
