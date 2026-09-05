import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test(
    'CI YAML parses and grants write permission only to Android delivery',
    () {
      final workflow = loadYaml(
        File('.github/workflows/foundation.yml').readAsStringSync(),
      ) as YamlMap;
      final triggers = workflow['on'] as YamlMap;
      expect(
        triggers.keys,
        containsAll(['push', 'pull_request', 'workflow_dispatch']),
      );
      expect(workflow['permissions'], {'contents': 'read'});
      final jobs = workflow['jobs'] as YamlMap;
      expect(jobs.keys.toSet(), {
        'checks',
        'windows-debug',
        'android-debug',
        'windows-native-audio',
        'android-native-audio',
        'windows-native-audio-sources',
        'android-native-audio-sources',
        'windows-just-audio',
        'android-just-audio',
      });
      final dispatch = triggers['workflow_dispatch'] as YamlMap;
      expect((dispatch['inputs'] as YamlMap)['run_native_audio_poc'], {
        'description': 'Run the read-only Android and Windows native audio POC',
        'required': true,
        'default': false,
        'type': 'boolean',
      });
      expect((dispatch['inputs'] as YamlMap)['run_native_audio_source_poc'], {
        'description': 'Run the read-only content URI and HTTPS audio POC',
        'required': true,
        'default': false,
        'type': 'boolean',
      });
      expect((dispatch['inputs'] as YamlMap)['run_just_audio_poc'], {
        'description': 'Run the read-only just_audio native local WAV POC',
        'required': true,
        'default': false,
        'type': 'boolean',
      });
      for (final id in [
        'windows-debug',
        'android-debug',
        'windows-native-audio',
        'android-native-audio',
        'windows-native-audio-sources',
        'android-native-audio-sources',
        'windows-just-audio',
        'android-just-audio',
      ]) {
        expect((jobs[id] as YamlMap)['needs'], 'checks');
      }
      expect((jobs['checks'] as YamlMap)['permissions'], isNull);
      expect((jobs['windows-debug'] as YamlMap)['permissions'], isNull);
      expect((jobs['android-debug'] as YamlMap)['permissions'], {
        'contents': 'write',
      });
      final windowsSteps =
          (jobs['windows-debug'] as YamlMap)['steps'] as YamlList;
      expect(
        windowsSteps.whereType<YamlMap>().map((step) => step['run']),
        contains(
          'flutter test --no-pub --tags windows-golden --reporter expanded',
        ),
      );
      final environment = workflow['env'] as YamlMap;
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      expect(
        (pubspec['environment'] as YamlMap)['flutter'],
        '>=${environment['FLUTTER_VERSION']}',
      );

      expect(
        (jobs['windows-native-audio'] as YamlMap)['runs-on'],
        'windows-2025',
      );
      expect(
        (jobs['android-native-audio'] as YamlMap)['runs-on'],
        'ubuntu-24.04',
      );
      for (final id in ['windows-native-audio', 'android-native-audio']) {
        final job = jobs[id] as YamlMap;
        expect(job['permissions'], isNull);
        expect(
          job['if'],
          "github.event_name == 'workflow_dispatch' && "
          'inputs.run_native_audio_poc',
        );
        final steps = (job['steps'] as YamlList).cast<YamlMap>();
        final commands = <String>[
          ...steps.map((step) => step['run']).whereType<String>(),
          ...steps
              .map((step) => step['with'])
              .whereType<YamlMap>()
              .map((withValues) => withValues['script'])
              .whereType<String>(),
        ];
        expect(
          commands,
          anyElement(
            contains('integration_test/native_local_audio_poc_test.dart'),
          ),
        );
      }
      for (final id in ['windows-debug', 'android-debug']) {
        expect(
          (jobs[id] as YamlMap)['if'],
          "github.event_name != 'workflow_dispatch' || "
          '(!inputs.run_native_audio_poc && '
          '!inputs.run_native_audio_source_poc && '
          '!inputs.run_just_audio_poc)',
        );
      }

      expect(
        (jobs['windows-just-audio'] as YamlMap)['runs-on'],
        'windows-2025',
      );
      expect(
        (jobs['android-just-audio'] as YamlMap)['runs-on'],
        'ubuntu-24.04',
      );
      for (final id in ['windows-just-audio', 'android-just-audio']) {
        final job = jobs[id] as YamlMap;
        expect(job['permissions'], isNull);
        expect(
          job['if'],
          "github.event_name == 'workflow_dispatch' && "
          'inputs.run_just_audio_poc',
        );
        final steps = (job['steps'] as YamlList).cast<YamlMap>();
        final commands = <String>[
          ...steps.map((step) => step['run']).whereType<String>(),
          ...steps
              .map((step) => step['with'])
              .whereType<YamlMap>()
              .map((withValues) => withValues['script'])
              .whereType<String>(),
        ];
        expect(
          commands,
          anyElement(
            contains('integration_test/just_audio_native_local_poc_test.dart'),
          ),
        );
      }

      for (final id in [
        'windows-native-audio-sources',
        'android-native-audio-sources',
      ]) {
        final job = jobs[id] as YamlMap;
        expect(job['permissions'], isNull);
        expect(
          job['if'],
          "github.event_name == 'workflow_dispatch' && "
          'inputs.run_native_audio_source_poc',
        );
        final steps = (job['steps'] as YamlList).cast<YamlMap>();
        final commands = <String>[
          ...steps.map((step) => step['run']).whereType<String>(),
          ...steps
              .map((step) => step['with'])
              .whereType<YamlMap>()
              .map((withValues) => withValues['script'])
              .whereType<String>(),
        ];
        expect(
          commands,
          contains('node tools/generate_native_audio_poc_tls.mjs'),
        );
        expect(
          commands,
          anyElement(
            allOf(
              contains('integration_test/native_audio_sources_poc_test.dart'),
              contains(
                '--dart-define-from-file='
                'build/native-audio-poc/tls-defines.json',
              ),
            ),
          ),
        );
      }
    },
  );

  test(
    'cloud APK delivery is manual, draft-only and uploads verified files',
    () {
      final workflow = loadYaml(
        File('.github/workflows/foundation.yml').readAsStringSync(),
      ) as YamlMap;
      final jobs = workflow['jobs'] as YamlMap;
      final android = jobs['android-debug'] as YamlMap;
      final steps = (android['steps'] as YamlList).cast<YamlMap>();
      expect(android['needs'], 'checks');
      int runIndex(String command) => steps.indexWhere(
        (step) => (step['run'] as String? ?? '').contains(command),
      );
      final build = runIndex('flutter build apk --debug --no-pub');
      final verify = runIndex('apksigner');
      final assets = runIndex('./tools/verify_android_apk.ps1');
      final package = runIndex('node tools/android_artifact.mjs');
      final upload = steps.indexWhere(
        (step) => step['id'] == 'android-apk-release',
      );
      expect(build, greaterThanOrEqualTo(0));
      expect(verify, greaterThan(build));
      expect(assets, greaterThan(verify));
      expect(package, greaterThan(assets));
      expect(upload, greaterThan(package));
      final summary = runIndex('--summary');
      expect(summary, greaterThan(upload));
      expect(steps.any((step) => step['continue-on-error'] == true), isFalse);
      expect(steps[upload]['if'], "github.event_name == 'workflow_dispatch'");
      expect(steps[summary]['if'], "github.event_name == 'workflow_dispatch'");
      expect(steps[upload]['uses'], isNull);
      expect(steps[upload]['env'], {'GH_TOKEN': r'${{ github.token }}'});
      final script = steps[upload]['run'] as String;
      expect(script, contains('gh release create'));
      expect(
        script,
        contains(r'ci-debug-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}'),
      );
      expect(script, contains(r'--target "$GITHUB_SHA"'));
      expect(script, contains('--draft'));
      expect(script, contains('--prerelease'));
      expect(script, isNot(contains('--clobber')));
      expect(script, isNot(contains('actions/upload-artifact')));
      expect(
        script,
        contains('https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-*'),
      );
      expect(script, contains(r'release-url=$release_url'));
      expect(
        steps[summary]['env'],
        containsPair(
          'YY_APK_RELEASE_URL',
          r'${{ steps.android-apk-release.outputs.release-url }}',
        ),
      );
      for (final path in [
        'build/ci/android-debug/YYMusic-debug.apk',
        'build/ci/android-debug/SHA256SUMS',
        'build/ci/android-debug/build-metadata.json',
      ]) {
        expect(script, contains(path));
      }
    },
  );

  test(
    'Android SDK installation does not depend on sdkmanager being on PATH',
    () {
      final workflow = loadYaml(
        File('.github/workflows/foundation.yml').readAsStringSync(),
      ) as YamlMap;
      final jobs = workflow['jobs'] as YamlMap;
      final android = jobs['android-debug'] as YamlMap;
      final steps = (android['steps'] as YamlList).cast<YamlMap>();
      final install = steps.indexWhere(
        (step) => step['name'] == 'Install pinned Android build components',
      );
      final build = steps.indexWhere(
        (step) => step['run'] == 'flutter build apk --debug --no-pub',
      );
      expect(install, greaterThanOrEqualTo(0));
      expect(build, greaterThan(install));
      final script = steps[install]['run'] as String;
      expect(
        script,
        contains(
          r'${ANDROID_HOME:?ANDROID_HOME is required}/cmdline-tools/latest/bin/sdkmanager',
        ),
      );
      expect(script, contains(r'test -x "$sdk_manager"'));
      expect(
        script,
        contains(
          r'"$sdk_manager" '
          "'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358'",
        ),
      );
      expect(script, isNot(contains('--licenses')));
    },
  );
}
