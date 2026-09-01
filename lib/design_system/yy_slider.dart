import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_theme.dart';
import 'yy_tokens.dart';

enum YYSliderAppearance { standard, lyrics }

/// Controlled native slider. Changes are previews; only onChangeEnd commits.
/// Vertical scrolling, pointer cancellation and disabling never commit a drag.
class YYSlider extends StatefulWidget {
  const YYSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.step = .01,
    this.onChangeStart,
    this.onChangeEnd,
    this.onChangeCancel,
    this.semanticFormatter,
    this.focusNode,
    this.loading = false,
    this.appearance = YYSliderAppearance.standard,
    this.lyricsBackgroundColor = const Color(0xFF34454D),
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(step > 0 && step < double.infinity),
       assert(min > -double.infinity && max < double.infinity);
  final String label;
  final double value, min, max, step;
  final ValueChanged<double>? onChanged, onChangeStart, onChangeEnd;
  final VoidCallback? onChangeCancel;
  final String Function(double)? semanticFormatter;
  final FocusNode? focusNode;
  final bool loading;
  final YYSliderAppearance appearance;
  final Color lyricsBackgroundColor;

  @override
  State<YYSlider> createState() => _YYSliderState();
}

class _YYSliderState extends State<YYSlider> {
  final _internalFocus = FocusNode(debugLabel: 'YYSlider');
  bool _hovered = false, _focused = false, _hasFocus = false;
  double? _dragValue;
  bool get _enabled =>
      widget.onChanged != null && widget.max > widget.min && !widget.loading;
  FocusNode get _focus => widget.focusNode ?? _internalFocus;
  double get _value => _dragValue ?? widget.value;

  @override
  void didUpdateWidget(YYSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled ||
        widget.min != oldWidget.min ||
        widget.max != oldWidget.max) {
      _dragValue = null;
    }
  }

  @override
  void dispose() {
    _internalFocus.dispose();
    super.dispose();
  }

  double _normalize(double value) {
    if (value >= widget.max) return widget.max;
    if (value <= widget.min) return widget.min;
    return (widget.min +
            ((value - widget.min) / widget.step).round() * widget.step)
        .clamp(widget.min, widget.max);
  }

  String _describe(double value) =>
      widget.semanticFormatter?.call(value) ??
      '${widget.max == widget.min ? 0 : ((value - widget.min) / (widget.max - widget.min) * 100).round()}%';

  double _at(double x, double width, bool rtl) {
    final fraction =
        ((x - YYSliderMetrics.horizontalInset) /
                (width - YYSliderMetrics.horizontalInset * 2))
            .clamp(0.0, 1.0);
    return _normalize(
      widget.min + (rtl ? 1 - fraction : fraction) * (widget.max - widget.min),
    );
  }

  void _discrete(double value) {
    if (!_enabled || _dragValue != null) return;
    final next = _normalize(value);
    if (next == widget.value) return;
    _focus.requestFocus();
    widget.onChangeStart?.call(widget.value);
    widget.onChanged!(next);
    widget.onChangeEnd?.call(next);
  }

  void _start(double value) {
    if (!_enabled) return;
    _focus.requestFocus();
    setState(() => _dragValue = value);
    widget.onChangeStart?.call(widget.value);
    widget.onChanged!(value);
  }

  void _update(double value) {
    if (!_enabled || _dragValue == null || value == _dragValue) return;
    setState(() => _dragValue = value);
    widget.onChanged!(value);
  }

  void _end() {
    final value = _dragValue;
    if (value == null) return;
    setState(() => _dragValue = null);
    if (_enabled) widget.onChangeEnd?.call(value);
  }

  void _cancel() {
    if (_dragValue == null) return;
    setState(() => _dragValue = null);
    widget.onChangeCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final lyrics = widget.appearance == YYSliderAppearance.lyrics;
    final trackHeight = lyrics
        ? YYSliderMetrics.lyricsTrackHeight
        : YYSliderMetrics.trackHeight;
    final thumbDiameter = lyrics
        ? YYSliderMetrics.lyricsThumbDiameter
        : YYSliderMetrics.thumbDiameter;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final fraction = widget.max == widget.min
        ? 0.0
        : ((_value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    final canIncrease = _enabled && _value < widget.max;
    final canDecrease = _enabled && _value > widget.min;
    final increase = _normalize(_value + widget.step),
        decrease = _normalize(_value - widget.step);
    return Semantics(
      slider: true,
      enabled: _enabled,
      focusable: _enabled,
      focused: _hasFocus,
      label: widget.label,
      value: widget.loading ? '加载中' : _describe(_value),
      increasedValue: canIncrease ? _describe(increase) : null,
      decreasedValue: canDecrease ? _describe(decrease) : null,
      onIncrease: canIncrease ? () => _discrete(increase) : null,
      onDecrease: canDecrease ? () => _discrete(decrease) : null,
      excludeSemantics: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _discrete(_value + (rtl ? -widget.step : widget.step)),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _discrete(_value + (rtl ? widget.step : -widget.step)),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _discrete(_value + widget.step),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _discrete(_value - widget.step),
          const SingleActivator(LogicalKeyboardKey.home): () =>
              _discrete(widget.min),
          const SingleActivator(LogicalKeyboardKey.end): () =>
              _discrete(widget.max),
        },
        child: FocusableActionDetector(
          enabled: _enabled,
          focusNode: _focus,
          includeFocusSemantics: false,
          mouseCursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onFocusChange: (value) => setState(() => _hasFocus = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          child: SizedBox(
            height: YYSpace.touchTarget,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = math.max(
                  YYSpace.touchTarget,
                  constraints.hasBoundedWidth ? constraints.maxWidth : 200.0,
                );
                final travel = width - YYSliderMetrics.horizontalInset * 2;
                final x =
                    YYSliderMetrics.horizontalInset +
                    (rtl ? 1 - fraction : fraction) * travel;
                final thumbColor = lyrics
                    ? const Color(0xFFFFFFFF)
                    : _dragValue != null
                    ? theme.accent.pressed
                    : theme.accent.color;
                // Flutter's accepted DragGestureRecognizer also ends on a raw
                // PointerCancelEvent. Intercept it before that end can commit.
                return Listener(
                  onPointerCancel: (_) => _cancel(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _enabled
                        ? (event) =>
                              _discrete(_at(event.localPosition.dx, width, rtl))
                        : null,
                    onHorizontalDragStart: _enabled
                        ? (event) =>
                              _start(_at(event.localPosition.dx, width, rtl))
                        : null,
                    onHorizontalDragUpdate: _enabled
                        ? (event) =>
                              _update(_at(event.localPosition.dx, width, rtl))
                        : null,
                    onHorizontalDragEnd: _enabled ? (_) => _end() : null,
                    onHorizontalDragCancel: _enabled ? _cancel : null,
                    child: Opacity(
                      opacity: _enabled ? 1 : .42,
                      child: SizedBox(
                        width: width,
                        height: YYSpace.touchTarget,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: YYSliderMetrics.horizontalInset,
                              right: YYSliderMetrics.horizontalInset,
                              top: (YYSpace.touchTarget - trackHeight) / 2,
                              child: Container(
                                key: const ValueKey('slider-track'),
                                height: trackHeight,
                                decoration: BoxDecoration(
                                  color: lyrics
                                      ? const Color(0x38FFFFFF)
                                      : colors.secondaryIcon,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: rtl
                                  ? null
                                  : YYSliderMetrics.horizontalInset,
                              right: rtl
                                  ? YYSliderMetrics.horizontalInset
                                  : null,
                              width: fraction * travel,
                              top: (YYSpace.touchTarget - trackHeight) / 2,
                              child: Container(
                                height: trackHeight,
                                decoration: BoxDecoration(
                                  color: lyrics
                                      ? const Color(0xFFFFFFFF)
                                      : theme.accent.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Positioned(
                              left: x - thumbDiameter / 2,
                              top: (YYSpace.touchTarget - thumbDiameter) / 2,
                              child: AnimatedScale(
                                scale: _hovered && _enabled
                                    ? YYSliderMetrics.hoverScale
                                    : 1,
                                duration: theme.motion(
                                  YYSliderMetrics.hoverDuration,
                                ),
                                child: Container(
                                  key: const ValueKey('slider-thumb'),
                                  width: thumbDiameter,
                                  height: thumbDiameter,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: thumbColor,
                                    border: Border.all(
                                      color: lyrics
                                          ? widget.lyricsBackgroundColor
                                          : YYAccent.contrast(
                                                  thumbColor,
                                                  colors.base,
                                                ) <
                                                3
                                          ? YYAccent.foregroundFor(thumbColor)
                                          : thumbColor,
                                      width: lyrics
                                          ? YYSliderMetrics.lyricsThumbBorder
                                          : 1,
                                    ),
                                    boxShadow: [
                                      if (_focused && _enabled)
                                        BoxShadow(
                                          color: lyrics
                                              ? const Color(0xCC000000)
                                              : colors.text,
                                          spreadRadius:
                                              YYSliderMetrics.outerRing + 2,
                                        ),
                                      if (!lyrics)
                                        BoxShadow(
                                          color: colors.elevated,
                                          spreadRadius:
                                              YYSliderMetrics.outerRing,
                                        ),
                                      BoxShadow(
                                        color: lyrics
                                            ? const Color(0x38000000)
                                            : theme.accent.color.withValues(
                                                alpha: .32,
                                              ),
                                        offset: const Offset(0, 3),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
