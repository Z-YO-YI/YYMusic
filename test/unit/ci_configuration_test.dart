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
      final environment = workflow['env'] as YamlMap;
      final pubspec =
          loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
      expect(
        (pubspec['environment'] as YamlMap)['flutter'],
        '>=${environment['FLUTTER_VERSION']}',
      );
    },
  );
}
