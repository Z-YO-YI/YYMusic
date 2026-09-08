import 'dart:async';

import 'package:yymusic/domain/models/catalog_search.dart';
import 'package:yymusic/domain/models/local_library_overview.dart';
import 'package:yymusic/domain/models/pagination.dart';
import 'package:yymusic/domain/repositories/local_library_repository.dart';

import 'fake_local_library_repository.dart';

final class LocalMusicProbe implements LocalLibraryRepository {
  final data = FakeLocalLibraryRepository();
  final changes = StreamController<void>.broadcast();
  final calls = <({PageRequest page, SearchCancellation? token})>[];
  Stream<void> Function()? onWatch;
  Future<LocalLibraryOverview> Function(PageRequest, SearchCancellation?)?
  onRead;
  int watchCount = 0;
  @override
  Stream<void> watchLocalChanges() {
    watchCount++;
    return onWatch?.call() ?? changes.stream;
  }

  @override
  Future<LocalLibraryOverview> readLocalOverview(
    PageRequest page, {
    SearchCancellation? cancellation,
  }) {
    calls.add((page: page, token: cancellation));
    return onRead?.call(page, cancellation) ??
        data.readLocalOverview(page, cancellation: cancellation);
  }

  Future<void> close() async {
    await changes.close();
    await data.close();
  }
}

LocalFolderSummary localFolder(int index, {bool enabled = true}) =>
    LocalFolderSummary(
      id: 'folder-${index.toString().padLeft(3, '0')}',
      displayName: '音乐目录 ${index.toString().padLeft(3, '0')}',
      platform: index.isEven
          ? LocalFolderPlatform.windows
          : LocalFolderPlatform.android,
      enabled: enabled,
      lastScannedAt: index.isEven ? DateTime.utc(2026, 9, 1) : null,
    );
