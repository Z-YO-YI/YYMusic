import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../design_system/yy_player_surface.dart';

/// Shared presentation binding, not a second player or platform controller.
class ShellPlayer extends StatelessWidget {
  const ShellPlayer({
    super.key,
    required this.presenter,
    this.phone = false,
    this.compact = false,
    this.inspector = false,
  });

  final PlaybackPresenter presenter;
  final bool phone;
  final bool compact;
  final bool inspector;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: presenter,
    builder: (context, _) {
      final controls = _PlayerControls(
        // Reset gesture state when a queue entry or platform layout changes.
        key: ValueKey((presenter.entryId, phone, compact, inspector)),
        presenter: presenter,
        phone: phone,
        compact: compact,
        inspector: inspector,
      );
      if (inspector) return controls;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (presenter.errorMessage case final message?)
            YYErrorBanner(
              title: '播放暂不可用',
              message: message,
              actionLabel: '重试',
              onAction: presenter.canControl
                  ? () => unawaited(presenter.togglePlayback())
                  : null,
            ),
          controls,
        ],
      );
    },
  );
}

class _PlayerControls extends StatefulWidget {
  const _PlayerControls({
    super.key,
    required this.presenter,
    required this.phone,
    required this.compact,
    required this.inspector,
  });
  final PlaybackPresenter presenter;
  final bool phone;
  final bool compact;
  final bool inspector;
  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  double? _seekPreview;
  double? _volumePreview;

  @override
  void didUpdateWidget(_PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    // YYSlider cancels its gesture when disabled; discard our preview too.
    if (!widget.presenter.canSeek) _seekPreview = null;
    if (!widget.presenter.canChangeVolume) _volumePreview = null;
  }

  @override
  Widget build(BuildContext context) {
    final presenter = widget.presenter;
    final data = presenter.data;
    final entry = presenter.entryId;
    final preview = _seekPreview;
    final view = data.copyWith(
      position: preview == null || !presenter.canSeek
          ? data.position
          : Duration(
              microseconds: (data.duration.inMicroseconds * preview).round(),
            ),
      volume: _volumePreview ?? data.volume,
    );
    final toggle = presenter.canControl
        ? () => unawaited(presenter.togglePlayback())
        : null;
    final next = presenter.canControl
        ? () => unawaited(presenter.next())
        : null;
    final previous = presenter.canControl
        ? () => unawaited(presenter.previous())
        : null;
    final shuffle = presenter.canControl ? presenter.toggleShuffle : null;
    final repeat = presenter.canControl ? presenter.cycleRepeat : null;
    final void Function(double)? seekPreview = presenter.canSeek
        ? (value) => setState(() => _seekPreview = value)
        : null;
    final void Function(double)? seekCommit = presenter.canSeek && entry != null
        ? (value) {
            setState(() => _seekPreview = null);
            unawaited(presenter.seek(value, expectedEntryId: entry));
          }
        : null;
    void seekCancel() => setState(() => _seekPreview = null);
    if (widget.inspector) {
      return YYNowPlayingInspector(
        data: view,
        sourceLabel: presenter.sourceLabel,
        statusLabel: presenter.statusLabel,
        queueCount: presenter.queueCount,
        errorMessage: presenter.errorMessage,
        loading: presenter.busy,
        onTogglePlayback: toggle,
        onPrevious: previous,
        onNext: next,
        onToggleShuffle: shuffle,
        onCycleRepeat: repeat,
        onSeekPreview: seekPreview,
        onSeekCommit: seekCommit,
        onSeekCancel: seekCancel,
      );
    }
    if (widget.phone) {
      return YYMiniPlayer(
        data: view,
        loading: presenter.busy,
        onTogglePlayback: toggle,
        onNext: next,
      );
    }
    return YYDesktopPlayerBar(
      data: view,
      compact: widget.compact,
      loading: presenter.busy,
      onTogglePlayback: toggle,
      onNext: next,
      onPrevious: previous,
      onToggleShuffle: shuffle,
      onCycleRepeat: repeat,
      onSeekPreview: seekPreview,
      onSeekCommit: seekCommit,
      onSeekCancel: seekCancel,
      onVolumePreview: presenter.canChangeVolume
          ? (value) => setState(() => _volumePreview = value)
          : null,
      onVolumeCommit: presenter.canChangeVolume
          ? (value) {
              setState(() => _volumePreview = null);
              unawaited(presenter.setVolume(value));
            }
          : null,
      onVolumeCancel: () => setState(() => _volumePreview = null),
    );
  }
}
