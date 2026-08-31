import 'package:flutter/widgets.dart';

import '../../design_system/yy_artwork_placeholder.dart';
import '../../design_system/yy_button.dart';
import '../../design_system/yy_slider.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';

/// Explicitly local slider previews; no audio engine, timer or fake playback.
class GalleryMediaControls extends StatefulWidget {
  const GalleryMediaControls({super.key});
  @override
  State<GalleryMediaControls> createState() => _GalleryMediaControlsState();
}

class _GalleryMediaControlsState extends State<GalleryMediaControls> {
  double _preview = 42, _committed = 42, _start = 42;
  bool _disabled = false;
  String _time(double seconds) =>
      '${seconds ~/ 60}:${(seconds.round() % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final secondary = YYTypography.caption.copyWith(
      color: YYTheme.of(context).colors.secondary,
    );
    return YYSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('滑块 · 3 / 14', style: YYTypography.sectionTitle),
          const SizedBox(height: 4),
          Text('仅演示进度数值，不触发播放。横向拖动预览，松开提交；取消不提交。', style: secondary),
          const SizedBox(height: 12),
          YYSlider(
            key: const ValueKey('demo-slider'),
            label: '示例进度',
            value: _preview,
            max: 240,
            step: 1,
            semanticFormatter: _time,
            onChanged: _disabled
                ? null
                : (value) => setState(() => _preview = value),
            onChangeStart: (_) => _start = _committed,
            onChangeEnd: (value) => setState(() => _committed = value),
            onChangeCancel: () => setState(() => _preview = _start),
          ),
          Text(
            '预览 ${_time(_preview)} · 已提交 ${_time(_committed)} / 4:00',
            key: const ValueKey('demo-slider-values'),
            style: secondary,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              YYButton(
                key: const ValueKey('disable-demo-slider'),
                label: '禁用滑块',
                selected: _disabled,
                onPressed: () => setState(() {
                  _disabled = !_disabled;
                  _preview = _committed;
                }),
              ),
              YYButton(
                label: '重置示例',
                onPressed: () => setState(() {
                  _preview = _committed = 42;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('方向键微调，Home / End 到两端；支持系统无障碍增减。', style: secondary),
        ],
      ),
    );
  }
}

/// The source's seven flat CSS motifs, labelled as placeholders rather than media.
class GalleryArtworkSection extends StatelessWidget {
  const GalleryArtworkSection({super.key});

  @override
  Widget build(BuildContext context) => YYSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('几何占位 · 7', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '无封面示例，非真实专辑。保留 App.tsx 最终配色和几何；真实封面接入后优先显示。',
          style: YYTypography.caption.copyWith(
            color: YYTheme.of(context).colors.secondary,
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 140).floor().clamp(2, 4);
            final dimension =
                (constraints.maxWidth - (columns - 1) * 20) / columns;
            return Wrap(
              spacing: 20,
              runSpacing: 24,
              children: [
                for (final kind in YYArtworkKind.values)
                  SizedBox(
                    width: dimension,
                    child: Column(
                      children: [
                        YYArtworkPlaceholder(
                          kind: kind,
                          dimension: dimension,
                          semanticLabel: '${kind.name} 无封面示例',
                        ),
                        const SizedBox(height: 12),
                        Text(kind.name, style: YYTypography.caption),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
