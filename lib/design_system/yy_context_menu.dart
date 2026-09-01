import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_icon.dart';
import 'yy_surface.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Presentation-only menu entry. Feature code owns what each id means.
@immutable
final class YYContextMenuItem {
  const YYContextMenuItem({
    required this.id,
    required this.label,
    required this.glyph,
    this.enabled = true,
    this.selected = false,
    this.loading = false,
    this.danger = false,
    this.dividerBefore = false,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final YYGlyph glyph;
  final bool enabled;
  final bool selected;
  final bool loading;
  final bool danger;
  final bool dividerBefore;
}

/// Bounded Widgets-only context menu. Positioning and visibility stay external.
class YYContextMenu extends StatefulWidget {
  const YYContextMenu({
    super.key,
    required this.items,
    this.title,
    this.meta,
    this.onSelected,
    this.onDismiss,
    this.autofocus = true,
  }) : assert(items.length > 0);

  final List<YYContextMenuItem> items;
  final String? title;
  final String? meta;
  final ValueChanged<String>? onSelected;
  final VoidCallback? onDismiss;
  final bool autofocus;

  @override
  State<YYContextMenu> createState() => _YYContextMenuState();
}

class _YYContextMenuState extends State<YYContextMenu> {
  late List<FocusNode> _focusNodes = _createFocusNodes();

  List<FocusNode> _createFocusNodes() => [
    for (final item in widget.items)
      FocusNode(debugLabel: 'YYContextMenu:${item.id}'),
  ];

  @override
  void initState() {
    super.initState();
    _scheduleInitialFocus();
  }

  @override
  void didUpdateWidget(YYContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.items.map((item) => item.id).join('\u0000');
    final newIds = widget.items.map((item) => item.id).join('\u0000');
    if (oldIds != newIds) {
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = _createFocusNodes();
      _scheduleInitialFocus();
    }
  }

  void _scheduleInitialFocus() {
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.items.indexWhere(
        (item) => item.enabled && !item.loading && widget.onSelected != null,
      );
      if (index >= 0) _focusNodes[index].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width;
    final targetWidth = viewport < 600
        ? YYOverlayMetrics.phoneContextMenuWidth
        : YYOverlayMetrics.contextMenuWidth;
    final width = math.max(0.0, math.min(targetWidth, viewport - 24));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.title == null ? '上下文菜单' : '上下文菜单，${widget.title}',
      child: SizedBox(
        width: width,
        child: YYGlassPanel(
          radius: YYRadius.contextMenu,
          padding: const EdgeInsets.all(YYOverlayMetrics.contextMenuPadding),
          blurSigma: 30,
          child: FocusScope(
            autofocus: widget.autofocus,
            child: Builder(
              builder: (menuContext) => Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.arrowDown):
                      NextFocusIntent(),
                  SingleActivator(LogicalKeyboardKey.arrowUp):
                      PreviousFocusIntent(),
                  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
                },
                child: Actions(
                  actions: {
                    NextFocusIntent: CallbackAction<NextFocusIntent>(
                      onInvoke: (_) {
                        FocusScope.of(menuContext).nextFocus();
                        return null;
                      },
                    ),
                    PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                      onInvoke: (_) {
                        FocusScope.of(menuContext).previousFocus();
                        return null;
                      },
                    ),
                    DismissIntent: CallbackAction<DismissIntent>(
                      onInvoke: (_) {
                        widget.onDismiss?.call();
                        return null;
                      },
                    ),
                  },
                  child: FocusTraversalGroup(
                    policy: WidgetOrderTraversalPolicy(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.title != null || widget.meta != null)
                          _MenuHeader(title: widget.title, meta: widget.meta),
                        for (
                          var index = 0;
                          index < widget.items.length;
                          index++
                        )
                          _MenuEntry(
                            item: widget.items[index],
                            focusNode: _focusNodes[index],
                            onSelected: widget.onSelected,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.title, required this.meta});

  final String? title;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 7),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: YYTypography.text(size: 11, weight: 700),
            ),
          if (title != null && meta != null) const SizedBox(height: 3),
          if (meta != null)
            Text(
              meta!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: YYTypography.text(
                size: 9,
                weight: 500,
                color: colors.tertiary,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuEntry extends StatelessWidget {
  const _MenuEntry({
    required this.item,
    required this.focusNode,
    required this.onSelected,
  });

  final YYContextMenuItem item;
  final FocusNode focusNode;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final action = item.enabled && !item.loading && onSelected != null
        ? () => onSelected!(item.id)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.dividerBefore)
          Container(
            key: ValueKey('context-menu-divider-${item.id}'),
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            color: YYTheme.of(context).colors.border,
          ),
        YYControlAction(
          label: item.label,
          onActivate: action,
          focusNode: focusNode,
          selected: item.selected ? true : null,
          loading: item.loading,
          inMutuallyExclusiveGroup: false,
          builder: (context, interaction) {
            final theme = YYTheme.of(context);
            final colors = theme.colors;
            final fill = interaction.pressed
                ? colors.pressed
                : item.selected
                ? Color.alphaBlend(theme.accent.soft, colors.elevated)
                : interaction.hovered
                ? colors.subtle
                : const Color(0x00000000);
            final foreground = item.danger
                ? YYPalette.error
                : item.selected
                ? theme.accent.readableOn(fill)
                : colors.text;
            return AnimatedContainer(
              key: ValueKey('context-menu-item-${item.id}'),
              duration: theme.motion(YYMotion.hover),
              curve: YYMotion.standard,
              height: YYOverlayMetrics.contextMenuItemHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: interaction.focused
                      ? theme.accent.color
                      : const Color(0x00000000),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  YYIcon(glyph: item.glyph, size: 18, color: foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: 11,
                        weight: 600,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
