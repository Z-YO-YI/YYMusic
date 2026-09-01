import 'package:flutter/widgets.dart';

import '../../app/layout_class.dart';
import '../../design_system/yy_button.dart';
import '../../design_system/yy_context_menu.dart';
import '../../design_system/yy_dialog.dart';
import '../../design_system/yy_icon.dart';
import '../../design_system/yy_theme.dart';
import '../../design_system/yy_toast.dart';
import '../../design_system/yy_tokens.dart';

/// Inline overlay fixtures. They do not insert a production Overlay or route.
class GalleryOverlayPrimitives extends StatefulWidget {
  const GalleryOverlayPrimitives({super.key, required this.platform});

  final YYPlatform platform;

  @override
  State<GalleryOverlayPrimitives> createState() =>
      _GalleryOverlayPrimitivesState();
}

class _GalleryOverlayPrimitivesState extends State<GalleryOverlayPrimitives> {
  String _status = '尚未操作 Overlay Fixture';
  String _toastMessage = 'Fixture 操作已记录';
  bool _toastVisible = true;

  static const _items = [
    YYContextMenuItem(id: 'play', label: '立即播放', glyph: YYGlyph.play),
    YYContextMenuItem(id: 'next', label: '下一首播放', glyph: YYGlyph.next),
    YYContextMenuItem(id: 'queue', label: '添加到队列', glyph: YYGlyph.listPlus),
    YYContextMenuItem(
      id: 'favorite',
      label: '添加到喜欢',
      glyph: YYGlyph.heart,
      selected: true,
      dividerBefore: true,
    ),
    YYContextMenuItem(
      id: 'playlist',
      label: '添加到歌单',
      glyph: YYGlyph.playlist,
      loading: true,
    ),
    YYContextMenuItem(
      id: 'remove',
      label: '移除示例',
      glyph: YYGlyph.trash,
      danger: true,
      enabled: false,
    ),
  ];

  void _record(String status, {bool showToast = true}) {
    setState(() {
      _status = status;
      _toastMessage = status;
      _toastVisible = showToast;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('弹层原语 · Fixture', style: YYTypography.sectionTitle),
        const SizedBox(height: 4),
        Text(
          '以内联方式验证视觉、焦点和动作；不会打开业务弹层、路由或平台菜单。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: YYContextMenu(
            title: 'A Quiet Orbit',
            meta: 'Luna Harbor · Fixture',
            items: _items,
            autofocus: false,
            onSelected: (id) => _record('Fixture：选择菜单 $id（未执行业务）'),
            onDismiss: () =>
                _record('Fixture：请求关闭菜单（未移除 Overlay）', showToast: false),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.platform == YYPlatform.windows)
          YYDialog(
            title: '播放设置',
            subtitle: '受控 Dialog Fixture，不读取设备或睡眠计时',
            autofocus: false,
            onClose: () => _record('Fixture：请求关闭 Dialog（未导航）'),
            body: _FixtureBody(platformLabel: 'Windows Dialog'),
            actions: [
              YYButton(
                label: '取消',
                onPressed: () => _record('Fixture：取消（无业务变更）'),
              ),
              YYButton(
                label: '完成',
                glyph: YYGlyph.check,
                style: YYButtonStyle.primary,
                onPressed: () => _record('Fixture：完成（未保存）'),
              ),
            ],
          )
        else
          YYBottomSheet(
            title: '添加到歌单',
            subtitle: 'Phone Bottom Sheet Fixture，不读取真实歌单',
            autofocus: false,
            onClose: () => _record('Fixture：请求关闭 Sheet（未导航）'),
            body: const _FixtureBody(platformLabel: 'Android Phone Sheet'),
            actions: [
              YYButton(
                label: '取消',
                onPressed: () => _record('Fixture：取消（无业务变更）'),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: YYButton(
                label: _toastVisible ? '隐藏 Toast Fixture' : '显示 Toast Fixture',
                glyph: YYGlyph.info,
                onPressed: () => setState(() {
                  _toastVisible = !_toastVisible;
                  _status = _toastVisible
                      ? 'Fixture：显示受控 Toast'
                      : 'Fixture：隐藏受控 Toast';
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: YYToast(message: _toastMessage, visible: _toastVisible),
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          label: _status,
          child: Text(
            _status,
            key: const ValueKey('overlay-fixture-status'),
            style: YYTypography.caption.copyWith(color: colors.secondary),
          ),
        ),
      ],
    );
  }
}

class _FixtureBody extends StatelessWidget {
  const _FixtureBody({required this.platformLabel});

  final String platformLabel;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(platformLabel, style: YYTypography.text(weight: 700)),
        const SizedBox(height: 8),
        Text(
          '这里只展示通用头部、滚动内容和操作区。真实设备、歌单、播放、保存与未保存确认均未接入。',
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
      ],
    );
  }
}
