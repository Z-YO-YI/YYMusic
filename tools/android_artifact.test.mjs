import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import test from 'node:test';
import { artifactSummary, buildMetadata } from './android_artifact.mjs';

const commit = 'a'.repeat(40);
const environment = {
  GITHUB_ACTIONS: 'true', GITHUB_REPOSITORY: 'Z-YO-YI/YYMusic',
  GITHUB_SERVER_URL: 'https://github.com', GITHUB_SHA: commit,
  GITHUB_RUN_ID: '123', GITHUB_RUN_ATTEMPT: '2', FLUTTER_VERSION: '3.47.2',
};
const bytes = Buffer.from('abc'); // Pure metadata fixture; never an uploaded APK.

test('APK metadata records only the exact checkout, run and checksum', () => {
  const result = buildMetadata(bytes, { ...environment, SECRET_DO_NOT_COPY: 'fixture-only' }, commit);
  assert.equal(result.apk.sha256, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  assert.equal(result.apk.bytes, 3);
  assert.equal(result.commit, commit);
  assert.equal(result.runUrl, 'https://github.com/Z-YO-YI/YYMusic/actions/runs/123');
  assert.equal(result.buildType, 'debug');
  assert.equal(result.signing, 'ephemeral-runner-debug-key');
  assert(!JSON.stringify(result).includes('fixture-only'));
});

test('APK metadata refuses local, mismatched or malformed run identities', () => {
  for (const patch of [
    { GITHUB_ACTIONS: 'false' }, { GITHUB_REPOSITORY: 'someone/else' },
    { GITHUB_SERVER_URL: 'https://example.com' }, { GITHUB_SHA: 'short' },
    { GITHUB_RUN_ID: '../123' }, { GITHUB_RUN_ATTEMPT: '0' }, { FLUTTER_VERSION: '' },
  ]) assert.throws(() => buildMetadata(bytes, { ...environment, ...patch }, commit));
  assert.throws(() => buildMetadata(bytes, environment, 'b'.repeat(40)));
  assert.throws(() => buildMetadata(Buffer.alloc(0), environment, commit));
});

test('artifact summary links only this run and clearly identifies debug signing', () => {
  const metadata = buildMetadata(bytes, environment, commit);
  const url = `${metadata.runUrl}/artifacts/456`;
  const summary = artifactSummary(metadata, url);
  assert(summary.includes(url));
  assert(summary.includes('debug signing key can change'));
  for (const invalid of ['', `${url}\n# untrusted`, url.replace('/123/', '/999/'), 'https://example.com']) {
    assert.throws(() => artifactSummary(metadata, invalid));
  }
});

test('the CLI refuses local packaging before copying any APK', () => {
  assert.throws(
    () => execFileSync(process.execPath, ['tools/android_artifact.mjs'], {
      env: { ...process.env, GITHUB_ACTIONS: 'false' }, stdio: 'pipe',
    }),
    error => error.status !== 0 && error.stderr.toString().includes('not locally'),
  );
});
