import 'package:flutter/widgets.dart';

import 'yy_button.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

Widget yyEditingMenu(YYThemeData theme, EditableTextState state) {
  final labels = {
    ContextMenuButtonType.cut: '剪切',
    ContextMenuButtonType.copy: '复制',
    ContextMenuButtonType.paste: '粘贴',
    ContextMenuButtonType.selectAll: '全选',
  };
  return YYTheme(
    data: theme,
    child: CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: state.contextMenuAnchors.primaryAnchor,
        anchorBelow:
            state.contextMenuAnchors.secondaryAnchor ??
            state.contextMenuAnchors.primaryAnchor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colors.border),
            boxShadow: YYShadows.floating(theme.brightness),
          ),
          child: Wrap(
            children: [
              for (final item in state.contextMenuButtonItems)
                if (labels.containsKey(item.type))
                  YYButton(
                    label: labels[item.type]!,
                    onPressed: item.onPressed,
                    style: YYButtonStyle.quiet,
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Native text-editing chrome, not an application icon or a Material control.
class YYSelectionHandles extends TextSelectionControls
    with TextSelectionHandleControls {
  YYSelectionHandles(this.color);
  final Color color;
  @override
  Size getHandleSize(double textLineHeight) => const Size(22, 22);
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      const Offset(11, 0);
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => GestureDetector(
    onTap: onTap,
    child: SizedBox.square(
      dimension: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}
