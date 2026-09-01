import 'package:flutter/widgets.dart';

import '../../design_system/yy_feedback.dart';
import '../../design_system/yy_icon.dart';
import '../../design_system/yy_surface.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';

/// Local-only feedback fixtures; no network, repository or loading task runs.
class GalleryStateSurfaces extends StatefulWidget {
  const GalleryStateSurfaces({super.key});

  @override
  State<GalleryStateSurfaces> createState() => _GalleryStateSurfacesState();
}

class _GalleryStateSurfacesState extends State<GalleryStateSurfaces> {
  String _status = '状态组件尚未操作';

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('状态与反馈 · Fixture', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '只验证空状态、错误提示与纯色加载骨架；不会请求网络或生成假结果。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 16),
        YYErrorBanner(
          title: '示例音乐源暂不可用',
          message: '这是静态错误 Fixture，不代表设备当前网络状态。',
          actionLabel: '重试 Fixture',
          onAction: () => setState(() => _status = 'Fixture：收到重试请求（未访问网络）'),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;
            final empty = const YYSurface(
              padding: EdgeInsets.zero,
              child: YYEmptyState(
                message: '播放队列为空。\n可在歌曲“更多”菜单中添加。',
                glyph: YYGlyph.queue,
              ),
            );
            final skeleton = YYSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('纯色加载占位', style: YYTypography.text(weight: 700)),
                  const SizedBox(height: 14),
                  const YYSkeleton(height: 16, width: 180),
                  const SizedBox(height: 10),
                  const YYSkeleton(height: 12),
                  const SizedBox(height: 8),
                  const YYSkeleton(height: 12, width: 220),
                ],
              ),
            );
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [empty, const SizedBox(height: 14), skeleton],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: empty),
                const SizedBox(width: 14),
                Expanded(child: skeleton),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          label: _status,
          child: Text(
            _status,
            key: const ValueKey('state-fixture-status'),
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
        ),
      ],
    );
  }
}
