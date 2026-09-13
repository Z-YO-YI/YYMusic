import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../app/playback_sleep_action.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_dialog.dart';
import '../../../design_system/yy_option_card.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../playback/playback_sleep_timer_state.dart';
import 'audio_output_section.dart';
import 'sleep_remaining_text.dart';

/// Shared native surface; its host owns insertion, barrier and route lifetime.
class SleepSettingsPanel extends StatefulWidget {
  const SleepSettingsPanel({
    super.key,
    required this.presenter,
    required this.platform,
    required this.isCurrent,
    required this.onClose,
  });
  final PlaybackPresenter presenter;
  final YYPlatform platform;
  final bool Function() isCurrent;
  final VoidCallback onClose;
  @override
  State<SleepSettingsPanel> createState() => _SleepSettingsPanelState();
}

class _SleepSettingsPanelState extends State<SleepSettingsPanel> {
  int _generation = 0;
  bool _closing = false;
  bool _surfaceActive = true;
  String? _error;

  bool _allowed(int generation) {
    if (!mounted || _closing || generation != _generation) return false;
    try {
      if (!widget.isCurrent() || !mounted || generation != _generation) {
        _generation++;
        return false;
      }
    } catch (_) {
      _generation++;
      return false;
    }
    if (!_surfaceActive || !_surfaceAllowed()) {
      _generation++;
      return false;
    }
    final box = context.findRenderObject();
    return box is RenderBox &&
        box.hasSize &&
        box.size.width > 0 &&
        box.size.height > 0;
  }

  bool _surfaceAllowed() {
    if (!(ModalRoute.isCurrentOf(context) ?? true) ||
        !TickerMode.valuesOf(context).enabled) {
      return false;
    }
    final focus = Focus.maybeOf(context);
    if (focus != null &&
        (!focus.descendantsAreFocusable ||
            focus.ancestors.any((node) => !node.descendantsAreFocusable))) {
      return false;
    }
    return true;
  }

  void _close(int generation) {
    if (!_allowed(generation)) return;
    _closing = true;
    _generation++;
    widget.onClose();
  }

  @override
  void didUpdateWidget(SleepSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presenter != widget.presenter) {
      _error = null;
      _generation++;
    }
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.presenter,
    builder: (context, _) {
      // Subscribe during build, before any click, so cover/uncover revokes.
      _surfaceActive = _surfaceAllowed();
      final generation = ++_generation;
      final presenter = widget.presenter;
      final sleep = presenter.sleepState;
      final storageFailure = presenter.sleepPersistenceFailure;
      final colors = YYTheme.of(context).colors;
      final size = MediaQuery.sizeOf(context);
      if (size.isEmpty) return const SizedBox.shrink();
      final phone =
          widget.platform == YYPlatform.android &&
          (size.width < 600 || size.height < 500);
      void close() => _close(generation);
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (presenter.audioOutput case final output?) ...[
            AudioOutputSection(
              controller: output,
              isCurrent: () => _allowed(generation),
            ),
            const SizedBox(height: 24),
          ],
          Text('睡眠定时', style: YYTypography.sectionTitle),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              _status(sleep),
              key: const ValueKey('sleep-status'),
              style: YYTypography.caption.copyWith(color: colors.secondary),
            ),
          ),
          SleepRemainingText(
            presenter: presenter,
            active: _surfaceActive && !_closing,
            isCurrent: () => _allowed(generation),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const ValueKey('sleep-action-error'),
                style: YYTypography.caption.copyWith(color: colors.secondary),
              ),
            ),
          ],
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth < 500
                  ? box.maxWidth
                  : (box.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final choice in PlaybackSleepChoice.values)
                    SizedBox(width: width, child: _card(choice, generation)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              presenter.sleepPersistenceMessage ?? '设置仅在本次启动有效；取消不会自动恢复播放。',
              key: const ValueKey('sleep-persistence-status'),
              style: YYTypography.caption.copyWith(color: colors.tertiary),
            ),
          ),
          if (storageFailure != null && presenter.canRetrySleepPersistence)
            Align(
              alignment: Alignment.centerLeft,
              child: YYButton(
                key: const ValueKey('sleep-storage-retry'),
                label: '重试',
                style: YYButtonStyle.quiet,
                onPressed: () {
                  if (_allowed(generation)) {
                    presenter.retrySleepPersistence(storageFailure);
                  }
                },
              ),
            ),
        ],
      );
      final actions = [
        YYButton(
          key: const ValueKey('sleep-done'),
          label: '完成',
          style: YYButtonStyle.primary,
          onPressed: close,
        ),
      ];
      return SafeArea(
        child: Align(
          alignment: phone ? Alignment.bottomCenter : Alignment.center,
          child: phone
              ? YYBottomSheet(
                  title: '播放设置',
                  subtitle: presenter.audioOutput == null
                      ? '睡眠定时'
                      : '音频输出与睡眠定时',
                  body: body,
                  onClose: close,
                  actions: actions,
                )
              : YYDialog(
                  title: '播放设置',
                  subtitle: presenter.audioOutput == null
                      ? '睡眠定时'
                      : '音频输出与睡眠定时',
                  body: body,
                  onClose: close,
                  actions: actions,
                ),
        ),
      );
    },
  );

  Widget _card(PlaybackSleepChoice choice, int generation) {
    final apply = widget.presenter.sleepAction(
      choice,
      isCurrent: () => _allowed(generation),
    );
    return YYOptionCard(
      key: ValueKey('sleep-${choice.name}'),
      title: _title(choice),
      help: switch (choice) {
        PlaybackSleepChoice.off => '持续播放',
        PlaybackSleepChoice.currentEntry =>
          apply == null ? '请先开始播放当前歌曲' : '当前歌曲播放完后暂停',
        _ => '时间到自动暂停',
      },
      selected: widget.presenter.selectedSleepChoice == choice,
      onPressed: apply == null
          ? null
          : () {
              if (!_allowed(generation)) return;
              final result = apply();
              if (!mounted || _closing) return;
              setState(
                () => _error = switch (result) {
                  PlaybackSleepActionResult.accepted => null,
                  PlaybackSleepActionResult.rejected => '播放状态已变化，请重新选择。',
                  PlaybackSleepActionResult.failed => '设置未完成，请重新选择。',
                },
              );
            },
    );
  }
}

String _title(PlaybackSleepChoice choice) => switch (choice) {
  PlaybackSleepChoice.off => '关闭',
  PlaybackSleepChoice.fifteen => '15 分钟',
  PlaybackSleepChoice.thirty => '30 分钟',
  PlaybackSleepChoice.sixty => '60 分钟',
  PlaybackSleepChoice.currentEntry => '本曲结束',
};

String _status(PlaybackSleepTimerState state) => switch (state.phase) {
  PlaybackSleepPhase.off => '未设置',
  PlaybackSleepPhase.armed =>
    state.entryId != null
        ? '本曲结束后暂停'
        : state.duration == null
        ? '定时已启用，到期自动暂停'
        : '已设置 ${state.duration!.duration.inMinutes} 分钟，到期自动暂停',
  PlaybackSleepPhase.pausing => '正在暂停播放…',
  PlaybackSleepPhase.expired => '睡眠定时已结束',
  PlaybackSleepPhase.failed => '睡眠定时未完成，请重新设置。',
};
