import 'package:flutter/widgets.dart';

import '../../design_system/yy_theme.dart';
import '../../design_system/yy_tokens.dart';
import '../../design_system/yy_window_toolbar.dart';
import '../../design_system/yy_windows_sidebar.dart';
import '../../shells/shell_chrome.dart';

/// Explicit Windows chrome fixtures; callbacks never call operating-system APIs.
class GalleryWindowsChrome extends StatefulWidget {
  const GalleryWindowsChrome({super.key});

  @override
  State<GalleryWindowsChrome> createState() => _GalleryWindowsChromeState();
}

class _GalleryWindowsChromeState extends State<GalleryWindowsChrome> {
  int _selected = 0;
  String _status = '尚未操作 Windows Fixture';

  void _setStatus(String value) => setState(() => _status = value);

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Windows Chrome · Fixture', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '仅验证 Toolbar 与 Sidebar 视觉/动作；不会操作真实窗口、来源或账户。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 16),
        YYWindowToolbar(
          onMinimize: () => _setStatus('Fixture：请求最小化（未调用系统）'),
          onToggleMaximize: () => _setStatus('Fixture：请求最大化（未调用系统）'),
          onClose: () => _setStatus('Fixture：请求关闭（未调用系统）'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 500,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              YYWindowsSidebar(
                compact: false,
                destinations: primaryDestinations,
                selectedIndex: _selected,
                onSelected: (index) => setState(() {
                  _selected = index;
                  _status = 'Fixture：选择 ${primaryDestinations[index].label}';
                }),
                sourceLabel: 'Fixture：音乐源在线',
                sourceDescription: '仅视觉状态，不读取真实来源或凭据。',
                sourceConnected: true,
                onManageSources: () => _setStatus('Fixture：管理音乐源未接入'),
                onAccountMore: () => _setStatus('Fixture：账户菜单未接入'),
              ),
              const SizedBox(width: 16),
              YYWindowsSidebar(
                compact: true,
                destinations: primaryDestinations,
                selectedIndex: _selected,
                onSelected: (index) => setState(() {
                  _selected = index;
                  _status =
                      'Fixture：紧凑导航选择 ${primaryDestinations[index].label}';
                }),
                sourceLabel: 'Fixture：隐藏来源',
                sourceDescription: '紧凑模式不展示。',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          label: _status,
          child: Text(
            _status,
            key: const ValueKey('windows-fixture-status'),
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
        ),
      ],
    );
  }
}
