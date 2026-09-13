import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_theme.dart';
import '../../../design_system/yy_tokens.dart';
import '../../../platform/audio_output/audio_output_controller.dart';
import '../../../platform/contracts/audio_output_gateway.dart';

/// Read-only route observation, never a selectable simulated device list.
class AudioOutputSection extends StatefulWidget {
  const AudioOutputSection({
    super.key,
    required this.controller,
    required this.isCurrent,
  });
  final AudioOutputController controller;
  final bool Function() isCurrent;
  @override
  State<AudioOutputSection> createState() => _AudioOutputSectionState();
}

class _AudioOutputSectionState extends State<AudioOutputSection> {
  int _generation = 0;
  String? _message;

  bool _allowed(int generation) {
    if (!mounted || generation != _generation) return false;
    try {
      return widget.isCurrent() && mounted && generation == _generation;
    } catch (_) {
      return false;
    }
  }

  @override
  void didUpdateWidget(AudioOutputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _generation++;
    if (oldWidget.controller != widget.controller) _message = null;
  }

  Future<void> _open(int generation) async {
    if (!_allowed(generation) || widget.controller.openingSettings) return;
    setState(() => _message = null);
    final result = await widget.controller.openSystemSettings(
      isCurrent: () => _allowed(generation),
    );
    if (!_allowed(generation)) return;
    setState(
      () => _message = switch (result) {
        AudioOutputSettingsResult.opened => '已请求打开系统设置；返回应用后重新读取输出。',
        AudioOutputSettingsResult.unavailable => '系统设置当前不可用，请稍后重试。',
        AudioOutputSettingsResult.failed => '未能打开系统设置，请重试或从系统中手动打开。',
      },
    );
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final snapshot = controller.snapshot;
      final route = snapshot.route;
      final generation = _generation;
      final colors = YYTheme.of(context).colors;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('音频输出', style: YYTypography.sectionTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.elevated,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(YYRadius.button),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.label ?? '暂时无法确认当前输出',
                  key: const ValueKey('audio-output-label'),
                  style: YYTypography.text(
                    size: 11,
                    weight: 690,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (route.observation) {
                    AudioOutputObservation.unknown => '输出信息不可用，不代表没有连接音频设备。',
                    AudioOutputObservation.systemDefault =>
                      '系统默认输出；不保证就是播放器当前实际输出。',
                    AudioOutputObservation.playerRoute => '播放器当前实际输出。',
                  },
                  key: const ValueKey('audio-output-source'),
                  style: YYTypography.caption.copyWith(color: colors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '应用内不支持切换输出，请使用系统声音设置。',
            style: YYTypography.caption.copyWith(color: colors.tertiary),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: YYButton(
              key: const ValueKey('audio-output-settings'),
              label: controller.openingSettings ? '正在打开系统设置…' : '打开系统声音设置',
              loading: controller.openingSettings,
              onPressed: snapshot.canOpenSettings && !controller.openingSettings
                  ? () => _open(generation)
                  : null,
            ),
          ),
          if (!snapshot.canOpenSettings) ...[
            const SizedBox(height: 8),
            Text(
              '此环境无法打开系统声音设置。',
              style: YYTypography.caption.copyWith(color: colors.tertiary),
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                key: const ValueKey('audio-output-feedback'),
                style: YYTypography.caption.copyWith(color: colors.secondary),
              ),
            ),
          ],
        ],
      );
    },
  );
}
