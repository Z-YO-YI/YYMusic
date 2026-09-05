import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/domain_validation.dart';
import '../../../domain/models/playlist_name.dart';
import '../../../domain/repositories/collection_repository.dart';
import 'playlist_command_result.dart';

/// Root-owned writer. The Library controller remains the list projection owner.
final class PlaylistController extends ChangeNotifier {
  PlaylistController({
    this.collection,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _idFactory = idFactory ?? _newId,
       _clock = clock ?? DateTime.now;
  final CollectionRepository? collection;
  final String Function() _idFactory;
  final DateTime Function() _clock;
  bool _disposed = false, _busy = false;
  bool get busy => _busy;
  bool get isAvailable => !_disposed && collection != null;
  Future<PlaylistCommandResult>? _pending;
  Future<void>? _closeFuture;

  Future<PlaylistCommandResult> createPlaylist(String name) {
    final String normalized;
    try {
      normalized = PlaylistName.normalize(name);
    } catch (_) {
      return Future.value(
        const PlaylistCommandResult(PlaylistCommandStatus.invalidName),
      );
    }
    return _run(() async {
      final id = _idFactory();
      final now = _clock().toUtc();
      await collection!.createPlaylist(
        Playlist(id: id, name: normalized, createdAt: now, updatedAt: now),
      );
      return id;
    });
  }

  Future<PlaylistCommandResult> renamePlaylist(String id, String name) {
    final String normalized;
    try {
      normalized = PlaylistName.normalize(name);
    } catch (_) {
      return Future.value(
        const PlaylistCommandResult(PlaylistCommandStatus.invalidName),
      );
    }
    return _run(() async {
      DomainValidation.identifier(id, 'id');
      await collection!.renamePlaylist(id, normalized);
      return id;
    });
  }

  /// The caller must confirm intent before invoking this metadata-only deletion.
  Future<PlaylistCommandResult> deletePlaylist(String id) => _run(() async {
    DomainValidation.identifier(id, 'id');
    await collection!.deletePlaylist(id);
    return id;
  });

  Future<PlaylistCommandResult> _run(Future<String> Function() action) {
    if (!isAvailable) {
      return Future.value(
        const PlaylistCommandResult(PlaylistCommandStatus.unavailable),
      );
    }
    if (_busy) {
      return Future.value(
        const PlaylistCommandResult(PlaylistCommandStatus.busy),
      );
    }
    _busy = true;
    // Register before executing or notifying. Accepted work is not cancelled by close.
    final operation = _pending = Future<PlaylistCommandResult>(() async {
      try {
        final id = await action();
        return PlaylistCommandResult(
          PlaylistCommandStatus.succeeded,
          playlistId: id,
        );
      } catch (error) {
        final status =
            error is DomainFailure && error.code == DomainFailureCode.notFound
            ? PlaylistCommandStatus.notFound
            : error is DomainFailure &&
                  error.code == DomainFailureCode.forbidden &&
                  const {
                    'collection-repository.playlist-system-create',
                    'collection-repository.playlist-system-rename',
                    'collection-repository.playlist-system-delete',
                  }.contains(error.diagnosticId)
            ? PlaylistCommandStatus.protectedPlaylist
            : PlaylistCommandStatus.failed;
        return PlaylistCommandResult(status);
      } finally {
        _busy = false;
        _pending = null;
        _notify();
      }
    });
    _notify();
    return operation;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _closeFuture = _pending?.then((_) {}) ?? Future.value();
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}

String _newId() {
  final random = Random.secure();
  return 'playlist-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
