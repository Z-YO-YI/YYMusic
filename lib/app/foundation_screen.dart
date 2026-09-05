import 'package:flutter/widgets.dart';

import '../design_system/yy_button.dart';
import '../design_system/yy_icon.dart';
import '../design_system/yy_theme.dart';
import '../shared/foundation_button.dart';
import 'app_routes.dart';
import 'app_view_state.dart';

/// One reusable route envelope. These are not six implemented business pages.
class FoundationScreen extends StatefulWidget {
  const FoundationScreen({
    super.key,
    required this.route,
    required this.navigation,
    required this.viewState,
    this.showDesignGallery = false,
  });
  final AppRoute route;
  final AppNavigation navigation;
  final AppViewState viewState;
  final bool showDesignGallery;

  @override
  State<FoundationScreen> createState() => _FoundationScreenState();
}

class _FoundationScreenState extends State<FoundationScreen> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(widget.route),
    );
    _scroll.addListener(_saveOffset);
  }

  void _saveOffset() =>
      widget.viewState.saveScrollOffset(widget.route, _scroll.offset);

  @override
  void dispose() {
    _scroll.removeListener(_saveOffset);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: YYTheme.of(context).colors.base,
    child: SafeArea(
      child: SingleChildScrollView(
        key: ValueKey('screen-${widget.route.name}'),
        controller: _scroll,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.route.label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text('Phase 1 · 工程骨架', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            const Text('此处验证平台布局、导航和共用依赖。业务页面尚未实现。'),
            if (widget.route == AppRoute.settings) ...[
              const SizedBox(height: 20),
              YYButton(
                label: '开源许可',
                glyph: YYGlyph.info,
                onPressed: widget.navigation.openLicenses,
              ),
            ],
            if (widget.showDesignGallery) ...[
              const SizedBox(height: 20),
              YYButton(
                key: const ValueKey('open-design-gallery'),
                label: '设计基础预览',
                glyph: YYGlyph.palette,
                style: YYButtonStyle.primary,
                onPressed: widget.navigation.openDesignGallery,
              ),
            ],
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!widget.route.isMain)
                  FoundationButton(
                    key: const ValueKey('route-back'),
                    label: '返回',
                    onPressed: widget.navigation.back,
                  ),
                if (widget.route != AppRoute.player)
                  FoundationButton(
                    key: const ValueKey('open-player'),
                    label: '验证播放路由',
                    onPressed: widget.navigation.openPlayer,
                  ),
                if (widget.route != AppRoute.lyrics)
                  FoundationButton(
                    key: const ValueKey('open-lyrics'),
                    label: '验证歌词路由',
                    onPressed: widget.navigation.openLyrics,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('播放状态：不可用；未选择音频后端。'),
            const SizedBox(height: 12),
            const Text('曲库、在线来源及凭据存储：尚未接入。'),
            const SizedBox(height: 12),
            const Text('当前路由不触发操作系统全屏，OS Gateway 在平台阶段实现。'),
          ],
        ),
      ),
    ),
  );
}
