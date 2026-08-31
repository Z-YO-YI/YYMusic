import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('bundled font bytes and licenses match the pinned Google Fonts commit', () => {
  const manifest = JSON.parse(read('assets/fonts/manifest.json'));
  assert.equal(manifest.sourceRepository, 'https://github.com/google/fonts');
  assert.equal(manifest.sourceCommit, 'ade3d1533e06b2b1462ffcde8e08b129627ca360');
  assert.equal(manifest.files.length, 4);
  for (const file of manifest.files) {
    const bytes = readFileSync(file.path);
    assert.equal(bytes.length, file.bytes, file.path);
    assert.equal(createHash('sha256').update(bytes).digest('hex'), file.sha256, file.path);
  }
  for (const path of ['assets/fonts/inter/OFL.txt', 'assets/fonts/noto_sans_sc/OFL.txt']) {
    assert.match(read(path), /SIL OPEN FONT LICENSE Version 1.1/);
    assert.match(read(path), /Copyright/);
  }
});

test('Flutter glyph enum covers each original SVG exactly once', () => {
  const glyphSource = read('lib/design_system/yy_icon.dart').split('const YYGlyph')[0];
  const names = [...glyphSource.matchAll(/\w+\('([^']+)',/g)].map(match => match[1]).sort();
  const files = walk('assets/icons/yymusic').map(path => path.split('/').pop().replace('.svg', '')).sort();
  assert.equal(names.length, 44);
  assert.deepEqual(names, files);
});

test('Git preserves exact bytes for fonts, upstream licenses and PNG goldens', () => {
  const files = JSON.parse(read('assets/fonts/manifest.json')).files.map(file => file.path);
  const goldens = walk('test/golden/baselines').filter(path => path.endsWith('.png'));
  for (const original of ['components_dark_390_130.png', 'components_light_390_130.png', 'icon_atlas_800.png']) {
    assert(goldens.some(path => path.endsWith(`/${original}`)), original);
  }
  assert(goldens.length >= 8, 'Phase2B adds five baselines without dropping the original three');
  files.push(...goldens);
  const attributes = execFileSync('git', ['check-attr', 'text', '--', ...files], { encoding: 'utf8' }).trim().split(/\r?\n/);
  assert.equal(attributes.length, files.length);
  assert(attributes.every(line => line.endsWith(': text: unset')), attributes.join('\n'));
});

test('native design UI has no storage, network, platform or playback side effects', () => {
  const files = [...walk('lib/design_system'), ...walk('lib/features/design_gallery')];
  for (const path of files.filter(path => path.endsWith('.dart'))) {
    assert(!/dart:io|package:(http|dio|shared_preferences|path_provider)|MethodChannel|\.play\(|\.seek\(/.test(read(path)), path);
  }
});
