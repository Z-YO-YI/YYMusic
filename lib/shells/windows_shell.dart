import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import '../app/layout_class.dart';
import 'shell_chrome.dart';

class WindowsShell extends StatelessWidget {
  const WindowsShell({
    super.key,
    required this.layout,
    required this.navigation,
    required this.selected,
    required this.child,
  });
  final YYLayoutClass layout;
  final AppNavigation navigation;
  final AppRoute selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final narrow = layout == YYLayoutClass.windowsNarrow;
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: Center(child: Text('YYMusic · Windows · ${layout.name}')),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: narrow ? 72 : 240,
                child: ShellNavigation(
                  navigation: navigation,
                  selected: selected,
                ),
              ),
              Expanded(child: child),
              if (layout == YYLayoutClass.windowsExpanded)
                const SizedBox(
                  width: 320,
                  child: Center(child: Text('Inspector 结构预留')),
                ),
            ],
          ),
        ),
        FoundationPlaybackSlot(height: narrow ? 76 : 88),
      ],
    );
  }
}
