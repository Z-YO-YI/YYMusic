import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { auditMediaKitRedistribution } from './media_kit_redistribution_audit.mjs';

const manifestPath = 'docs/legal/media_kit/manifest.json';
const loadManifest = () => JSON.parse(readFileSync(manifestPath, 'utf8'));

test('media_kit redistribution evidence is complete and fail-closed', () => {
  const result = auditMediaKitRedistribution();
  assert.equal(result.ok, true, result.errors.join('\n'));
  assert.equal(result.status, 'blocked');
});

test('media_kit redistribution audit rejects an unreviewed approval flip', () => {
  const manifest = loadManifest();
  manifest.status = 'approved';
  manifest.releaseApproved = true;
  manifest.productionWiringApproved = true;
  const result = auditMediaKitRedistribution({ manifest });
  assert.equal(result.ok, false);
  assert(result.errors.some(error => error.includes('must remain blocked')));
  assert(result.errors.some(error => error.includes('must not be approved')));
});

test('media_kit redistribution audit rejects missing blocker evidence', () => {
  const manifest = loadManifest();
  manifest.blockers = [];
  manifest.native.android.blockers = [];
  manifest.native.windows.blockers = [];
  const result = auditMediaKitRedistribution({ manifest });
  assert.equal(result.ok, false);
  assert(result.errors.some(error => error.includes('global blocker list')));
  assert(result.errors.some(error => error.includes('Android blocker list')));
  assert(result.errors.some(error => error.includes('Windows blocker list')));
});

test('media_kit redistribution audit rejects an APK-to-JAR native mismatch', () => {
  const manifest = loadManifest();
  manifest.native.android.verifiedApplicationArtifact.nativeEntries[0].sha256 = '0'.repeat(64);
  const result = auditMediaKitRedistribution({ manifest });
  assert.equal(result.ok, false);
  assert(result.errors.some(error => error.includes('hash differs from its release JAR')));
});
