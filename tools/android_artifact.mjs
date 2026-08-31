import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { appendFileSync, copyFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repository = 'Z-YO-YI/YYMusic';
const packageName = 'YYMusic-debug.apk';

// This is ordinary build metadata, not a cryptographic provenance attestation.
export function buildMetadata(bytes, environment, checkoutCommit) {
  assert.equal(environment.GITHUB_ACTIONS, 'true', 'APK delivery must run in GitHub Actions');
  assert.equal(environment.GITHUB_REPOSITORY, repository, 'Unexpected repository');
  assert.equal(environment.GITHUB_SERVER_URL, 'https://github.com', 'Unexpected server');
  assert.match(environment.GITHUB_SHA ?? '', /^[a-f0-9]{40}$/, 'Invalid commit');
  assert.equal(checkoutCommit, environment.GITHUB_SHA, 'Checkout does not match this workflow run');
  assert.match(environment.GITHUB_RUN_ID ?? '', /^[1-9][0-9]*$/, 'Invalid run ID');
  assert.match(environment.GITHUB_RUN_ATTEMPT ?? '', /^[1-9][0-9]*$/, 'Invalid attempt');
  assert.match(environment.FLUTTER_VERSION ?? '', /^\d+\.\d+\.\d+$/, 'Invalid Flutter version');
  assert(bytes.length > 0, 'Empty APK');
  return {
    schemaVersion: 1,
    repository,
    commit: checkoutCommit,
    runUrl: `https://github.com/${repository}/actions/runs/${environment.GITHUB_RUN_ID}`,
    attempt: environment.GITHUB_RUN_ATTEMPT,
    flutterVersion: environment.FLUTTER_VERSION,
    buildType: 'debug',
    signing: 'ephemeral-runner-debug-key',
    apk: { name: packageName, bytes: bytes.length, sha256: createHash('sha256').update(bytes).digest('hex') },
  };
}

export function draftReleaseSummary(metadata, releaseTag) {
  const runId = metadata.runUrl.split('/').at(-1);
  assert.equal(releaseTag, `ci-debug-${runId}-${metadata.attempt}`, 'Draft Release belongs to another run');
  const releaseUrl = `https://github.com/${repository}/releases/tag/${releaseTag}`;
  return [
    '## YYMusic Android Debug APK', '',
    `[Download APK, SHA256SUMS and build metadata from the private draft Release](${releaseUrl})`, '',
    `Draft Release tag: \`${releaseTag}\``, '',
    `Commit: \`${metadata.commit}\``, '',
    `APK SHA-256: \`${metadata.apk.sha256}\``, '',
    'Built and verified on GitHub Actions; this is not a locally uploaded APK.', '',
    'Debug only. The Release remains a draft; GitHub sign-in and repository access are required.', '',
    'The runner debug signing key can change between runs. This is not a stable release/update signing identity.', '',
  ].join('\n');
}

function main() {
  // Refuse local packaging before touching any files or reading repository state.
  assert.equal(process.env.GITHUB_ACTIONS, 'true', 'Run APK delivery in GitHub Actions, not locally');
  const root = fileURLToPath(new URL('../', import.meta.url));
  const source = resolve(root, 'build/app/outputs/flutter-apk/app-debug.apk');
  const output = resolve(root, 'build/ci/android-debug');
  const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
  const metadata = buildMetadata(readFileSync(source), process.env, commit);
  if (process.argv[2] === '--summary') {
    assert(process.env.GITHUB_STEP_SUMMARY, 'Missing GitHub summary file');
    appendFileSync(process.env.GITHUB_STEP_SUMMARY, draftReleaseSummary(metadata, process.env.YY_APK_RELEASE_TAG));
    return;
  }
  assert.equal(process.argv.length, 2, 'Unexpected arguments');
  mkdirSync(output, { recursive: true });
  copyFileSync(source, resolve(output, packageName));
  writeFileSync(resolve(output, 'SHA256SUMS'), `${metadata.apk.sha256}  ${packageName}\n`);
  writeFileSync(resolve(output, 'build-metadata.json'), `${JSON.stringify(metadata, null, 2)}\n`);
  console.log(`Packaged ${packageName} for ${metadata.commit}; SHA-256 ${metadata.apk.sha256}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
