import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Controlled switch: 46x28 visual track, 22 thumb, >=44 touch target.
class YYToggle extends StatelessWidget {
  const YYToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.loading = false,
    this.focusNode,
  });
  final String label;
  final bool value, loading;
  final ValueChanged<bool>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final fill = value ? theme.accent.color : theme.colors.pressed;
    final boundary =
        value && YYAccent.contrast(fill, theme.colors.elevated) < 3;
    return YYControlAction(
      label: label,
      toggled: value,
      loading: loading,
      focusNode: focusNode,
      onActivate: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, state) => Center(
        widthFactor: 1,
        heightFactor: 1,
        child: AnimatedScale(
          scale: state.pressed ? .98 : 1,
          duration: theme.motion(YYMotion.press),
          child: AnimatedContainer(
            key: const ValueKey('toggle-track'),
            duration: theme.motion(const Duration(milliseconds: 160)),
            curve: YYMotion.standard,
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (state.focused || boundary)
                  BoxShadow(
                    color: theme.colors.text,
                    spreadRadius: state.focused ? 3 : 1,
                  ),
                if (state.hovered && !state.focused && !boundary)
                  BoxShadow(color: theme.colors.strongBorder, spreadRadius: 1),
              ],
            ),
            child: AnimatedAlign(
              duration: theme.motion(const Duration(milliseconds: 180)),
              curve: YYMotion.enter,
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                key: const ValueKey('toggle-thumb'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  shape: BoxShape.circle,
                  border: boundary
                      ? Border.all(color: theme.accent.readableOn(fill))
                      : null,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
