import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models/domain_failure.dart';
import '../domain/models/software_license.dart';
import '../domain/repositories/license_repository.dart';

typedef FrameworkLicenseLoader = Stream<LicenseEntry> Function();
typedef NativeLicenseLoader = Future<String> Function();

/// Reads packaged framework/native license texts only, lazily and without IO APIs.
final class FlutterLicenseRepository implements LicenseRepository {
  const FlutterLicenseRepository({
    this.frameworkLoader = _frameworkLicenses,
    this.nativeLoader = _nativeLicenses,
    this.timeout = const Duration(seconds: 20),
  });

  final FrameworkLicenseLoader frameworkLoader;
  final NativeLicenseLoader nativeLoader;
  final Duration timeout;

  static Stream<LicenseEntry> _frameworkLicenses() => LicenseRegistry.licenses;
  static Future<String> _nativeLicenses() => rootBundle.loadString(
    'assets/legal/android_audio/notices.json',
    cache: false,
  );

  @override
  Future<List<SoftwareLicense>> load() async {
    try {
      return await _read().timeout(timeout);
    } catch (_) {
      throw DomainFailure(
        code: DomainFailureCode.unknown,
        diagnosticId: 'licenses.bundled-text-unavailable',
        retryable: true,
      );
    }
  }

  Future<List<SoftwareLicense>> _read() async {
    final licenses = <SoftwareLicense>[];
    var totalBytes = 0;
    await for (final entry in frameworkLoader().timeout(timeout)) {
      final paragraphs = entry.paragraphs.toList();
      final text = paragraphs.map((p) => p.text).join('\n\n');
      totalBytes += utf8.encode(text).length;
      if (licenses.length >= 10000 || totalBytes > 16 * 1024 * 1024) {
        throw const FormatException('License catalog exceeds limits');
      }
      final names = entry.packages.toList();
      licenses.add(
        SoftwareLicense(
          packages: names.isEmpty ? const ['未标注组件（随应用提供）'] : names,
          text: text,
        ),
      );
    }
    licenses.addAll(_parseNative(await nativeLoader()));
    licenses.sort((a, b) => a.packages.first.compareTo(b.packages.first));
    return List.unmodifiable(licenses);
  }

  List<SoftwareLicense> _parseNative(String source) {
    if (utf8.encode(source).length > 2 * 1024 * 1024) {
      throw const FormatException('Native license catalog exceeds limits');
    }
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> ||
        decoded['schemaVersion'] != 1 ||
        decoded['scope'] != 'resolved-android-media3-audio-closure') {
      throw const FormatException('Unexpected native license scope');
    }
    final documents = decoded['documents'];
    final components = decoded['components'];
    if (documents is! List<Object?> ||
        documents.isEmpty ||
        documents.length > 200 ||
        components is! List<Object?> ||
        components.isEmpty ||
        components.length > 200) {
      throw const FormatException('Invalid native license catalog');
    }
    final texts = <String, String>{};
    final packages = <String, Set<String>>{};
    for (final document in documents) {
      if (document is! Map<String, Object?> ||
          document['sha256'] is! String ||
          document['text'] is! String) {
        throw const FormatException('Invalid native legal document');
      }
      final hash = document['sha256']! as String;
      final text = document['text']! as String;
      final bytes = utf8.encode(text);
      if (bytes.isEmpty ||
          bytes.length > 1024 * 1024 ||
          bytes.length != document['bytes'] ||
          sha256.convert(bytes).toString() != hash ||
          texts.containsKey(hash)) {
        throw const FormatException(
          'Native legal document fingerprint differs',
        );
      }
      texts[hash] = text;
      packages[hash] = {};
    }
    final coordinates = <String>{};
    for (final component in components) {
      if (component is! Map<String, Object?> ||
          component['coordinate'] is! String ||
          component['licenseDocuments'] is! List<Object?> ||
          component['artifacts'] is! List<Object?>) {
        throw const FormatException('Invalid native component');
      }
      final name = component['coordinate']! as String;
      if (!RegExp(r'^[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+$')
              .hasMatch(name) ||
          !coordinates.add(name)) {
        throw const FormatException('Invalid native component identity');
      }
      final references = [...component['licenseDocuments']! as List<Object?>];
      if (references.isEmpty) {
        throw const FormatException('Missing full license');
      }
      for (final artifact in component['artifacts']! as List<Object?>) {
        if (artifact is! Map<String, Object?> ||
            artifact['notices'] is! List<Object?>) {
          throw const FormatException('Invalid native artifact');
        }
        for (final notice in artifact['notices']! as List<Object?>) {
          if (notice is! Map<String, Object?>) {
            throw const FormatException('Invalid embedded notice');
          }
          references.add(notice['document']);
        }
      }
      for (final reference in references) {
        final names = reference is String ? packages[reference] : null;
        if (names == null) {
          throw const FormatException('Missing native document');
        }
        names.add('Android · $name');
      }
    }
    return [
      for (final entry in texts.entries)
        SoftwareLicense(packages: packages[entry.key]!, text: entry.value),
    ];
  }
}
