import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const sha256Pattern = /^[a-f0-9]{64}$/;

function read(root, relativePath) {
  return readFileSync(path.join(root, relativePath), 'utf8');
}

function collectHashes(value, location = 'manifest', result = []) {
  if (Array.isArray(value)) {
    value.forEach((item, index) => collectHashes(item, `${location}[${index}]`, result));
    return result;
  }
  if (value && typeof value === 'object') {
    for (const [key, child] of Object.entries(value)) {
      if (/sha256$/i.test(key)) result.push({ location: `${location}.${key}`, value: child });
      collectHashes(child, `${location}.${key}`, result);
    }
  }
  return result;
}

function nativeEntryMap(releaseArtifacts) {
  return new Map(
    releaseArtifacts.flatMap(artifact =>
      artifact.nativeEntries.map(entry => [entry.path, entry]),
    ),
  );
}

export function auditMediaKitRedistribution({
  root = process.cwd(),
  manifest = JSON.parse(read(root, 'docs/legal/media_kit/manifest.json')),
} = {}) {
  const errors = [];
  const check = (condition, message) => {
    if (!condition) errors.push(message);
  };

  check(manifest.schemaVersion === 1, 'manifest schemaVersion must be 1');
  check(manifest.status === 'blocked', 'Phase 4G must remain blocked until this audit is deliberately revised');
  check(manifest.releaseApproved === false, 'media_kit native release must not be approved');
  check(manifest.productionWiringApproved === false, 'media_kit production wiring must not be approved');
  check(manifest.scope?.distributionMode === 'inventory-only', 'manifest must remain inventory-only');
  check(manifest.scope?.legalAdvice === false, 'manifest must not present itself as legal advice');
  check(Array.isArray(manifest.blockers) && manifest.blockers.length >= 5, 'global blocker list is incomplete');
  check(
    Array.isArray(manifest.requiredBeforeRelease) && manifest.requiredBeforeRelease.length >= 5,
    'release prerequisites are incomplete',
  );

  for (const { location, value } of collectHashes(manifest)) {
    check(typeof value === 'string' && sha256Pattern.test(value), `${location} is not a lowercase SHA-256`);
  }

  const expectedPackages = new Map([
    ['media_kit', '1.2.6'],
    ['media_kit_libs_audio', '1.0.7'],
    ['media_kit_libs_android_audio', '1.3.8'],
    ['media_kit_libs_windows_audio', '1.0.9'],
  ]);
  check(manifest.dartPackages?.length === expectedPackages.size, 'audited Dart package set changed');
  for (const pkg of manifest.dartPackages ?? []) {
    check(expectedPackages.get(pkg.name) === pkg.version, `${pkg.name} version is not the audited lockfile version`);
    check(pkg.licenseExpression === 'MIT', `${pkg.name} wrapper license must be recorded separately as MIT`);
  }

  const lockfile = read(root, 'pubspec.lock');
  for (const [name, version] of expectedPackages) {
    check(
      new RegExp(`^  ${name}:[\\s\\S]*?^    version: "${version.replaceAll('.', '\\.')}"$`, 'm').test(lockfile),
      `${name} ${version} is not locked`,
    );
  }
  const pubspec = read(root, 'pubspec.yaml');
  check(/^  media_kit: 1\.2\.6$/m.test(pubspec), 'media_kit direct version changed');
  check(/^  media_kit_libs_audio: 1\.0\.7$/m.test(pubspec), 'media_kit_libs_audio direct version changed');
  check(!/assets\/legal\/media_kit|docs\/legal\/media_kit/.test(pubspec), 'blocked legal inventory must not be bundled');
  check(!existsSync(path.join(root, 'assets/legal/media_kit')), 'blocked app legal asset directory must not exist');

  const graph = read(root, 'lib/app/dependency_graph.dart');
  check(/_audioEngine = audioEngine \?\? UnavailableAudioEngine\(\)/.test(graph), 'production audio fallback is not unavailable');
  for (const entrypoint of ['lib/main.dart', 'lib/app/app_bootstrap.dart']) {
    const source = read(root, entrypoint);
    check(!/MediaKit|MediaKitAudioEngine|NativeMediaKitPlayerBackend/.test(source), `${entrypoint} wires media_kit into production`);
  }

  const android = manifest.native?.android;
  check(android?.mappingStatus === 'partial', 'Android source mapping must remain partial');
  check(android?.release?.commit === '87744be8b337c50ed54961249b7a97c5e8cc37c9', 'Android build commit changed');
  check(android?.releaseArtifacts?.length === 4, 'Android release must cover exactly four JARs');
  check(android?.blockers?.length >= 3, 'Android blocker list is incomplete');
  check(android?.embeddedConfiguration?.gpl === false, 'Android embedded FFmpeg GPL flag is not false');
  check(android?.embeddedConfiguration?.nonfree === false, 'Android embedded FFmpeg nonfree flag is not false');
  check(android?.embeddedConfiguration?.version3 === true, 'Android embedded FFmpeg version3 flag is not true');

  const androidReleaseEntries = nativeEntryMap(android?.releaseArtifacts ?? []);
  const bundledEntries = android?.verifiedApplicationArtifact?.nativeEntries ?? [];
  check(bundledEntries.length === 6, 'Android APK native evidence must cover two libraries for three ABIs');
  check(
    JSON.stringify([...new Set(bundledEntries.map(entry => entry.path.split('/')[1]))].sort()) ===
      JSON.stringify(['arm64-v8a', 'armeabi-v7a', 'x86_64']),
    'Android APK ABI evidence changed',
  );
  for (const entry of bundledEntries) {
    const releaseEntry = androidReleaseEntries.get(entry.path);
    check(Boolean(releaseEntry), `${entry.path} is not present in the audited release JARs`);
    check(releaseEntry?.size === entry.size, `${entry.path} size differs from its release JAR`);
    check(releaseEntry?.sha256 === entry.sha256, `${entry.path} hash differs from its release JAR`);
  }

  const windows = manifest.native?.windows;
  check(windows?.mappingStatus === 'blocked', 'Windows source mapping must remain blocked');
  check(windows?.blockers?.length >= 4, 'Windows blocker list is incomplete');
  check(windows?.releaseArchive?.entries?.length === 6, 'Windows archive inventory changed');
  check(windows?.verifiedBinary?.matchesPhase4cWindowsDebugArtifact === true, 'Windows DLL match evidence is missing');
  check(windows?.embeddedConfiguration?.gpl === false, 'Windows embedded FFmpeg GPL flag is not false');
  check(windows?.embeddedConfiguration?.nonfree === false, 'Windows embedded FFmpeg nonfree flag is not false');
  check(windows?.embeddedConfiguration?.mpvGplOption === false, 'Windows embedded mpv GPL option is not false');
  check(windows?.embeddedConfiguration?.preferStatic === true, 'Windows static-link preference evidence is missing');
  check(
    /enables GPL and nonfree while the binary disables both/.test(windows?.rejectedSourceMapping?.reason ?? ''),
    'Windows historical source mismatch is not recorded',
  );

  return { ok: errors.length === 0, errors, status: manifest.status };
}

const currentFile = fileURLToPath(import.meta.url);
if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === pathToFileURL(currentFile).href) {
  const result = auditMediaKitRedistribution();
  assert.deepEqual(result.errors, [], result.errors.join('\n'));
  console.log('media_kit redistribution gate: blocked (fail-closed evidence verified)');
}
