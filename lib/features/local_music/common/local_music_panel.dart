import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../phone/phone_local_music_layout.dart';
import '../tablet/tablet_local_music_layout.dart';
import '../windows/windows_local_music_layout.dart';
import 'local_music_controller.dart';
import 'local_music_sections.dart';

/// Retains root state across layout changes; never scans or owns a repository.
class LocalMusicPanel extends StatefulWidget {
  const LocalMusicPanel({
    super.key,
    required this.controller,
    required this.platform,
    this.enabled = true,
  });
  final LocalMusicController controller;
  final YYPlatform platform;
  final bool enabled;
  @override
  State<LocalMusicPanel> createState() => _LocalMusicPanelState();
}

class _LocalMusicPanelState extends State<LocalMusicPanel> {
  bool _active = false;
  @override
  void initState() {
    super.initState();
    widget.controller.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LocalMusicPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setActive(false);
      widget.controller.start();
    }
    _sync();
  }

  void _sync() {
    final size = MediaQuery.sizeOf(context);
    _active =
        widget.enabled &&
        size.width > 0 &&
        size.height > 0 &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    widget.controller.setActive(_active);
  }

  @override
  void dispose() {
    widget.controller.setActive(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final size = MediaQuery.sizeOf(context);
      final sections = LocalMusicSections(
        controller: widget.controller,
        canInteract: () => mounted && _active && widget.enabled,
      );
      return widget.platform == YYPlatform.windows
          ? WindowsLocalMusicLayout(sections: sections)
          : size.width < 600
          ? PhoneLocalMusicLayout(sections: sections)
          : TabletLocalMusicLayout(
              sections: sections,
              landscape: size.width > size.height,
            );
    },
  );
}
