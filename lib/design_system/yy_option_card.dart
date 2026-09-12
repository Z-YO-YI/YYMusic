import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Controlled two-line option from the composed HTML optionsOverlay.
class YYOptionCard extends StatefulWidget {
  const YYOptionCard({
    super.key,
    required this.title,
    required this.help,
    required this.onPressed,
    this.selected = false,
  });
  final String title, help;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  State<YYOptionCard> createState() => _YYOptionCardState();
}

class _YYOptionCardState extends State<YYOptionCard> {
  bool _hovered = false, _focused = false;
  void _activate() => widget.onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final enabled = widget.onPressed != null;
    final background = widget.selected
        ? Color.alphaBlend(theme.accent.soft, colors.elevated)
        : _hovered && enabled
        ? colors.subtle
        : colors.elevated;
    final foreground = widget.selected
        ? theme.accent.readableOn(background)
        : colors.text;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: '${widget.title}，${widget.help}',
      excludeSemantics: true,
      onTap: enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _activate : null,
          child: Opacity(
            opacity: enabled ? 1 : .48,
            child: AnimatedContainer(
              duration: theme.motion(YYMotion.press),
              curve: YYMotion.standard,
              constraints: const BoxConstraints(minHeight: 74),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(YYRadius.button),
                border: Border.all(
                  color: _focused && enabled
                      ? colors.text
                      : widget.selected
                      ? theme.accent.color.withValues(alpha: .28)
                      : colors.border,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: YYTypography.text(
                      size: 11,
                      weight: 690,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.help,
                    style: YYTypography.text(
                      size: 9,
                      height: 1.45,
                      color: colors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
