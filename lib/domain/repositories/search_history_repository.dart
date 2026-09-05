import '../models/catalog_search.dart';

abstract interface class SearchHistoryRepository {
  /// Newest first, bounded to 20 entries; source identities remain distinct.
  Future<List<SearchHistoryEntry>> listHistory();
  Future<void> record(String query, {String? sourceId});
  Future<void> clear();
  Future<void> dispose();
}
