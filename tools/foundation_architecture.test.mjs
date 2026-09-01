import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

const sources = walk('lib').filter(path => path.endsWith('.dart'));

test('formal source does not embed WebViews, fixture catalogs or source archives', () => {
  for (const path of sources) {
    assert(!/WebView|InAppWebView|dart:html|SonicGallery|sonic_gallery|LinearGradient|RadialGradient|SweepGradient/.test(read(path)), path);
    assert(!/import\s+['"][^'"]*(design_reference|archive)\//.test(read(path)), path);
  }
  const pubspec = read('pubspec.yaml');
  assert.match(pubspec, /uses-material-design: false/);
  const bundled = [...pubspec.matchAll(/^\s+-\s+(?:asset:\s+)?(assets\/[^\s]+)\s*$/gm)].map(match => match[1]);
  assert.deepEqual(bundled, [
    'assets/icons/yymusic/',
    'assets/fonts/inter/OFL.txt',
    'assets/fonts/noto_sans_sc/OFL.txt',
    'assets/fonts/inter/InterVariable.ttf',
    'assets/fonts/noto_sans_sc/NotoSansSCVariable.ttf',
  ], 'Only audited icons, pinned fonts and licenses may be bundled');
  for (const path of sources) {
    assert(!/package:flutter\/material.dart|SvgPicture\.network|GoogleFonts\./.test(read(path)), path);
  }
});

test('routing and injection packages remain inside the app composition boundary', () => {
  for (const path of sources.filter(path => !path.startsWith('lib/app/'))) {
    assert(!/package:(go_router|flutter_riverpod)\//.test(read(path)), path);
  }
  for (const path of sources.filter(path => path.startsWith('lib/shells/'))) {
    assert(!/DependencyGraph\(|PlaybackController\(|QueueController\(|dart:io|package:dio/.test(read(path)), path);
  }
});

test('domain contracts stay independent and UI has no direct data access', () => {
  const domainSources = sources.filter(path => path.startsWith('lib/domain/'));
  assert(domainSources.length >= 10, 'Phase 3A domain contracts are missing');
  for (const path of domainSources) {
    assert(!/package:flutter|dart:io|package:(drift|sqlite|sqflite|dio|http)\//.test(read(path)), path);
    assert(!/import\s+['"][^'"]*\/(app|data|platform|playback|shells|features)\//.test(read(path)), path);
  }
  const uiSources = sources.filter(path => /lib\/(design_system|features|shells)\//.test(path));
  for (const path of uiSources) {
    assert(!/package:(drift|sqlite|sqflite|dio|http)\/|import\s+['"][^'"]*\/data\//.test(read(path)), path);
  }
  for (const path of sources.filter(path => !path.startsWith('lib/data/'))) {
    assert(!/package:(drift|sqlite3|path_provider)\//.test(read(path)), path);
  }
  for (const path of sources.filter(path => path.startsWith('lib/data/'))) {
    assert(!/import\s+['"][^'"]*\/(app|design_system|features|playback|shells)\//.test(read(path)), path);
  }

  const pubspec = read('pubspec.yaml');
  assert.match(pubspec, /^  drift: \^2\.34\.3$/m);
  assert.match(pubspec, /^  sqlite3: \^3\.5\.2$/m);
  assert.match(pubspec, /^  path_provider: \^2\.1\.6$/m);
  assert.match(pubspec, /^  drift_dev: \^2\.34\.5$/m);
  assert(!/drift_flutter|sqlite3_flutter_libs|sqflite/.test(pubspec));

  const snapshot = JSON.parse(read('drift_schemas/yymusic/drift_schema_v1.json'));
  const tableNames = snapshot.entities
    .filter(entity => entity.type === 'table')
    .map(entity => entity.data.name)
    .sort();
  assert.deepEqual(tableNames, [
    'album_artists', 'albums', 'app_settings', 'artists', 'favorites',
    'local_folders', 'lyrics_cache', 'music_sources', 'play_history',
    'playlist_entries', 'playlists', 'queue_entries', 'queue_state',
    'schema_migrations', 'search_history', 'track_artists', 'tracks',
  ]);
});

test('native runners are branded and Android release does not use debug signing', () => {
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:label="YYMusic"/);
  assert.match(read('windows/runner/main.cpp'), /window\.Create\(L"YYMusic"/);
  assert(!read('android/app/build.gradle.kts').includes('signingConfigs.getByName("debug")'));
});

test('CI validates both debug targets with least-privileged, pinned actions', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /contents: read/);
  assert.match(workflow, /flutter build windows --debug --no-pub/);
  assert.match(workflow, /flutter build apk --debug --no-pub/);
  assert.match(workflow, /dart run build_runner build/);
  assert.match(workflow, /dart run drift_dev make-migrations/);
  assert.match(workflow, /git diff --exit-code -- lib\/data\/database\/app_database\.g\.dart drift_schemas\//);
  const actions = [...workflow.matchAll(/uses: (\S+)/g)].map(match => match[1]);
  assert(actions.length >= 4);
  assert(actions.every(action => /@[a-f0-9]{40}$/.test(action)));
  assert(!/pull_request_target|secrets\./.test(workflow));
  assert.equal(workflow.match(/contents: write/g)?.length, 1);
  const android = workflow.slice(workflow.indexOf('\n  android-debug:'));
  assert.match(android, /permissions:\s+contents: write/);
  assert.match(android, /if: github\.event_name == 'workflow_dispatch'/);
  assert.match(android, /GH_TOKEN: \$\{\{ github\.token \}\}/);
});
