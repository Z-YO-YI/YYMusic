import 'lyrics.dart';

/// Immutable, clock-free projection of timed lyrics onto media position.
///
/// A positive document offset delays lyrics. Intervals are start-inclusive and
/// end-exclusive; the last line at an equal start time takes precedence.
final class LyricsTimeline {
  const LyricsTimeline(this.document);

  final LyricsDocument document;
  static const _maxMicros = 0x7fffffffffffffff;

  /// Returns no line for plain lyrics, gaps or unrepresentable positions.
  int? activeIndex(Duration position) {
    if (document.kind != LyricsKind.synchronized || position.isNegative) {
      return null;
    }
    final media = position.inMicroseconds;
    final offset = document.offset.inMicroseconds;
    if ((offset > 0 && media < offset) ||
        (offset < 0 && media > _maxMicros + offset)) {
      return null;
    }
    final time = media - offset;
    final lines = document.lines;
    var low = 0;
    var high = lines.length;
    while (low < high) {
      final middle = low + ((high - low) ~/ 2);
      if (lines[middle].start!.inMicroseconds <= time) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final candidate = low - 1;
    if (candidate < 0 || time >= lines[candidate].end!.inMicroseconds) {
      return null;
    }
    return candidate;
  }

  /// Maps a timed line to media time, rejecting out-of-range media targets.
  Duration? seekTarget(int index, {Duration? duration}) {
    if (document.kind != LyricsKind.synchronized ||
        index < 0 ||
        index >= document.lines.length ||
        (duration != null && duration <= Duration.zero)) {
      return null;
    }
    final start = document.lines[index].start!.inMicroseconds;
    final offset = document.offset.inMicroseconds;
    if (offset > 0 && start > _maxMicros - offset) return null;
    final effective = start + offset;
    final target = Duration(microseconds: effective < 0 ? 0 : effective);
    if (duration != null && target >= duration) return null;
    return target;
  }
}
