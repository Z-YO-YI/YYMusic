import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../phone/phone_catalog_detail_layout.dart';
import '../tablet/tablet_catalog_detail_layout.dart';
import '../windows/windows_catalog_detail_layout.dart';
import 'catalog_detail_controller.dart';
import 'catalog_detail_sections.dart';
import 'catalog_detail_state.dart';

/// A route owns view state and borrows a root-registered, drainable detail session.
class CatalogDetailScreen extends StatefulWidget {
  const CatalogDetailScreen({
    super.key,
    required this.target,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
  });
  final CatalogDetailTarget target;
  final CatalogDetailSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;

  /// App-owned chrome is below route state so shell changes cannot dispose it.
  final Widget Function(Widget child) frame;
  @override
  State<CatalogDetailScreen> createState() => CatalogDetailScreenState();
}

class CatalogDetailScreenState extends State<CatalogDetailScreen> {
  late final CatalogDetailController controller;
  final _scroll = ScrollController();
  CatalogDetailTab _tab = CatalogDetailTab.tracks;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.target);
    controller.addListener(_changed);
    unawaited(controller.start());
    _revision = controller.revision;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.setActive(TickerMode.valuesOf(context).enabled);
  }

  void _changed() {
    if (_revision == controller.revision) return;
    _revision = controller.revision;
    _resetScroll();
  }

  void _resetScroll() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });
  @override
  void dispose() {
    controller.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.frame(
    ColoredBox(
      color: YYTheme.of(context).colors.base,
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, widget.playback]),
        builder: (context, _) {
          final size = MediaQuery.sizeOf(context);
          final sections = CatalogDetailSections(
            controller: controller,
            playback: widget.playback,
            navigation: widget.navigation,
            tab: _tab,
            onTab: (value) {
              setState(() => _tab = value);
              _resetScroll();
            },
          );
          return widget.platform == YYPlatform.windows
              ? WindowsCatalogDetailLayout(sections: sections, scroll: _scroll)
              : size.width < 600
              ? PhoneCatalogDetailLayout(sections: sections, scroll: _scroll)
              : TabletCatalogDetailLayout(
                  sections: sections,
                  scroll: _scroll,
                  landscape: size.width > size.height,
                );
        },
      ),
    ),
  );
}
