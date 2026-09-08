import 'catalog_reference.dart';
import 'pagination.dart';
import 'track.dart';

enum LocalFolderPlatform { windows, android, unknown }

/// Persisted metadata only: neither enabled nor lastScannedAt proves access.
/// Deliberately excludes paths, content URIs and authorization references.
final class LocalFolderSummary {
  LocalFolderSummary({
    required String id,
    required String displayName,
    required this.platform,
    required this.enabled,
    this.lastScannedAt,
  }) : id = catalogIdentifier(id),
       displayName = _folderName(displayName) {
    if (lastScannedAt != null && !lastScannedAt!.isUtc) {
      throw ArgumentError('Local folder scan time must be UTC');
    }
  }

  final String id;
  final String displayName;
  final LocalFolderPlatform platform;
  final bool enabled;
  final DateTime? lastScannedAt;

  @override
  String toString() => 'LocalFolderSummary(<redacted>)';
}

String _folderName(String value) {
  if (value.trim().isEmpty ||
      value.length > 512 ||
      value.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    throw ArgumentError('Invalid local folder display name');
  }
  return value;
}

/// Counts all persisted local references, not files verified by a fresh scan.
final class LocalTrackSummary {
  LocalTrackSummary({
    required Map<TrackAvailability, int> counts,
    required this.totalDuration,
  }) : counts = Map.unmodifiable({
         for (final state in TrackAvailability.values)
           state: counts[state] ?? 0,
       }) {
    if (this.counts.values.any((count) => count < 0) ||
        totalDuration.isNegative) {
      throw ArgumentError('Invalid local track statistics');
    }
  }

  final Map<TrackAvailability, int> counts;
  final Duration totalDuration;
  int get totalCount => counts.values.fold(0, (total, count) => total + count);
  int get availableCount => counts[TrackAvailability.available]!;
  int get unavailableCount => totalCount - availableCount;
}

/// One statement's complete statistics and a bounded stable folder window.
/// Separate calls are not a long-lived snapshot; callers refresh after changes.
final class LocalLibraryOverview {
  LocalLibraryOverview({
    required this.tracks,
    required this.folderCount,
    required this.enabledFolderCount,
    required this.page,
    required Iterable<LocalFolderSummary> folders,
  }) : folders = List.unmodifiable(folders) {
    final visibleEnabled = this.folders
        .where((folder) => folder.enabled)
        .length;
    if (folderCount < 0 ||
        enabledFolderCount < 0 ||
        enabledFolderCount > folderCount ||
        visibleEnabled > enabledFolderCount ||
        this.folders.length - visibleEnabled >
            folderCount - enabledFolderCount ||
        this.folders.length !=
            (folderCount - page.offset).clamp(0, page.limit) ||
        this.folders.map((folder) => folder.id).toSet().length !=
            this.folders.length) {
      throw ArgumentError('Invalid local folder window');
    }
  }

  final LocalTrackSummary tracks;
  final int folderCount;
  final int enabledFolderCount;
  final PageRequest page;
  final List<LocalFolderSummary> folders;
  bool get hasMore => page.offset + folders.length < folderCount;

  @override
  String toString() => 'LocalLibraryOverview(<redacted>)';
}
