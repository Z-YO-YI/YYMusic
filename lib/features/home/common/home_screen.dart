import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_view_state.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_theme.dart';
import '../phone/phone_home_layout.dart';
import '../tablet/tablet_home_layout.dart';
import '../windows/windows_home_layout.dart';
import 'home_controller.dart';
import 'home_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.platform,
    required this.controller,
    required this.playback,
    required this.navigation,
    required this.viewState,
  });
  final YYPlatform platform;
  final HomeController controller;
  final PlaybackPresenter playback;
  final AppNavigation navigation;
  final AppViewState viewState;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scroll;
  @override
  void initState() {
    super.initState();
    _scroll = ScrollController(
      initialScrollOffset: widget.viewState.scrollOffset(AppRoute.home),
    );
    _scroll.addListener(_save);
    widget.controller.start();
  }

  void _save() =>
      widget.viewState.saveScrollOffset(AppRoute.home, _scroll.offset);
  @override
  void dispose() {
    _scroll.removeListener(_save);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: YYTheme.of(context).colors.base,
    child: ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.playback]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);
          final phone =
              widget.platform == YYPlatform.android && size.width < 600;
          final padding = phone ? 16.0 : 24.0;
          final width = (constraints.maxWidth - padding * 2).clamp(
            1.0,
            double.infinity,
          );
          final sections = HomeSections(
            controller: widget.controller,
            playback: widget.playback,
            navigation: widget.navigation,
            width: width,
          );
          return SingleChildScrollView(
            key: const ValueKey('screen-home'),
            controller: _scroll,
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('YYMusic', style: sections.titleStyle),
                    ),
                    YYIconButton(
                      label: '刷新首页',
                      glyph: sections.refreshGlyph,
                      onPressed: () {
                        unawaited(widget.controller.refreshCatalog());
                        widget.controller.retryHistory();
                        widget.controller.retrySources();
                      },
                    ),
                    const SizedBox(width: 4),
                    YYIconButton(
                      key: const ValueKey('open-design-gallery'),
                      label: '设计基础预览',
                      glyph: sections.galleryGlyph,
                      onPressed: widget.navigation.openDesignGallery,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (phone)
                  PhoneHomeLayout(sections: sections)
                else if (widget.platform == YYPlatform.android)
                  TabletHomeLayout(
                    sections: sections,
                    landscape: size.width > size.height,
                  )
                else
                  WindowsHomeLayout(sections: sections),
                const SizedBox(height: 24),
                Text(
                  '本地导入和在线来源配置仍在开发。封面暂用占位，不提供音乐下载。',
                  style: sections.captionStyle(context),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
