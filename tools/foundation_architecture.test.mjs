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
  for (const path of sources) {
    assert(!/package:drift_dev\//.test(read(path)), `${path} must not import dev-only migration APIs`);
  }

  const pubspec = read('pubspec.yaml');
  assert.match(pubspec, /^  crypto: \^3\.0\.7$/m);
  assert.match(pubspec, /^  drift: \^2\.34\.3$/m);
  assert.match(pubspec, /^  flutter_secure_storage: \^10\.3\.1$/m);
  assert.match(pubspec, /^  sqlite3: \^3\.5\.2$/m);
  assert.match(pubspec, /^  path_provider: \^2\.1\.6$/m);
  assert.match(pubspec, /^  drift_dev: \^2\.34\.5$/m);
  assert(!/drift_flutter|sqlite3_flutter_libs|sqflite/.test(pubspec));

  const credentialSources = sources.filter(path => path.startsWith('lib/platform/secure_credentials/'));
  assert.equal(credentialSources.length, 4, 'Phase 3G secure credential implementation set changed');
  for (const path of sources.filter(path => !path.startsWith('lib/platform/secure_credentials/'))) {
    assert(!/package:flutter_secure_storage\//.test(read(path)), `${path} bypasses the secure credential boundary`);
  }
  for (const path of credentialSources) {
    assert(!/package:(drift|sqlite3|dio|http)\/|dart:io|dart:developer|debugPrint|print\(/.test(read(path)), path);
  }
  const credentialCore = read('lib/platform/secure_credentials/secure_storage_credential_gateway.dart');
  assert.match(credentialCore, /implements SecureCredentialGateway/);
  assert.match(credentialCore, /Random\.secure\(\)/);
  assert.match(credentialCore, /schemaVersion/);
  assert.match(read('lib/platform/contracts/secure_credential_gateway.dart'), /details: <redacted>/);
  const androidCredential = read('lib/platform/secure_credentials/android_secure_credential_gateway.dart');
  assert.match(androidCredential, /final class AndroidSecureCredentialGateway/);
  assert.match(androidCredential, /resetOnError: false/);
  assert.match(androidCredential, /migrateWithBackup: true/);
  assert.match(androidCredential, /storageNamespace: 'yymusic_credentials_v1'/);
  const windowsCredential = read('lib/platform/secure_credentials/windows_secure_credential_gateway.dart');
  assert.match(windowsCredential, /final class WindowsSecureCredentialGateway/);
  assert.match(windowsCredential, /WindowsOptions\(useBackwardCompatibility: false\)/);

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

  const repository = read('lib/data/repositories/drift_library_repository.dart');
  assert.match(repository, /implements LibraryRepository/);
  assert.match(repository, /transaction\(\(\) async/);
  assert.match(repository, /insertAllOnConflictUpdate/);
  assert.match(repository, /limit\(request\.limit \+ 1, offset: request\.offset\)/);
  assert(!/CollectionRepository|MusicSourceRepository|SecureCredentialGateway|package:flutter/.test(repository));
  const collectionRepository = read('lib/data/repositories/drift_collection_repository.dart');
  assert.match(collectionRepository, /implements CollectionRepository/);
  assert.match(collectionRepository, /transaction\(\(\) async/g);
  assert.match(collectionRepository, /readsFrom: \{_database\.queueStateRecords, _database\.queueEntryRecords\}/);
  assert.match(collectionRepository, /\.skip\(20\)/);
  assert.match(collectionRepository, /\.limit\(20\)/);
  assert(!/LyricsRepository|MusicSourceRepository|SecureCredentialGateway|package:flutter/.test(collectionRepository));
  const lyricsRepository = read('lib/data/repositories/drift_lyrics_repository.dart');
  assert.match(lyricsRepository, /implements LyricsRepository/);
  assert.match(lyricsRepository, /insertOnConflictUpdate/);
  assert.match(lyricsRepository, /trackSourceType\.equals\(track\.sourceType\.name\)/);
  assert(!/LibraryRepository|CollectionRepository|MusicSourceRepository|SecureCredentialGateway|package:flutter/.test(lyricsRepository));
  const lyricsMapper = read('lib/data/repositories/lyrics_row_mapper.dart');
  assert.match(lyricsMapper, /jsonEncode/);
  assert.match(lyricsMapper, /jsonDecode/);
  assert.match(lyricsMapper, /value\.length != 4/);
  assert(!/dart:io|package:flutter|MusicSourceRepository|SecureCredentialGateway/.test(lyricsMapper));
  const sourceRepository = read('lib/data/repositories/drift_music_source_repository.dart');
  assert.match(sourceRepository, /implements MusicSourceRepository/);
  assert.match(sourceRepository, /transaction\(\(\) async/g);
  assert.match(sourceRepository, /insertOnConflictUpdate/);
  assert.match(sourceRepository, /built-in-delete/);
  assert(!/SensitiveCredential|SecureCredentialGateway|package:(dio|http)|dart:io|package:flutter/.test(sourceRepository));
  const sourceMapper = read('lib/data/repositories/music_source_row_mapper.dart');
  assert.match(sourceMapper, /source\.keys\.toList\(\)\.\.sort\(\)/);
  assert.match(sourceMapper, /jsonEncode/);
  assert.match(sourceMapper, /jsonDecode/);
  assert(!/SensitiveCredential|SecureCredentialGateway|package:(dio|http)|dart:io|package:flutter/.test(sourceMapper));
  const bootstrap = read('lib/app/app_bootstrap.dart');
  assert(!/DriftLibraryRepository|DriftCollectionRepository|DriftLyricsRepository|DriftMusicSourceRepository|AppDatabase|AndroidSecureCredentialGateway|WindowsSecureCredentialGateway|FlutterSecureStorage/.test(bootstrap), 'Phase 3H bootstrap must use the app data composition boundary');
  assert.match(bootstrap, /createProductionAppDataServices/);
  assert.match(bootstrap, /YYMusic 无法初始化本地数据/);
  assert(!/package:(drift|sqlite3|flutter_secure_storage)\//.test(bootstrap));

  const dataComposition = read('lib/app/database_app_data_services.dart');
  for (const implementation of [
    'DriftLibraryRepository',
    'DriftCollectionRepository',
    'DriftLyricsRepository',
    'DriftMusicSourceRepository',
    'AndroidSecureCredentialGateway',
    'WindowsSecureCredentialGateway',
  ]) {
    assert.match(dataComposition, new RegExp(implementation));
  }
  assert.match(dataComposition, /await closeDatabase\(database\)/);
  assert.match(dataComposition, /await _database\.close\(\)/);

  const devFixtureSources = sources.filter(path => path.startsWith('lib/dev_fixture/'));
  assert.equal(devFixtureSources.length, 2, 'Phase 3H dev fixture implementation set changed');
  for (const path of sources.filter(path => !path.startsWith('lib/dev_fixture/') && path !== 'lib/main_dev.dart')) {
    assert(!/dev_fixture\//.test(read(path)), `${path} imports development fixture code`);
  }
  const defaultMain = read('lib/main.dart');
  assert(!/dev_fixture|main_dev/.test(defaultMain));
  const devMain = read('lib/main_dev.dart');
  assert.match(devMain, /createDevFixtureAppDataServices/);
  const fixture = read('lib/dev_fixture/dev_fixture.dart');
  assert.match(fixture, /https:\/\/fixture\.invalid/);
  assert.match(fixture, /MusicSourceStatus\.disabled/);
  assert.match(fixture, /TrackAvailability\.sourceDisabled/);
  assert(!/SensitiveCredential|credentialRef: ['"]|MusicSourceStatus\.connected|package:(dio|http)|dart:io|PlaybackController|AudioEngine/.test(fixture));
  const fixtureFactory = read('lib/dev_fixture/dev_fixture_app_data_services.dart');
  assert.match(fixtureFactory, /openInMemoryDatabase\(\)/);
  assert(!/openDefaultDatabase|SecureCredentialGateway/.test(fixtureFactory));
  assert.match(read('lib/data/database/database_connection.dart'), /AppDatabase openInMemoryDatabase\(\).*NativeDatabase\.memory\(\)/s);
});

test('native runners are branded and Android release does not use debug signing', () => {
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:label="YYMusic"/);
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:allowBackup="false"/);
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
