import '../models/catalog_search.dart';
import '../models/local_library_overview.dart';
import '../models/pagination.dart';

/// Read-only view over the existing local index, not an OS scanner or grant API.
/// The owner must drain accepted reads and cancel subscriptions before storage
/// shutdown. Cancellation discards results; it does not interrupt native SQL.
abstract interface class LocalLibraryRepository {
  Future<LocalLibraryOverview> readLocalOverview(
    PageRequest folders, {
    SearchCancellation? cancellation,
  });

  /// Emits after relevant table changes without executing a catalog query.
  /// Subscribe before the initial read. Consumers coalesce and reread; changes
  /// can include unrelated rows and do not contain a new snapshot themselves.
  Stream<void> watchLocalChanges();
}
