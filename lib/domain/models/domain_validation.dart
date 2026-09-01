abstract final class DomainValidation {
  static String identifier(String value, String field) {
    if (value.isEmpty || value.length > 256 || value.trim() != value) {
      throw ArgumentError.value(
        value,
        field,
        'must be a trimmed 1-256 character identifier',
      );
    }
    if (value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      throw ArgumentError.value(
        value,
        field,
        'must not contain control characters',
      );
    }
    return value;
  }

  static String text(String value, String field, {int maxLength = 2048}) {
    if (value.trim().isEmpty || value.length > maxLength) {
      throw ArgumentError.value(
        value,
        field,
        'must contain visible text within $maxLength characters',
      );
    }
    return value;
  }

  static List<String> textList(Iterable<String> values, String field) {
    final copy = values
        .map((value) => text(value, field, maxLength: 512))
        .toList(growable: false);
    if (copy.isEmpty) {
      throw ArgumentError.value(copy, field, 'must not be empty');
    }
    if (copy.toSet().length != copy.length) {
      throw ArgumentError.value(copy, field, 'must not contain duplicates');
    }
    return List<String>.unmodifiable(copy);
  }

  static Uri? httpUri(Uri? value, String field) {
    if (value == null) return null;
    if (!value.hasAuthority ||
        (value.scheme != 'https' && value.scheme != 'http')) {
      throw ArgumentError.value(
        value,
        field,
        'must be an absolute HTTP(S) URI',
      );
    }
    return value;
  }

  static DateTime utc(DateTime value, String field) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, field, 'must be normalized to UTC');
    }
    return value;
  }

  static Map<String, Object?> jsonMap(
    Map<String, Object?> values,
    String field,
  ) {
    return Map.unmodifiable(
      values.map((key, value) {
        text(key, '$field key', maxLength: 256);
        return MapEntry(key, _jsonValue(value, field));
      }),
    );
  }

  static Object? _jsonValue(Object? value, String field) {
    if (value is double && !value.isFinite) {
      throw ArgumentError.value(
        value,
        field,
        'must contain only finite JSON numbers',
      );
    }
    if (value == null || value is bool || value is num || value is String) {
      return value;
    }
    if (value is List<Object?>) {
      return List<Object?>.unmodifiable(
        value.map((item) => _jsonValue(item, field)),
      );
    }
    if (value is Map<String, Object?>) {
      return jsonMap(value, field);
    }
    throw ArgumentError.value(
      value,
      field,
      'must contain only JSON-compatible values',
    );
  }
}
