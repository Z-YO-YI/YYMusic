import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('Profile probe is explicit, read-only, short-lived and excludes APK delivery', () {
    final workflow = loadYaml(
      File('.github/workflows/foundation.yml').readAsStringSync(),
    ) as YamlMap;
    final inputs =
        ((workflow['on'] as YamlMap)['workflow_dispatch'] as YamlMap)['inputs']
            as YamlMap;
    expect((inputs['build_windows_audio_probe'] as YamlMap)['default'], false);
    expect((inputs['build_windows_audio_probe'] as YamlMap)['type'], 'boolean');
    final jobs = workflow['jobs'] as YamlMap;
    final checks = (jobs['checks'] as YamlMap)['steps'] as YamlList;
    final conflict = checks.cast<YamlMap>().singleWhere(
      (step) => step['name'] == 'Reject conflicting diagnostic modes',
    );
    expect(
      conflict['if'],
      'inputs.run_just_audio_poc && inputs.build_windows_audio_probe',
    );
    expect(conflict['run'], 'exit 1');
    final windows = jobs['windows-debug'] as YamlMap;
    expect(windows['permissions'], isNull);
    final steps = (windows['steps'] as YamlList).cast<YamlMap>();
    final profileBuild = steps.singleWhere(
      (step) => step['name'] == 'Build isolated Windows Profile audio probe',
    );
    final profileUpload = steps.singleWhere(
      (step) => step['name'] == 'Upload short-lived Windows diagnostic only',
    );
    const condition =
        "github.event_name == 'workflow_dispatch' && inputs.build_windows_audio_probe";
    expect(profileBuild['if'], condition);
    expect(profileUpload['if'], condition);
    expect(
      profileBuild['run'],
      allOf(
        contains('flutter build windows --profile'),
        contains('integration_test/windows_audio_probe.dart'),
        contains('windows_audio_profile_metadata.ps1'),
      ),
    );
    expect((profileUpload['with'] as YamlMap)['retention-days'], 1);
    expect(
      (profileUpload['with'] as YamlMap)['path'],
      'build/windows/x64/runner/Profile/',
    );
    expect(
      (jobs['android-debug'] as YamlMap)['if'],
      contains('!inputs.build_windows_audio_probe'),
    );
    final debug = steps.singleWhere(
      (step) => step['run'] == 'flutter build windows --debug --no-pub',
    );
    expect(debug['if'], '!inputs.build_windows_audio_probe');
  });
  test('CI YAML parses and grants write permission only to Android delivery', () {
    final workflow = loadYaml(
      File('.github/workflows/foundation.yml').readAsStringSync(),
    ) as YamlMap;
    final triggers = workflow['on'] as YamlMap;
    expect(
      triggers.keys,
      containsAll(['push', 'pull_request', 'workflow_dispatch']),
    );
    expect(
      ((triggers['push'] as YamlMap)['branches'] as YamlList).toSet(),
      containsAll(['codex/**', 'feat/**', 'fix/**', 'refactor/**', 'docs/**']),
    );
    expect(workflow['permissions'], {'contents': 'read'});
    final jobs = workflow['jobs'] as YamlMap;
    expect(jobs.keys.toSet(), {
      'checks',
      'windows-debug',
      'android-debug',
      'windows-just-audio',
      'android-just-audio',
    });
    final dispatch = triggers['workflow_dispatch'] as YamlMap;
    expect((dispatch['inputs'] as YamlMap)['run_just_audio_poc'], {
      'description': 'Run the read-only just_audio native source POC',
      'required': true,
      'default': false,
      'type': 'boolean',
    });
    for (final id in [
      'windows-debug',
      'android-debug',
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
      (jobs['windows-debug'] as YamlMap)['if'],
      "github.event_name != 'workflow_dispatch' || !inputs.run_just_audio_poc",
    );
    expect(
      (jobs['android-debug'] as YamlMap)['if'],
      "github.event_name != 'workflow_dispatch' || "
      '(!inputs.run_just_audio_poc && !inputs.build_windows_audio_probe)',
    );

    expect((jobs['windows-just-audio'] as YamlMap)['runs-on'], 'windows-2025');
    expect((jobs['android-just-audio'] as YamlMap)['runs-on'], 'ubuntu-24.04');
    final windowsJustAudioSteps =
        ((jobs['windows-just-audio'] as YamlMap)['steps'] as YamlList)
            .cast<YamlMap>();
    final windowsAudioPreflight = windowsJustAudioSteps.singleWhere(
      (step) => step['name'] == 'Require a real Windows playback endpoint',
    );
    expect(windowsAudioPreflight['shell'], 'pwsh');
    expect(
      windowsAudioPreflight['run'],
      allOf(
        contains("@('AudioEndpointBuilder', 'Audiosrv')"),
        contains('Get-PnpDevice -Class AudioEndpoint -PresentOnly'),
        contains('playbackEndpoints.Count -eq 0'),
      ),
    );
    for (final id in ['windows-just-audio', 'android-just-audio']) {
      final job = jobs[id] as YamlMap;
      expect(job['permissions'], isNull);
      expect(
        job['if'],
        "github.event_name == 'workflow_dispatch' && "
        'inputs.run_just_audio_poc && inputs.just_audio_poc_platform != '
        "'${id == 'windows-just-audio' ? 'android' : 'windows'}'",
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
          contains(
            id == 'windows-just-audio'
                ? 'integration_test/just_audio_native_local_poc_test.dart'
                : 'integration_test/just_audio_android_sources_poc_test.dart',
          ),
        ),
      );
    }
  });

  test(
    'native platform choice defaults to both and cannot enable delivery',
    () {
      final workflow = loadYaml(
        File('.github/workflows/foundation.yml').readAsStringSync(),
      ) as YamlMap;
      final inputs =
          ((workflow['on'] as YamlMap)['workflow_dispatch']
                  as YamlMap)['inputs']
              as YamlMap;
      final platform = inputs['just_audio_poc_platform'] as YamlMap;
      expect(platform['type'], 'choice');
      expect(platform['default'], 'both');
      expect(platform['required'], true);
      expect(platform['options'], ['both', 'android', 'windows']);
      final jobs = workflow['jobs'] as YamlMap;
      for (final id in ['checks', 'windows-debug', 'android-debug']) {
        // Choosing a platform is not permission to change the delivery mode.
        expect(
          (jobs[id] as YamlMap)['if'].toString(),
          isNot(contains('just_audio_poc_platform')),
        );
      }
      final checks = (jobs['checks'] as YamlMap)['steps'] as YamlList;
      expect(
        checks.cast<YamlMap>().map((step) => step['run']),
        contains(
          'dart format --output=none --set-exit-if-changed lib test integration_test',
        ),
      );
      for (final id in ['windows-just-audio', 'android-just-audio']) {
        final steps = ((jobs[id] as YamlMap)['steps'] as YamlList)
            .cast<YamlMap>();
        expect(steps.any((step) => step['continue-on-error'] == true), isFalse);
        expect(steps.any((step) => step['if'] == 'always()'), isFalse);
        expect(
          steps.map((step) => step['uses'].toString()).join('\n'),
          isNot(contains('upload-artifact')),
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
