import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/flutter_license_repository.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/software_license.dart';

void main() {
  final native = File('assets/legal/android_audio/notices.json')
      .readAsStringSync();
  Stream<LicenseEntry> framework() => Stream.value(
    const LicenseEntryWithLineBreaks([
      'package_alpha',
      'package_beta',
    ], 'First paragraph.\n\nFinal complete paragraph.'),
  );

  test(
    'framework notices without package attribution remain visible in full',
    () async {
      final repository = FlutterLicenseRepository(
        frameworkLoader: () => Stream.value(
          const LicenseEntryWithLineBreaks(
            [],
            'Complete unattributed license.',
          ),
        ),
        nativeLoader: () async => native,
      );
      final result = await repository.load();
      expect(
        result
            .singleWhere((license) => license.packages.contains('未标注组件（随应用提供）'))
            .text,
        'Complete unattributed license.',
      );
    },
  );

  test(
    'software license keeps immutable names, full text and normalized search',
    () {
      final names = ['Package_Alpha'];
      final license = SoftwareLicense(
        packages: names,
        text: '  Complete text.\n',
      );
      names.clear();
      expect(license.packages, ['Package_Alpha']);
      expect(license.text, '  Complete text.\n');
      expect(license.matches(' ALPHA '), isTrue);
      expect(license.matches('missing'), isFalse);
      expect(() => license.packages.clear(), throwsUnsupportedError);
      expect(
        () => SoftwareLicense(packages: [], text: 'x'),
        throwsArgumentError,
      );
      expect(
        () => SoftwareLicense(packages: ['x'], text: ' '),
        throwsArgumentError,
      );
    },
  );

  test(
    'framework groups and all three native full texts reach the catalog',
    () async {
      final repository = FlutterLicenseRepository(
        frameworkLoader: framework,
        nativeLoader: () async => native,
      );
      final result = await repository.load();
      expect(result, hasLength(4));
      final sdk = result.singleWhere(
        (entry) => entry.packages.contains('package_alpha'),
      );
      expect(sdk.packages, ['package_alpha', 'package_beta']);
      expect(
        sdk.text,
        contains('First paragraph.\n\nFinal complete paragraph.'),
      );
      final allNativeNames = result
          .expand((entry) => entry.packages)
          .where((name) => name.startsWith('Android · '))
          .toSet();
      expect(allNativeNames, hasLength(51));
      final checker = result.singleWhere(
        (entry) => entry.matches('checker-qual'),
      );
      expect(
        checker.text,
        contains('Copyright 2004-present by the Checker Framework developers'),
      );
      expect(checker.text, contains('THE SOFTWARE.'));
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );

  test('native schema, complete body, duplicate identities and missing references fail safely', () async {
    final changes = <void Function(Map<String, Object?>)>[
      (value) => value['schemaVersion'] = 9,
      (value) => value['scope'] = 'unknown',
      (value) =>
          ((value['documents']! as List<Object?>).first!
                  as Map<String, Object?>)['text'] =
              'Truncated',
      (value) => (value['documents']! as List<Object?>).removeLast(),
      (value) => (value['components']! as List<Object?>).add(
        (value['components']! as List<Object?>).first,
      ),
      (value) =>
          ((value['components']! as List<Object?>).first!
                  as Map<String, Object?>)['licenseDocuments'] =
              <String>[],
    ];
    for (final change in changes) {
      final value = jsonDecode(native) as Map<String, Object?>;
      change(value);
      final repository = FlutterLicenseRepository(
        frameworkLoader: framework,
        nativeLoader: () async => jsonEncode(value),
      );
      await expectLater(
        repository.load(),
        throwsA(
          isA<DomainFailure>().having(
            (failure) => failure.diagnosticId,
            'safe identifier',
            'licenses.bundled-text-unavailable',
          ),
        ),
      );
    }
  });

  test('catalog size, malformed JSON and framework errors are bounded and redacted', () async {
    for (final text in [
      'invalid-json-private-path',
      'x' * (2 * 1024 * 1024 + 1),
    ]) {
      await expectLater(
        FlutterLicenseRepository(
          frameworkLoader: framework,
          nativeLoader: () async => text,
        ).load(),
        throwsA(isA<DomainFailure>()),
      );
    }
    final repository = FlutterLicenseRepository(
      frameworkLoader: () => Stream.error(StateError('private-path-marker')),
      nativeLoader: () async => native,
    );
    try {
      await repository.load();
      fail('Expected safe failure');
    } on DomainFailure catch (failure) {
      expect(failure.toString(), isNot(contains('private-path-marker')));
      expect(failure.retryable, isTrue);
    }
  });

  test(
    'a stalled framework stream times out and a new load can recover',
    () async {
      final controller = StreamController<LicenseEntry>();
      var calls = 0;
      final repository = FlutterLicenseRepository(
        frameworkLoader: () => calls++ == 0 ? controller.stream : framework(),
        nativeLoader: () async => native,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(repository.load(), throwsA(isA<DomainFailure>()));
      await controller.close();
      expect(await repository.load(), hasLength(4));
    },
  );
}
