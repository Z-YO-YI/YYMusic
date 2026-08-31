import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test(
    'CI YAML parses, gates both native builds and uses no write permission',
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
      expect(jobs.keys.toSet(), {'checks', 'windows-debug', 'android-debug'});
      for (final id in ['windows-debug', 'android-debug']) {
        expect((jobs[id] as YamlMap)['needs'], 'checks');
      }
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
    },
  );

  test(
    'cloud APK delivery is gated, pinned and uploads only verified files',
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
      final upload = steps.indexWhere((step) => step['id'] == 'android-apk');
      expect(build, greaterThanOrEqualTo(0));
      expect(verify, greaterThan(build));
      expect(assets, greaterThan(verify));
      expect(package, greaterThan(assets));
      expect(upload, greaterThan(package));
      expect(runIndex('--summary'), greaterThan(upload));
      expect(steps.any((step) => step['continue-on-error'] == true), isFalse);
      expect(
        steps[upload]['if'],
        isNull,
      ); // Normal success gate, never always().
      expect(
        steps[upload]['uses'],
        'actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a',
      );
      final options = steps[upload]['with'] as YamlMap;
      expect(options['path'].toString().trim().split('\n'), [
        'build/ci/android-debug/YYMusic-debug.apk',
        'build/ci/android-debug/SHA256SUMS',
        'build/ci/android-debug/build-metadata.json',
      ]);
      expect(options['if-no-files-found'], 'error');
      expect(options['retention-days'], 14);
      expect(options['compression-level'], 0);
      expect(options['include-hidden-files'], false);
      expect(options['overwrite'], false);
      expect(options['name'], contains(r'${{ github.sha }}'));
      expect(options['name'], contains(r'${{ github.run_attempt }}'));
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
