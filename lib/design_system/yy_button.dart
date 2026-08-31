import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Visual hierarchy independent of enabled, selected and loading states.
enum YYButtonStyle { primary, secondary, quiet }

/// Native, Material-independent button with one semantic/keyboard action.
class YYButton extends StatefulWidget {
  const YYButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.style = YYButtonStyle.secondary,
    this.selected = false,
    this.loading = false,
    this.focusNode,
    this.iconOnly = false,
  }) : assert(!iconOnly || glyph != null);

  final String label;
  final VoidCallback? onPressed;
  final YYGlyph? glyph;
  final YYButtonStyle style;
  final bool selected;
  final bool loading;
  final FocusNode? focusNode;
  final bool iconOnly;

  @override
  State<YYButton> createState() => _YYButtonState();
}

class _YYButtonState extends State<YYButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  void didUpdateWidget(YYButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final palette = theme.colors;
    final primary = widget.style == YYButtonStyle.primary;
    final quiet = widget.style == YYButtonStyle.quiet;
    final pressed = _pressed && _enabled;
    final hovered = _hovered && _enabled;
    final Color background;
    if (primary) {
      background = pressed ? theme.accent.pressed : theme.accent.color;
    } else if (widget.selected) {
      background = Color.alphaBlend(theme.accent.soft, palette.elevated);
    } else {
      background = pressed
          ? palette.pressed
          : hovered
          ? palette.subtle
          : palette.elevated;
    }
    final foreground = primary
        ? YYAccent.foregroundFor(background)
        : widget.selected
        ? theme.accent.readableOn(background)
        : palette.text;
    final border = _focused && _enabled
        ? palette.text
        : primary || (quiet && !hovered && !pressed && !widget.selected)
        ? const Color(0x00000000)
        : palette.border;
    final radius = widget.iconOnly ? YYRadius.iconButton : YYRadius.button;
    final content = widget.iconOnly
        ? YYIcon(glyph: widget.glyph!, color: foreground)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.glyph != null) ...[
                YYIcon(glyph: widget.glyph!, color: foreground, size: 18),
                const SizedBox(width: YYSpace.sm),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: YYTypography.button.copyWith(color: foreground),
                ),
              ),
            ],
          );
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.label,
      value: widget.loading ? '加载中' : null,
      onTap: _enabled ? _activate : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
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
          onTap: _enabled ? _activate : null,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: Opacity(
            opacity: _enabled ? 1 : .48,
            child: AnimatedContainer(
              duration: theme.motion(YYMotion.press),
              curve: YYMotion.standard,
              constraints: const BoxConstraints(
                minWidth: YYSpace.touchTarget,
                minHeight: YYSpace.touchTarget,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.iconOnly ? 11 : 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: quiet && !hovered && !pressed && !widget.selected
                    ? null
                    : background,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: border, width: 1.5),
                boxShadow: !_enabled || quiet
                    ? null
                    : primary
                    ? YYShadows.primary(theme.accent.color, hovered: hovered)
                    : YYShadows.icon,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon-only button that always requires an accessible action label.
class YYIconButton extends StatelessWidget {
  const YYIconButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.style = YYButtonStyle.secondary,
  });
  final YYGlyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final YYButtonStyle style;

  @override
  Widget build(BuildContext context) => YYButton(
    label: label,
    glyph: glyph,
    onPressed: onPressed,
    selected: selected,
    style: style,
    iconOnly: true,
  );
}
