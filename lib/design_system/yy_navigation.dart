import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_icon.dart';
import 'yy_surface.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Route-independent content; the app boundary owns IDs and navigation actions.
@immutable
class YYNavigationDestination {
  const YYNavigationDestination({
    required this.id,
    required this.label,
    required this.glyph,
  });
  final String id;
  final String label;
  final YYGlyph glyph;
}

/// The audited 3x18 leading marker, used only by rail/sidebar layouts.
class YYNavigationSelectionIndicator extends StatelessWidget {
  const YYNavigationSelectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final surface = Color.alphaBlend(theme.accent.soft, theme.colors.elevated);
    return ExcludeSemantics(
      child: Container(
        width: YYNavigationMetrics.indicatorWidth,
        height: YYNavigationMetrics.indicatorHeight,
        decoration: BoxDecoration(
          color: theme.accent.color,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(3),
          ),
          border:
              YYAccent.contrast(theme.accent.color, theme.colors.elevated) < 3
              ? Border.all(color: theme.accent.readableOn(surface), width: .75)
              : null,
        ),
      ),
    );
  }
}

/// Accessible touch/keyboard navigation; selection is controlled by the router.
class YYNavigationItem extends StatefulWidget {
  const YYNavigationItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onPressed,
    this.bottom = false,
    this.focusNode,
  });
  final YYNavigationDestination destination;
  final bool selected;
  final VoidCallback? onPressed;
  final bool bottom;
  final FocusNode? focusNode;

  @override
  State<YYNavigationItem> createState() => _YYNavigationItemState();
}

class _YYNavigationItemState extends State<YYNavigationItem> {
  bool _hovered = false, _pressed = false, _focused = false, _hasFocus = false;
  bool get _enabled => widget.onPressed != null;
  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  void didUpdateWidget(YYNavigationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final fill = widget.selected
        ? Color.alphaBlend(theme.accent.soft, colors.elevated)
        : _pressed && _enabled
        ? colors.pressed
        : _hovered && _enabled
        ? colors.subtle
        : const Color(0x00000000);
    final ink = widget.selected
        ? theme.accent.readableOn(fill)
        : colors.secondary;
    // Near-white/black custom accents must not erase the selected state.
    // Keep the user's original fill; add a readable boundary only when needed.
    final selectionOutline =
        widget.selected &&
        YYAccent.contrast(theme.accent.color, colors.elevated) < 3;
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: _enabled,
      inMutuallyExclusiveGroup: true,
      focused: _hasFocus,
      focusable: _enabled,
      label: widget.destination.label,
      excludeSemantics: true,
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: _enabled,
        includeFocusSemantics: false,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onFocusChange: (value) => setState(() => _hasFocus = value),
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
              duration: theme.motion(YYMotion.hover),
              curve: YYMotion.standard,
              constraints: const BoxConstraints(
                minHeight: YYSpace.touchTarget,
                minWidth: YYSpace.touchTarget,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(
                  widget.bottom ? 26 : YYRadius.navigation,
                ),
                border: Border.all(
                  color: _focused && _enabled
                      ? colors.text
                      : selectionOutline
                      ? ink
                      : const Color(0x00000000),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.bottom ? 4 : 2,
                      vertical: 3,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        YYIcon(
                          glyph: widget.destination.glyph,
                          size: YYNavigationMetrics.iconSize,
                          color: ink,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: YYTypography.text(
                            size: YYNavigationMetrics.labelSize,
                            weight: widget.selected ? 720 : 620,
                            height: 1.2,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.selected && !widget.bottom)
                    const Positioned(
                      left: 0,
                      child: YYNavigationSelectionIndicator(),
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

/// The phone capsule owns only layout, not route state or SafeArea insets.
class YYMobileBottomNavigation extends StatelessWidget {
  const YYMobileBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(destinations.length >= 2 && destinations.length <= 5),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);
  final List<YYNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final height = math.max(
      YYNavigationMetrics.phoneHeight,
      MediaQuery.textScalerOf(context).scale(YYNavigationMetrics.labelSize) *
              1.2 +
          44,
    );
    return YYGlassSurface(
      height: height,
      radius: YYRadius.phoneNavigation,
      padding: const EdgeInsets.all(6),
      blurSigma: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: YYNavigationItem(
                  key: ValueKey('nav-${destinations[index].id}'),
                  destination: destinations[index],
                  selected: selectedIndex == index,
                  bottom: true,
                  onPressed: () => onSelected(index),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bounded 72dp Android rail; small landscape heights remain scrollable.
class YYTabletNavigationRail extends StatelessWidget {
  const YYTabletNavigationRail({
    super.key,
    required this.height,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(height > 0),
       assert(selectedIndex >= 0 && selectedIndex < destinations.length);
  final double height;
  final List<YYNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final itemHeight = math.max(
      YYNavigationMetrics.railItemHeight,
      MediaQuery.textScalerOf(context).scale(YYNavigationMetrics.labelSize) *
              1.2 +
          36,
    );
    return SizedBox(
      width: YYNavigationMetrics.railWidth,
      child: YYGlassSurface(
        height: height,
        radius: YYRadius.panel,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        blurSigma: 34,
        child: SingleChildScrollView(
          child: Column(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height: itemHeight,
                    width: double.infinity,
                    child: YYNavigationItem(
                      key: ValueKey('nav-${destinations[index].id}'),
                      destination: destinations[index],
                      selected: selectedIndex == index,
                      onPressed: () => onSelected(index),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
