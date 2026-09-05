import 'domain_validation.dart';
import 'track.dart';

/// A literal substring query over the persisted catalog, not a remote request.
final class CatalogQuery {
  CatalogQuery(String text, {this.sourceType, String? sourceId})
    : text = normalizeSearchText(text),
      sourceId = sourceId == null
          ? null
          : DomainValidation.identifier(sourceId, 'sourceId');

  final String text;
  final MusicSourceType? sourceType;
  final String? sourceId;

  @override
  String toString() => 'CatalogQuery(<redacted>)';
}

/// Cooperative cancellation; never promises to interrupt native SQLite work.
final class SearchCancellation {
  var _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
  void throwIfCancelled() {
    if (_cancelled) throw const SearchCancelled();
  }
}

final class SearchCancelled implements Exception {
  const SearchCancelled();
  @override
  String toString() => 'SearchCancelled';
}

final class SearchHistoryEntry {
  SearchHistoryEntry({
    required String id,
    required String query,
    required DateTime searchedAt,
    String? sourceId,
  }) : id = DomainValidation.identifier(id, 'id'),
       query = normalizeSearchText(query),
       sourceId = sourceId == null
           ? null
           : DomainValidation.identifier(sourceId, 'sourceId'),
       searchedAt = DomainValidation.utc(searchedAt, 'searchedAt') {
    if (this.query.isEmpty) throw ArgumentError('Empty search history query');
  }

  final String id;
  final String query;
  final String? sourceId;
  final DateTime searchedAt;

  @override
  String toString() => 'SearchHistoryEntry(<redacted>)';
}

String normalizeSearchText(String text) {
  if (text.length > 2048 ||
      text.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
    // Do not put potentially private search input into ArgumentError.value.
    throw ArgumentError(
      'Search text must be at most 2048 characters without controls',
    );
  }
  return text.trim();
}

/// Matches SQLite's built-in lower(): ASCII letters only, no locale guessing.
String foldSearchText(String text) =>
    text.replaceAllMapped(RegExp('[A-Z]'), (match) => match[0]!.toLowerCase());
