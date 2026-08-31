import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import '../shared/foundation_button.dart';

class ShellNavigation extends StatelessWidget {
  const ShellNavigation({
    super.key,
    required this.navigation,
    required this.selected,
    this.horizontal = false,
  });

  final AppNavigation navigation;
  final AppRoute selected;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final route in AppRoute.mainRoutes)
        Padding(
          padding: const EdgeInsets.all(4),
          child: FoundationButton(
            key: ValueKey('nav-${route.name}'),
            label: route.label,
            selected: selected == route,
            onPressed: () => navigation.goTo(route),
          ),
        ),
    ];
    return horizontal
        ? Row(children: [for (final button in buttons) Expanded(child: button)])
        : SingleChildScrollView(child: Column(children: buttons));
  }
}

class FoundationPlaybackSlot extends StatelessWidget {
  const FoundationPlaybackSlot({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: Text('播放核心未接入 · Phase 4')),
  );
}
