import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../yy_tokens.dart';

typedef YYControlInteraction = ({bool hovered, bool pressed, bool focused});

/// Shared input/semantics only; consumers own their audited visual geometry.
class YYControlAction extends StatefulWidget {
  const YYControlAction({
    super.key,
    required this.label,
    required this.onActivate,
    required this.builder,
    this.selected,
    this.toggled,
    this.loading = false,
    this.focusNode,
    this.inMutuallyExclusiveGroup = true,
  });
  final String label;
  final VoidCallback? onActivate;
  final Widget Function(BuildContext, YYControlInteraction) builder;
  final bool? selected, toggled;
  final bool loading;
  final FocusNode? focusNode;
  final bool inMutuallyExclusiveGroup;
  @override
  State<YYControlAction> createState() => _YYControlActionState();
}

class _YYControlActionState extends State<YYControlAction> {
  bool _hovered = false, _pressed = false, _focused = false, _hasFocus = false;
  bool get _enabled => widget.onActivate != null && !widget.loading;
  void _activate() {
    if (_enabled) widget.onActivate!();
  }

  @override
  void didUpdateWidget(YYControlAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    button: widget.toggled == null,
    toggled: widget.toggled,
    selected: widget.selected,
    inMutuallyExclusiveGroup:
        widget.selected != null && widget.inMutuallyExclusiveGroup,
    enabled: _enabled,
    focusable: _enabled,
    focused: _hasFocus,
    value: widget.loading ? '加载中' : null,
    excludeSemantics: true,
    onTap: _enabled ? _activate : null,
    child: FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: _enabled,
      includeFocusSemantics: false,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onFocusChange: (value) {
        setState(() => _hasFocus = value);
        if (value) {
          unawaited(Scrollable.ensureVisible(context));
        }
      },
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
        onTap: _enabled ? _activate : null,
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: YYSpace.touchTarget,
            minHeight: YYSpace.touchTarget,
          ),
          child: Opacity(
            opacity: _enabled ? 1 : .45,
            child: widget.builder(context, (
              hovered: _hovered && _enabled,
              pressed: _pressed && _enabled,
              focused: _focused && _enabled,
            )),
          ),
        ),
      ),
    ),
  );
}
