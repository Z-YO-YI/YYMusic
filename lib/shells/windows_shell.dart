import 'package:flutter/widgets.dart';

import '../app/app_routes.dart';
import '../app/layout_class.dart';
import '../design_system/yy_surface.dart';
import '../design_system/yy_theme.dart';
import '../design_system/yy_tokens.dart';
import '../design_system/yy_window_toolbar.dart';
import '../design_system/yy_windows_sidebar.dart';
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
    final gap = narrow
        ? YYWindowsMetrics.compactGap
        : YYWindowsMetrics.expandedGap;
    final edge = narrow ? 12.0 : 16.0;
    return ColoredBox(
      color: YYTheme.of(context).colors.base,
      child: Padding(
        padding: EdgeInsets.fromLTRB(edge, 0, edge, edge),
        child: Column(
          children: [
            const YYWindowToolbar(showWindowControls: false),
            SizedBox(height: gap),
            Expanded(
              child: Row(
                children: [
                  YYWindowsSidebar(
                    compact: narrow,
                    destinations: primaryDestinations,
                    selectedIndex: AppRoute.mainRoutes.indexOf(selected),
                    onSelected: (index) =>
                        navigation.goTo(AppRoute.mainRoutes[index]),
                    sourceLabel: '音乐源尚未接入',
                    sourceDescription: '等待 Phase 3 Repository，不使用演示在线状态。',
                  ),
                  SizedBox(width: gap),
                  Expanded(child: child),
                  if (layout == YYLayoutClass.windowsExpanded) ...[
                    SizedBox(width: gap),
                    SizedBox(
                      width: YYWindowsMetrics.inspectorWidth,
                      child: YYGlassPanel(
                        child: Center(
                          child: Text(
                            'Inspector 结构预留 · Phase 5',
                            style: YYTypography.caption.copyWith(
                              color: YYTheme.of(context).colors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: gap),
            FoundationPlaybackSlot(
              height: narrow
                  ? YYWindowsMetrics.compactPlayerHeight
                  : YYWindowsMetrics.playerHeight,
            ),
          ],
        ),
      ),
    );
  }
}
