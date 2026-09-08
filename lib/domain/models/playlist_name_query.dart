/// Literal substring selection; SQLite and fakes use ASCII case folding only.
final class PlaylistNameQuery {
  factory PlaylistNameQuery(String value) {
    if (value.length > 512 ||
        value.runes.any((r) => r < 0x20 || r >= 0x7f && r <= 0x9f)) {
      throw ArgumentError(
        'Playlist filter must be at most 512 safe characters',
      );
    }
    return PlaylistNameQuery._(value.trim());
  }
  const PlaylistNameQuery._(this.text);
  final String text;
  String get folded => fold(text);
  bool matches(String name) => fold(name).contains(folded);
  static String fold(String value) => value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => match[0]!.toLowerCase(),
  );

  /// Unicode scalar order, matching valid UTF-8 SQLite BINARY identifiers.
  static int compareIds(String left, String right) {
    final a = left.runes.iterator, b = right.runes.iterator;
    while (true) {
      final hasA = a.moveNext(), hasB = b.moveNext();
      if (!hasA || !hasB) {
        return hasA
            ? 1
            : hasB
            ? -1
            : 0;
      }
      final order = a.current.compareTo(b.current);
      if (order != 0) return order;
    }
  }
}
