import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { root } from './design_audit.mjs';

const hash = value => createHash('sha256').update(value).digest('hex');
const digest = /^[0-9a-f]{64}$/;
const coordinate = /^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+$/;
const fail = message => { throw new Error(message); };
function check(value, message) { if (!value) fail(message); }
function fingerprint(value) {
  check(digest.test(value.sha256) && Number.isInteger(value.bytes) && value.bytes > 0, 'Invalid native fingerprint');
}

/** Validate only the audited Media3 closure, not an application-wide release. */
export function validateNativeNotices(bytes, manifest) {
  check(bytes.length > 0 && bytes.length <= 2 * 1024 * 1024, 'Native notice size limit');
  check(manifest.schemaVersion === 1 && manifest.scope === 'resolved-android-media3-audio-closure', 'Unexpected native scope');
  check(manifest.releaseApproved === false, 'Native materials must not approve application release');
  check(bytes.length === manifest.bundle.bytes && hash(bytes) === manifest.bundle.sha256, 'Native bundle fingerprint mismatch');
  const bundle = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
  check(bundle.schemaVersion === 1 && bundle.scope === manifest.scope, 'Unexpected bundle scope');
  const components = bundle.components;
  check(Array.isArray(components) && components.length === manifest.coordinates.length, 'Native coordinate count mismatch');
  assert.deepEqual(components.map(c => c.coordinate), manifest.coordinates, 'Native coordinate set mismatch');
  check(new Set(manifest.coordinates).size === components.length && components.every(c => coordinate.test(c.coordinate)), 'Invalid or duplicate native coordinate');
  assert.deepEqual(Object.keys(manifest.variantExcludedCoordinates).sort(), ['debug', 'profile', 'release'], 'Missing explicit native variants');
  for (const excluded of Object.values(manifest.variantExcludedCoordinates)) {
    check(Array.isArray(excluded) && new Set(excluded).size === excluded.length && excluded.every(c => manifest.coordinates.includes(c)), 'Invalid native variant exclusions');
  }
  const documents = new Map();
  check(Array.isArray(bundle.documents) && bundle.documents.length > 0 && bundle.documents.length <= 200, 'Invalid native documents');
  for (const document of bundle.documents) {
    fingerprint(document);
    check(typeof document.text === 'string' && Buffer.byteLength(document.text) === document.bytes && hash(document.text) === document.sha256, 'Native document fingerprint mismatch');
    check(!documents.has(document.sha256), 'Duplicate native document');
    documents.set(document.sha256, document);
  }
  const usedDocuments = new Set();
  for (const component of components) {
    check(Array.isArray(component.poms) && component.poms.length > 0 && component.poms.length <= 9, 'Missing native POM provenance');
    check(component.poms[0].coordinate === component.coordinate, 'Native POM identity mismatch');
    for (const pom of component.poms) { fingerprint(pom); check(coordinate.test(pom.coordinate), 'Invalid parent POM'); }
    check(component.declaredLicenses.length > 0 && component.licenseDocuments.length > 0, 'Missing complete native license');
    const use = sha => { check(documents.has(sha), 'Missing referenced native document'); usedDocuments.add(sha); };
    component.licenseDocuments.forEach(use);
    const filenames = new Set();
    for (const artifact of component.artifacts) {
      fingerprint(artifact);
      check(typeof artifact.name === 'string' && /^[A-Za-z0-9_.-]+\.(jar|aar)$/.test(artifact.name) && !filenames.has(artifact.name), 'Invalid or duplicate native artifact');
      filenames.add(artifact.name);
      for (const notice of artifact.notices) {
        check(typeof notice.path === 'string' && !notice.path.includes('..') && !notice.path.startsWith('/'), 'Invalid embedded notice path');
        use(notice.document);
      }
      check(!('path' in artifact), 'Private cache path in native bundle');
    }
  }
  check(usedDocuments.size === documents.size, 'Unreferenced native legal document');
  return bundle;
}

/** Compare source/build identity without persisting developer cache paths. */
export function validateNativeInventory(inventory, bundle, manifest) {
  check(inventory.schemaVersion === 1 && ['debug', 'profile', 'release'].includes(inventory.variant), 'Invalid resolved native inventory');
  const snapshot = components => components.map(component => ({
    coordinate: component.coordinate,
    artifacts: component.artifacts.map(({ name, bytes, sha256 }) => ({ name, bytes, sha256 })),
  }));
  const excluded = manifest.variantExcludedCoordinates[inventory.variant];
  check(Array.isArray(excluded), 'Missing audited native variant');
  const required = bundle.components.filter(c => !excluded.includes(c.coordinate));
  check(JSON.stringify(snapshot(inventory.components)) === JSON.stringify(snapshot(required)), 'Resolved native artifacts or versions differ from reviewed materials');
}

export function auditNativeNotices() {
  const manifest = JSON.parse(readFileSync(join(root, 'docs/legal/just_audio/native_manifest.json'), 'utf8'));
  return validateNativeNotices(readFileSync(join(root, manifest.bundle.path)), manifest);
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  const bundle = auditNativeNotices();
  if (process.argv[2]) {
    const manifest = JSON.parse(readFileSync(join(root, 'docs/legal/just_audio/native_manifest.json'), 'utf8'));
    validateNativeInventory(JSON.parse(readFileSync(process.argv[2], 'utf8')), bundle, manifest);
  }
  process.stdout.write(`PASS: ${bundle.components.length} native audio coordinates and ${bundle.documents.length} complete legal texts verified.\n`);
}
