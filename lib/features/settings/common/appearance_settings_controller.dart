import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../domain/models/appearance_settings.dart';
import '../../../domain/models/domain_failure.dart';
import '../../../domain/models/load_state.dart';
import '../../../domain/repositories/appearance_settings_repository.dart';

/// Root persistence bridge for all existing appearance controls, not a second theme.
final class AppearanceSettingsController extends ChangeNotifier {
  AppearanceSettingsController({required this.appearance, this.repository}) {
    _desired = _snapshot();
    appearance.addListener(_changed);
  }
  final YYAppearanceController appearance;
  final AppearanceSettingsRepository? repository;
  late AppearanceSettings _desired;
  AppearanceSettings? _saved;
  Future<void>? _worker, _initializing, _closing;
  DomainFailure? _failure;
  bool _loaded = false, _loading = false, _saving = false;
  bool _stopped = false, _restoring = false, _notifierDisposed = false;
  int _revision = 0, _notificationDepth = 0;

  bool get persistent => repository != null;
  bool get ready => _loaded && !_stopped;
  bool get saving => _saving;
  bool get unsaved => persistent && _desired != _saved;
  DomainFailure? get failure => _failure;
  LoadPhase get phase => _loading
      ? LoadPhase.loading
      : _failure != null
      ? LoadPhase.error
      : _loaded
      ? LoadPhase.data
      : LoadPhase.idle;

  /// Explicit startup before the app renders. Read failures stay recoverable.
  Future<void> initialize() {
    if (_stopped) return _closing ?? Future<void>.value();
    if (repository == null) {
      _loaded = true;
      _saved = _desired;
      return _initializing ??= Future<void>.value();
    }
    return _initializing ??= _start(read: true);
  }

  /// Retry the last load or latest unsaved snapshot, never an obsolete value.
  void retry() {
    if (_stopped || _worker != null || _failure == null) return;
    _failure = null;
    unawaited(_start(read: !_loaded));
  }

  AppearanceSettings _snapshot() => AppearanceSettings(
    mode: AppearanceMode.values.byName(appearance.mode.name),
    accent: appearance.accent.preset == null
        ? AppearanceAccent.custom
        : AppearanceAccent.values.byName(appearance.accent.preset!.name),
    customAccent: appearance.accent.preset == null
        ? appearance.accent.originalHex
        : null,
    glassEnabled: !appearance.reduceGlass,
    reduceMotion: appearance.reduceMotion,
  );

  void _changed() {
    if (_stopped || _restoring) return;
    _revision++;
    _desired = _snapshot();
    if (_loaded) {
      _failure = null;
      if (!persistent) _saved = _desired;
      _ensureSave();
    }
    _notify();
  }

  void _ensureSave() {
    if (_loaded &&
        persistent &&
        unsaved &&
        _failure == null &&
        _worker == null) {
      unawaited(_start(read: false));
    }
  }

  Future<void> _start({required bool read}) {
    if (_worker != null) return _worker!;
    _loading = read;
    // The event task is registered before invoking a potentially reentrant dependency.
    final work = _worker =
        Future<void>(() async {
          if (read) {
            try {
              final stored =
                  await (repository?.read() ??
                      Future<AppearanceSettings>.value(_desired));
              _saved = stored;
              _loaded = true;
              if (_revision == 0) {
                _desired = stored;
                if (!_stopped) {
                  _restoring = true;
                  try {
                    appearance.restore(
                      mode: YYThemeMode.values.byName(stored.mode.name),
                      accent: stored.accent == AppearanceAccent.custom
                          ? YYAccent.custom(stored.customAccent!)
                          : YYAccent.fromPreset(
                              YYAccentPreset.values.byName(stored.accent.name),
                            ),
                      reduceGlass: !stored.glassEnabled,
                      reduceMotion: stored.reduceMotion,
                    );
                  } finally {
                    _restoring = false;
                  }
                  // Other listeners may make a real change during restoration.
                  final actual = _snapshot();
                  if (actual != stored) {
                    _revision++;
                    _desired = actual;
                  }
                }
              }
            } catch (_) {
              _failure = _safeFailure('load');
            } finally {
              _loading = false;
            }
          }
          if (_loaded && repository == null) _saved = _desired;
          while (_loaded && persistent && unsaved && _failure == null) {
            final value = _desired;
            _saving = true;
            _notify();
            try {
              await repository!.save(value);
              _saved = value;
            } catch (_) {
              // A newer accepted preference gets its own attempt after this one.
              if (_desired == value) _failure = _safeFailure('save');
            } finally {
              _saving = false;
            }
          }
        }).whenComplete(() {
          _worker = null;
          // Covers a change delivered between the loop's last check and completion.
          _ensureSave();
          _notify();
        });
    unawaited(work.catchError((Object _) {}));
    _notify();
    return work;
  }

  static DomainFailure _safeFailure(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'appearance-settings.$operation',
    retryable: true,
  );

  void _notify() {
    if (_stopped) return;
    _notificationDepth++;
    try {
      notifyListeners();
    } finally {
      _notificationDepth--;
      if (_stopped) dispose();
    }
  }

  @override
  void dispose() {
    if (!_stopped) {
      _stopped = true;
      appearance.removeListener(_changed);
      _closing = _drain();
      unawaited(_closing!.catchError((Object _) {}));
    }
    if (_notifierDisposed || _notificationDepth != 0) return;
    _notifierDisposed = true;
    super.dispose();
  }

  Future<void> _drain() async {
    while (_worker != null) {
      await _worker!;
    }
    if (persistent && _revision > 0 && unsaved) throw _safeFailure('close');
  }

  /// Stops accepting changes, drains the last accepted save and keeps errors safe.
  Future<void> close() {
    dispose();
    return _closing!;
  }
}
