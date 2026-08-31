/// No database, fixture catalog or filesystem implementation in Phase 1.
abstract interface class LibraryRepository {
  Future<void> initialize();
  Future<void> dispose();
}
