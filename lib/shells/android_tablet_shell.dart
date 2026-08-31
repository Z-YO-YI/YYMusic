import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import '../app/layout_class.dart';
import '../design_system/yy_navigation.dart';
import 'shell_chrome.dart';

class AndroidTabletShell extends StatelessWidget {
  const AndroidTabletShell({
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
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        SizedBox(
          height: 44,
          child: Center(
            child: Text('YYMusic · Android Tablet · ${layout.name}'),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: LayoutBuilder(
                  builder: (context, constraints) => YYTabletNavigationRail(
                    height: constraints.maxHeight,
                    destinations: androidDestinations,
                    selectedIndex: AppRoute.mainRoutes.indexOf(selected),
                    onSelected: (index) =>
                        navigation.goTo(AppRoute.mainRoutes[index]),
                  ),
                ),
              ),
              Expanded(child: child),
              if (layout == YYLayoutClass.androidTabletLandscape &&
                  MediaQuery.sizeOf(context).width >= 1200)
                const SizedBox(
                  width: 260,
                  child: Center(child: Text('平板详情结构预留')),
                ),
            ],
          ),
        ),
        const FoundationPlaybackSlot(height: 76),
      ],
    ),
  );
}
