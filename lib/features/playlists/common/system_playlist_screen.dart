import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../app/layout_class.dart';
import '../../../app/playback_presenter.dart';
import '../../../design_system/yy_theme.dart';
import '../../../domain/models/collection_models.dart';
import '../phone/phone_system_playlist_layout.dart';
import '../tablet/tablet_system_playlist_layout.dart';
import '../windows/windows_system_playlist_layout.dart';
import 'system_playlist_controller.dart';
import 'system_playlist_sections.dart';

class SystemPlaylistScreen extends StatefulWidget {
  const SystemPlaylistScreen({
    super.key,
    required this.type,
    required this.sessions,
    required this.platform,
    required this.navigation,
    required this.playback,
    required this.frame,
  });
  final SystemPlaylistType type;
  final SystemPlaylistSessions sessions;
  final YYPlatform platform;
  final AppNavigation navigation;
  final PlaybackPresenter playback;
  final Widget Function(Widget child) frame;
  @override
  State<SystemPlaylistScreen> createState() => SystemPlaylistScreenState();
}

/// Route state is retained above replaceable platform chrome and owns no storage.
class SystemPlaylistScreenState extends State<SystemPlaylistScreen> {
  late final SystemPlaylistController controller;
  final scroll = ScrollController();
  bool _active = true;
  int _shownOffset = 0;
  int? _resetOffset;
  @override
  void initState() {
    super.initState();
    controller = widget.sessions.open(widget.type);
    controller.addListener(_changed);
    controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    _active =
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    controller.setActive(_active);
    _scheduleScroll();
  }

  void _changed() {
    final offset = controller.content?.page.offset ?? 0;
    if (controller.isCurrent && offset != _shownOffset) {
      _shownOffset = offset;
      _resetOffset = offset;
      _scheduleScroll();
    }
  }

  void _scheduleScroll() {
    final offset = _resetOffset;
    if (offset == null || !_active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _active && _resetOffset == offset && scroll.hasClients) {
        _resetOffset = null;
        scroll.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    unawaited(controller.close().catchError((Object _) {}));
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, widget.playback]),
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final sections = SystemPlaylistSections(
        controller: controller,
        navigation: widget.navigation,
        playback: widget.playback,
        canInteract: () => mounted && _active,
      );
      final content = widget.platform == YYPlatform.windows
          ? WindowsSystemPlaylistLayout(sections: sections, scroll: scroll)
          : size.width < 600
          ? PhoneSystemPlaylistLayout(sections: sections, scroll: scroll)
          : TabletSystemPlaylistLayout(
              sections: sections,
              scroll: scroll,
              landscape: size.width > size.height,
            );
      return widget.frame(
        ColoredBox(color: YYTheme.of(context).colors.base, child: content),
      );
    },
  );
}
