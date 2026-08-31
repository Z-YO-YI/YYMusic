import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../design_system/yy_theme.dart';

/// A text-only foundation control, not the Phase 2 design-system button.
class FoundationButton extends StatefulWidget {
  const FoundationButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  State<FoundationButton> createState() => _FoundationButtonState();
}

class _FoundationButtonState extends State<FoundationButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: widget.selected,
    label: widget.label,
    onTap: widget.onPressed,
    excludeSemantics: true,
    child: FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? Color.alphaBlend(
                    YYTheme.of(context).accent.soft,
                    YYTheme.of(context).colors.elevated,
                  )
                : YYTheme.of(context).colors.elevated,
            border: Border.all(
              color: _focused
                  ? YYTheme.of(context).colors.text
                  : YYTheme.of(context).colors.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(widget.label, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}
