import 'dart:async';

import 'package:flutter/widgets.dart';

import 'yy_theme.dart';
import 'yy_tokens.dart';

/// A small Widgets-only desktop tooltip; no Material visual defaults.
class YYTooltip extends StatefulWidget {
  const YYTooltip({
    super.key,
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 450),
    this.below = false,
  });

  final String message;
  final Widget child;
  final Duration waitDuration;
  final bool below;

  @override
  State<YYTooltip> createState() => _YYTooltipState();
}

class _YYTooltipState extends State<YYTooltip> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(widget.waitDuration, _controller.show);
  }

  void _hide() {
    _timer?.cancel();
    _controller.hide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _controller,
    overlayChildBuilder: (context) {
      final colors = YYTheme.of(context).colors;
      return CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: widget.below
            ? Alignment.bottomRight
            : Alignment.centerRight,
        followerAnchor: widget.below
            ? Alignment.topRight
            : Alignment.centerLeft,
        offset: widget.below ? const Offset(0, 8) : const Offset(8, 0),
        child: Align(
          alignment: Alignment.topLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.text,
                borderRadius: BorderRadius.circular(10),
                boxShadow: YYShadows.icon,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Text(
                  widget.message,
                  style: YYTypography.text(
                    size: 11,
                    weight: 620,
                    color: colors.elevated,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    child: CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _schedule(),
        onExit: (_) => _hide(),
        child: widget.child,
      ),
    ),
  );
}
