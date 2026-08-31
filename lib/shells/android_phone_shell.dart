import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import '../design_system/yy_navigation.dart';
import 'shell_chrome.dart';

class AndroidPhoneShell extends StatelessWidget {
  const AndroidPhoneShell({
    super.key,
    required this.navigation,
    required this.selected,
    required this.child,
  });
  final AppNavigation navigation;
  final AppRoute selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const SizedBox(
          height: 44,
          child: Center(child: Text('YYMusic · Android Phone')),
        ),
        Expanded(child: child),
        const FoundationPlaybackSlot(height: 64),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: YYMobileBottomNavigation(
            destinations: androidDestinations,
            selectedIndex: AppRoute.mainRoutes.indexOf(selected),
            onSelected: (index) => navigation.goTo(AppRoute.mainRoutes[index]),
          ),
        ),
      ],
    ),
  );
}
