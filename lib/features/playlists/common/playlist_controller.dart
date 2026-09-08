import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../domain/models/collection_models.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/domain_validation.dart';
import '../../../domain/models/playlist_name.dart';
import '../../../domain/models/track.dart';
import '../../../domain/repositories/collection_repository.dart';
import 'playlist_command_result.dart';

/// Root-owned writer. The Library controller remains the list projection owner.
final class PlaylistController extends ChangeNotifier {
  PlaylistController({
    this.collection,
    String Function()? idFactory,
    String Function()? entryIdFactory,
    DateTime Function()? clock,
  }) : _idFactory = idFactory ?? _newId,
       _entryIdFactory = entryIdFactory ?? _newEntryId,
       _clock = clock ?? DateTime.now;
  final CollectionRepository? collection;
  final String Function() _idFactory;
  final String Function() _entryIdFactory;
  final DateTime Function() _clock;
  bool _disposed = false, _busy = false;
  bool _notifierDisposed = false;
  int _notificationDepth = 0;
  String? _entryFailure;
  String? get entryFailure => _entryFailure;
  void dismissEntryFailure() {
    if (_disposed || _entryFailure == null) return;
    _entryFailure = null;
    _notify();
  }

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

  Future<PlaylistCommandResult> createPlaylistWithTrack(
    String name,
    TrackRef track,
  ) {
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
      final entryId = _entryIdFactory();
      final now = _clock().toUtc();
      await collection!.createPlaylistWithEntry(
        Playlist(id: id, name: normalized, createdAt: now, updatedAt: now),
        PlaylistEntryDraft(id: entryId, track: track, addedAt: now),
      );
      return id;
    }, entryCommand: true);
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

  Future<PlaylistCommandResult> addTrack(String playlistId, TrackRef track) =>
      _run(() async {
        DomainValidation.identifier(playlistId, 'playlistId');
        await collection!.appendPlaylistEntry(
          playlistId,
          PlaylistEntryDraft(
            id: _entryIdFactory(),
            track: track,
            addedAt: _clock().toUtc(),
          ),
        );
        return playlistId;
      }, entryCommand: true);

  Future<PlaylistCommandResult> removeEntry(
    String playlistId,
    String entryId,
  ) => _run(() async {
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    await collection!.removePlaylistEntry(playlistId, entryId);
    return playlistId;
  }, entryCommand: true);

  Future<PlaylistCommandResult> moveEntry(
    String playlistId,
    String entryId, {
    String? beforeEntryId,
  }) => _run(() async {
    DomainValidation.identifier(playlistId, 'playlistId');
    DomainValidation.identifier(entryId, 'entryId');
    if (beforeEntryId != null) {
      DomainValidation.identifier(beforeEntryId, 'beforeEntryId');
    }
    await collection!.movePlaylistEntry(
      playlistId,
      entryId,
      beforeEntryId: beforeEntryId,
    );
    return playlistId;
  }, entryCommand: true);

  Future<PlaylistCommandResult> _run(
    Future<String> Function() action, {
    bool entryCommand = false,
  }) {
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
    if (entryCommand) _entryFailure = null;
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
                    'collection-repository.playlist-system-entries',
                  }.contains(error.diagnosticId)
            ? PlaylistCommandStatus.protectedPlaylist
            : PlaylistCommandStatus.failed;
        final result = PlaylistCommandResult(status);
        if (entryCommand) _entryFailure = '歌曲条目：${result.message}';
        return result;
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
    if (_disposed) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_disposed) dispose();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _closeFuture = _pending?.then((_) {}) ?? Future.value();
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> close() {
    dispose();
    return _closeFuture!;
  }
}

String _newId() => _randomId('playlist');
String _newEntryId() => _randomId('playlist-entry');

String _randomId(String prefix) {
  final random = Random.secure();
  return '$prefix-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
