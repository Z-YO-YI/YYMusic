/// Name policy for user-facing playlist edits, shared by command and data layers.
abstract final class PlaylistName {
  static String normalize(String value) {
    final name = value.trim();
    if (name.isEmpty ||
        name.length > 512 ||
        value.runes.any(
          (rune) => rune < 0x20 || (rune >= 0x7f && rune <= 0x9f),
        )) {
      throw ArgumentError(
        'Playlist name must contain 1–512 non-control characters',
      );
    }
    return name;
  }
}
