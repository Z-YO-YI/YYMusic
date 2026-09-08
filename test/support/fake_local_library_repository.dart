import 'dart:async';

import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/local_library_overview.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/domain/repositories/local_library_repository.dart';

/// Isolated fixture implementation, never used by production bootstrap.
final class FakeLocalLibraryRepository implements LocalLibraryRepository {
  final tracks = <Track>[];
  final folders = <LocalFolderSummary>[];
  final _changes = StreamController<void>.broadcast();
  Future<void> Function()? beforeRead;

  @override
  Future<LocalLibraryOverview> readLocalOverview(
    PageRequest page, {
    SearchCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await beforeRead?.call();
    cancellation?.throwIfCancelled();
    final local = tracks.where((t) => t.sourceType == MusicSourceType.local);
    final sorted = folders.toList()
      ..sort((a, b) {
        final folded = foldSearchText(a.displayName)
            .compareTo(foldSearchText(b.displayName));
        if (folded != 0) return folded;
        final exact = a.displayName.compareTo(b.displayName);
        return exact == 0 ? a.id.compareTo(b.id) : exact;
      });
    return LocalLibraryOverview(
      tracks: LocalTrackSummary(
        counts: {
          for (final state in TrackAvailability.values)
            state: local.where((t) => t.availability == state).length,
        },
        totalDuration: local.fold(Duration.zero, (sum, t) => sum + t.duration),
      ),
      folderCount: sorted.length,
      enabledFolderCount: sorted.where((f) => f.enabled).length,
      page: page,
      folders: sorted.skip(page.offset).take(page.limit),
    );
  }

  void changed() => _changes.add(null);
  @override
  Stream<void> watchLocalChanges() => _changes.stream;
  Future<void> close() => _changes.close();
}
