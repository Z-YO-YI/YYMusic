import 'package:flutter/widgets.dart';

import '../features/player/common/shell_player.dart';
import '../shells/android_phone_shell.dart';
import '../shells/android_tablet_shell.dart';
import '../shells/windows_shell.dart';
import 'app_routes.dart';
import 'layout_class.dart';
import 'playback_presenter.dart';
import 'window_chrome.dart';

class AdaptiveRoot extends StatelessWidget {
  const AdaptiveRoot({
    super.key,
    required this.platform,
    required this.navigation,
    required this.selected,
    required this.child,
    this.playbackPresenter,
  });
  final YYPlatform platform;
  final AppNavigation navigation;
  final AppRoute selected;
  final Widget child;
  final PlaybackPresenter? playbackPresenter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // A transient zero-sized view is legal during minimization. No controllers
      // are disposed or replaced while there is no drawable area.
      if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
        return const SizedBox.shrink();
      }
      final layout = classifyLayout(
        platform: platform,
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      );
      final presenter = playbackPresenter;
      final player = presenter == null
          ? null
          : ShellPlayer(
              presenter: presenter,
              phone: layout == YYLayoutClass.androidPhone,
              compact:
                  layout == YYLayoutClass.windowsNarrow ||
                  layout == YYLayoutClass.androidTabletPortrait ||
                  layout == YYLayoutClass.androidTabletLandscape,
            );
      final inspector = presenter == null
          ? null
          : ShellPlayer(presenter: presenter, inspector: true);
      return switch (layout) {
        YYLayoutClass.windowsExpanded ||
        YYLayoutClass.windowsStandard ||
        YYLayoutClass.windowsNarrow => WindowsShell(
          layout: layout,
          showToolbar: !WindowFrameScope.active(context),
          navigation: navigation,
          selected: selected,
          player: player,
          inspector: inspector,
          child: child,
        ),
        YYLayoutClass.androidPhone => AndroidPhoneShell(
          navigation: navigation,
          selected: selected,
          player: player,
          child: child,
        ),
        YYLayoutClass.androidTabletPortrait ||
        YYLayoutClass.androidTabletLandscape => AndroidTabletShell(
          layout: layout,
          navigation: navigation,
          selected: selected,
          player: player,
          inspector: inspector,
          child: child,
        ),
      };
    },
  );
}
