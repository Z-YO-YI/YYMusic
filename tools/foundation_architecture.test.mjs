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
    'assets/legal/android_audio/notices.json',
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
  assert.match(bootstrap, /YYMusic 无法初始化应用/);
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

test('playback has one root-owned truth behind project contracts', () => {
  const state = read('lib/playback/playback_state.dart');
  for (const field of [
    'phase', 'currentTrack', 'position', 'buffered', 'duration', 'volume',
    'shuffleEnabled', 'repeatMode', 'queue', 'outputDevice', 'failure',
  ]) {
    assert.match(state, new RegExp(`final [^;]+ ${field};`), `PlaybackState.${field} is missing`);
  }
  for (const phase of [
    'idle', 'loading', 'buffering', 'ready', 'playing', 'paused', 'completed', 'error',
  ]) {
    assert.match(state, new RegExp(`\\b${phase},`), `PlaybackPhase.${phase} is missing`);
  }

  const engine = read('lib/playback/audio_engine.dart');
  for (const command of [
    'load', 'play', 'pause', 'stop', 'seek', 'setVolume', 'setPlaybackRate', 'dispose',
  ]) {
    assert.match(engine, new RegExp(`Future<void> ${command}\\(`), `AudioEngine.${command} is missing`);
  }
  assert.match(engine, /Stream<AudioEngineState> get states/);
  assert.match(read('lib/playback/playable_source.dart'), /locator: <redacted>, headers: <redacted>/);

  const controller = read('lib/playback/playback_controller.dart');
  assert.match(controller, /PlaybackState _state = PlaybackState\(\)/);
  assert.match(controller, /AudioEnginePhase\.completed/);
  assert.match(controller, /RepeatMode\.one/);
  assert.match(controller, /_rebuildShuffleOrder/);
  assert.match(controller, /_collectionRepository\.saveQueue|collection\.saveQueue/);
  const queue = read('lib/playback/queue_controller.dart');
  assert.match(queue, /QueueSnapshot get state => _playback\.state\.queue/);
  assert(!/QueueSnapshot _state|List<QueueEntry> _/.test(queue), 'QueueController must not own a second queue');

  const mediaSession = read('lib/platform/contracts/media_session_gateway.dart');
  assert.match(mediaSession, /abstract interface class MediaSessionGateway/);
  assert.match(mediaSession, /Future<void> updateMetadata\(Track track\)/);
  assert.match(mediaSession, /Future<void> updatePlaybackState\(PlaybackState state\)/);

  for (const path of sources.filter(path => /lib\/(design_system|features|shells)\//.test(path))) {
    assert(!/package:(media_kit|just_audio|audio_service)\//.test(read(path)), `${path} imports an audio plugin`);
  }
  const pluginImports = sources.filter(path => /package:media_kit\//.test(read(path)));
  assert.deepEqual(pluginImports, [], 'rejected media_kit must not remain in active source');
  assert(!/MediaKit|NativeMediaKitPlayerBackend/.test(read('lib/main.dart')));
  const redistribution = JSON.parse(read('docs/legal/media_kit/manifest.json'));
  assert.equal(redistribution.status, 'blocked');
  assert.equal(redistribution.activeDependency, false);
  assert.equal(redistribution.decision, 'rejected');
  assert.equal(redistribution.releaseApproved, false);
  assert.equal(redistribution.productionWiringApproved, false);
  assert.equal(redistribution.scope.distributionMode, 'inventory-only');
  assert(!/assets\/legal\/media_kit|docs\/legal\/media_kit/.test(read('pubspec.yaml')));
  const justAudioImports = sources.filter(path => /package:just_audio\//.test(read(path)));
  assert.deepEqual(
    justAudioImports,
    ['lib/playback/just_audio_backend.dart'],
    'just_audio must remain inside its playback adapter',
  );
  assert(!/JustAudioEngine|NativeJustAudioPlayerBackend/.test(read('lib/main.dart')));
  const pubspec = read('pubspec.yaml');
  const lockfile = read('pubspec.lock');
  assert(!/media_kit/i.test(`${pubspec}\n${lockfile}`));
  assert.match(pubspec, /^  just_audio: 0\.10\.6$/m);
  assert.match(pubspec, /^  just_audio_windows: 0\.2\.3$/m);
  assert.match(lockfile, /just_audio_platform_interface:[\s\S]*?version: "4\.6\.0"/);
  assert.match(lockfile, /audio_session:[\s\S]*?version: "0\.2\.4"/);
  assert.match(read('windows/flutter/generated_plugin_registrant.cc'), /JustAudioWindowsPluginRegisterWithRegistrar/);
  assert.match(read('windows/flutter/generated_plugins.cmake'), /^  just_audio_windows$/m);
  assert.match(
    read('windows/CMakeLists.txt'),
    /target_compile_definitions\(just_audio_windows_plugin PRIVATE[\s\S]*?_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS/,
  );
  const justAudioBackend = read('lib/playback/just_audio_backend.dart');
  assert.match(justAudioBackend, /AudioPlayer\(useProxyForRequestHeaders: useProxyForRequestHeaders\)/);
  assert.match(justAudioBackend, /required bool supportsRequestHeaders/);
  assert.match(justAudioBackend, /headers\.isNotEmpty && !supportsRequestHeaders/);
  assert.match(justAudioBackend, /AudioSource\.uri\(resource, headers: ephemeralHeaders\)/);
  for (const path of sources) {
    assert(!/LockCachingAudioSource|clearAssetCache|StreamAudioSource/.test(read(path)), `${path} adds caching or byte-stream audio`);
  }
  for (const path of sources.filter(path => path.startsWith('lib/shells/'))) {
    assert(!/import\s+['"][^'"]*\/playback\//.test(read(path)), `${path} owns playback logic`);
  }
  for (const path of sources) {
    assert(!/downloadTrack|saveOffline|batchDownload|downloadAlbum/.test(read(path)), `${path} adds a forbidden download API`);
  }
});

test('native runners are branded and Android release does not use debug signing', () => {
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:label="YYMusic"/);
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:allowBackup="false"/);
  assert.match(read('windows/runner/main.cpp'), /window\.Create\(L"YYMusic"/);
  assert(!read('android/app/build.gradle.kts').includes('signingConfigs.getByName("debug")'));
  const apkVerifier = read('tools/verify_android_apk.ps1');
  assert.match(apkVerifier, /libmpv\\\.so/);
  assert.match(apkVerifier, /libmediakitandroidhelper\\\.so/);
  assert.match(apkVerifier, /Rejected media_kit native content unexpectedly packaged in APK/);
});

test('CI validates both debug targets with least-privileged, pinned actions', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /contents: read/);
  assert.match(workflow, /branches: \['codex\/\*\*', 'feat\/\*\*', 'fix\/\*\*', 'refactor\/\*\*', 'docs\/\*\*', 'main', 'master'\]/);
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
  const windows = workflow.slice(
    workflow.indexOf('\n  windows-debug:'),
    workflow.indexOf('\n  android-debug:'),
  );
  assert.match(
    windows,
    /actions\/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a/,
  );
  assert.match(windows, /flutter build windows --debug --no-pub[\s\S]*?\.\/tools\/verify_windows_bundle\.ps1[\s\S]*?actions\/upload-artifact/);
  assert.match(windows, /if: github\.event_name == 'push'/);
  assert.match(windows, /path: build\/windows\/x64\/runner\/Debug\//);
  const windowsVerifier = read('tools/verify_windows_bundle.ps1');
  assert.match(windowsVerifier, /libmpv/);
  assert.match(windowsVerifier, /media_kit/);
  assert.match(windowsVerifier, /AssetManifest\.bin/);
});

test('only the just_audio native POC remains active in read-only dual-platform CI', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /^permissions:\s*\n\s+contents: read\s*$/m);
  assert.match(
    workflow,
    /run_just_audio_poc:[\s\S]*?required: true[\s\S]*?default: false[\s\S]*?type: boolean/,
  );
  assert(!/run_native_audio_poc|run_native_audio_source_poc/.test(workflow));
  const native = workflow.slice(workflow.indexOf('\n  windows-just-audio:'));
  assert.match(native, /runs-on: windows-2025/);
  assert.match(native, /runs-on: ubuntu-24\.04/);
  assert.equal(
    native.match(/if: github\.event_name == 'workflow_dispatch' && inputs\.run_just_audio_poc/g)?.length,
    2,
  );
  assert.match(
    native,
    /ReactiveCircus\/android-emulator-runner@a421e43855164a8197daf9d8d40fe71c6996bb0d/,
  );
  assert.equal(
    native.match(/integration_test\/just_audio_native_local_poc_test\.dart/g)?.length,
    1,
  );
  assert.match(native, /integration_test\/just_audio_android_sources_poc_test\.dart/);
  assert.match(
    native,
    /Require a real Windows playback endpoint[\s\S]*?AudioEndpointBuilder[\s\S]*?Audiosrv[\s\S]*?Get-PnpDevice -Class AudioEndpoint -PresentOnly[\s\S]*?playbackEndpoints\.Count -eq 0/,
  );
  assert(!/native_local_audio_poc_test|native_audio_sources_poc_test|generate_native_audio_poc_tls/.test(native));
  assert(!/contents: write|upload-artifact|gh release|secrets\.|pull_request_target/.test(native));
  assert(!/flutter build apk|flutter build appbundle/.test(native));
  assert.equal(
    workflow.match(/if: github\.event_name != 'workflow_dispatch' \|\| !inputs\.run_just_audio_poc/g)?.length,
    1,
  );

  const integrationFiles = walk('integration_test');
  assert(integrationFiles.every(path => path.endsWith('.dart')));
  assert(!integrationFiles.some(path => /\.(?:wav|mp3|flac|aac|m4a|ogg)$/i.test(path)));
  const headlessHook = 'createWithHeadlessAudioSinkForPoc';
  const hookFiles = [...sources, ...integrationFiles]
    .filter(path => read(path).includes(headlessHook))
    .sort();
  assert.deepEqual(hookFiles, []);
  const justAudioPoc = read('integration_test/just_audio_native_local_poc_test.dart');
  assert.match(justAudioPoc, /JustAudioEngine\.create\([\s\S]*?useProxyForRequestHeaders: false,[\s\S]*?supportsRequestHeaders: false/);
  assert.match(justAudioPoc, /buildDeterministicPcmWav\(\)/);
  assert.match(justAudioPoc, /AudioEnginePhase\.completed/);
  assert(!/MediaKit|headless|https?:\/\//.test(justAudioPoc));
  const sourceHook = 'createForControlledHttpsPoc';
  const sourceHookFiles = [...sources, ...integrationFiles]
    .filter(path => read(path).includes(sourceHook))
    .sort();
  assert.deepEqual(sourceHookFiles, []);

  const debugManifest = read('android/app/src/debug/AndroidManifest.xml');
  assert.match(debugManifest, /\.NativeAudioPocProvider/);
  assert.match(debugManifest, /android:exported="false"/);
  assert.match(debugManifest, /android:grantUriPermissions="false"/);
  assert(!/NativeAudioPocProvider/.test(read('android/app/src/main/AndroidManifest.xml')));
  assert(!/NativeAudioPocProvider/.test(read('android/app/src/profile/AndroidManifest.xml')));
  const provider = read('android/app/src/debug/kotlin/io/github/z_y_o_y_i/yymusic/NativeAudioPocProvider.kt');
  assert.match(provider, /ParcelFileDescriptor\.MODE_READ_ONLY/);
  assert.match(provider, /appContext\.cacheDir/);
  assert(!/externalStorage|MediaStore|READ_MEDIA|MANAGE_EXTERNAL/.test(provider));

  const tlsGenerator = read('tools/generate_native_audio_poc_tls.mjs');
  assert.match(tlsGenerator, /build', 'native-audio-poc/);
  assert.match(tlsGenerator, /process\.argv\.length !== 2/);
  assert.match(tlsGenerator, /rmSync\(privateKeyPath/);
  assert(!/console\.log\([^)]*(?:CERT|KEY|base64)/i.test(tlsGenerator));
  const sensitiveFixtureFiles = [
    ...walk('lib'),
    ...walk('integration_test'),
    ...walk('android/app/src'),
    ...walk('tools'),
  ].filter(path => /\.(?:pem|key|p12|pfx|wav|mp3|flac|aac|m4a|ogg)$/i.test(path));
  assert.deepEqual(sensitiveFixtureFiles, []);

  const networkProbe = read('lib/playback/network_playable_source_probe.dart');
  assert.match(networkProbe, /openUrl\('HEAD'/);
  assert.match(networkProbe, /request\.followRedirects = false/);
  assert.match(networkProbe, /client\.close\(force: true\)/);
  assert(!/print\(|debugPrint|dart:developer/.test(networkProbe));
  assert(!/NetworkPlayableSourceProbe|DartIoNetworkHeadTransport/.test(read('lib/main.dart')));
  assert.match(read('pubspec.yaml'), /integration_test:\s*\n\s+sdk: flutter/);
});

test('shared Shell presenter maps root playback and guards queued seek identity', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.equal(graph.match(/PlaybackPresenter\(playback\)/g)?.length, 1);
  const presenter = read('lib/app/playback_presenter.dart');
  assert.match(presenter, /extends ChangeNotifier/);
  assert.match(presenter, /expectedEntryId: expectedEntryId/);
  const controller = read('lib/playback/playback_controller.dart');
  assert.match(controller, /seek\([\s\S]*?expectedEntryId[\s\S]*?_schedule\([\s\S]*?expectedEntryId != null[\s\S]*?expectedEntryId != _state.queue.currentEntryId/);
  const shell = read('lib/features/player/common/shell_player.dart');
  assert.match(shell, /ValueKey\(\(presenter.entryId, phone, compact\)\)/);
  assert.match(shell, /expectedEntryId: entry/);
  assert(!/onToggleFavorite:|onOpenQueue:|onOpenFullscreen:/.test(shell));
  for (const path of [
    'lib/app/playback_presenter.dart',
    'lib/features/player/common/shell_player.dart',
    ...walk('lib/shells'),
  ]) {
    assert(!/PlaybackController\(|AudioPlayer\(|JustAudio|dart:io|package:just_audio|package:http/.test(read(path)), path);
  }
});

test('Android native source test reuses baseline and contains only a temporary debug fixture', () => {
  const content = read('integration_test/just_audio_android_sources_poc_test.dart');
  assert.match(content, /native_local\.main\(\)/);
  assert.match(content, /Platform\.isAndroid && kDebugMode/);
  assert.match(content, /getTemporaryDirectory\(\)/);
  assert.match(content, /fixture\.create\(exclusive: true\)/);
  assert.match(content, /createdFixture && await fixture\.exists\(\)/);
  assert.match(content, /await fixture\.delete\(\)/);
  assert.match(content, /buildDeterministicPcmWav\(\)/);
  assert.match(content, /PlayableSource\.contentUri\(/);
  assert.match(content, /DomainFailureCode\.playbackOpenFailed/);
  assert.equal(content.match(/engine\.load\(source\)/g)?.length, 2);
  for (const fact of ['sameEngineRecovered', 'missingSourceRejected', 'completed', 'disposed']) {
    assert.match(content, new RegExp(`'${fact}': true`));
  }
  assert.match(content, /await statesClosed\.future/);
  assert.match(content, /useProxyForRequestHeaders: false/);
  assert.match(content, /supportsRequestHeaders: false/);
  assert(!/MediaStore|Permission\.|badCertificateCallback|https?:\/\/|headless/.test(content));
  const metrics = content.slice(content.indexOf('final metrics ='));
  assert(!/fixture\.path|source\.uri|failure\.toString|exception|stackTrace/.test(metrics));
  assert.match(read('.github/workflows/foundation.yml'),
    /just_audio_poc_platform:[\s\S]*?default: both[\s\S]*?type: choice[\s\S]*?options: \[both, android, windows\]/);
});

test('HTTPS playback uses pinned upstream bytes without TLS overrides, disk persistence or production wiring', () => {
  const fixture = read('integration_test/support/pinned_https_audio_fixture.dart');
  assert.match(fixture, /43e3af79dabb43a69badffbbdfa6d421a1cdb36c/);
  assert.match(fixture, /1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce/);
  assert.match(fixture, /request\.followRedirects = false/);
  assert.match(fixture, /client\.close\(force: true\)/);
  assert.match(fixture, /bytes\.length \+ chunk\.length > length/);
  assert.match(fixture, /Duration\(seconds: 40\)/);
  assert(!/badCertificateCallback|SecurityContext|findProxy|File\(|writeAs|base64Decode|Authorization/.test(fixture));
  const native = read('integration_test/just_audio_native_https_poc_test.dart');
  assert.match(native, /verifyPinnedHttpsFixture\(\)/);
  assert.match(native, /PlayableSource\.networkStream\(/);
  assert.match(native, /uri: httpsFixtureUri/);
  assert.match(native, /useProxyForRequestHeaders: false/);
  assert.match(native, /supportsRequestHeaders: false/);
  assert(!/localFile|File\(|writeAs|badCertificateCallback|SecurityContext/.test(native));
  const combined = read('integration_test/just_audio_native_sources_poc_test.dart');
  for (const call of ['android_sources.main()', 'local.main()', 'https.main()']) assert(combined.includes(call));
  for (const path of sources) assert(!/pinned_https_audio_fixture|just_audio_native_https_poc/.test(read(path)), path);
});
