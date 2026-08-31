import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';
import { root, walk } from './design_audit.mjs';

test('all 13 archived legacy files match their pre-migration bytes', () => {
  const base = 'archive/sonic_gallery';
  const manifest = JSON.parse(readFileSync(join(root, base, 'manifest.json'), 'utf8'));
  assert.equal(manifest.length, 13);
  for (const entry of manifest) {
    const bytes = readFileSync(join(root, base, entry.path));
    assert.equal(bytes.length, entry.bytes, entry.path);
    assert.equal(createHash('sha256').update(bytes).digest('hex'), entry.sha256, entry.path);
  }
  assert.deepEqual(walk(base).sort(), [...manifest.map(entry => `${base}/${entry.path}`), `${base}/manifest.json`, `${base}/README.md`].sort());
});
