import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_artwork_placeholder.dart';
import 'yy_button.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// A controlled track row with a separate primary and overflow action.
///
/// Tapping the overflow button never invokes [onPressed]. Playback and menu
/// state remain outside this design-system component.
class YYTrackTile extends StatefulWidget {
  const YYTrackTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sourceLabel,
    required this.durationLabel,
    required this.artwork,
    required this.onPressed,
    this.onMore,
    this.playing = false,
    this.loading = false,
    this.focusNode,
  });

  final String title;
  final String subtitle;
  final String sourceLabel;
  final String durationLabel;
  final YYArtworkKind artwork;
  final VoidCallback? onPressed;
  final VoidCallback? onMore;
  final bool playing;
  final bool loading;
  final FocusNode? focusNode;

  @override
  State<YYTrackTile> createState() => _YYTrackTileState();
}

class _YYTrackTileState extends State<YYTrackTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _hasFocus = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  void didUpdateWidget(YYTrackTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final selectedSurface = Color.alphaBlend(
      theme.accent.soft,
      colors.elevated,
    );
    final surface = widget.playing
        ? selectedSurface
        : _pressed && _enabled
        ? colors.pressed
        : _hovered && _enabled
        ? colors.subtle
        : const Color(0x00000000);
    final titleColor = widget.playing
        ? theme.accent.readableOn(selectedSurface)
        : colors.text;
    final mainLabel =
        '${widget.title}，${widget.subtitle}，${widget.sourceLabel}，${widget.durationLabel}';

    final primary = Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.playing,
      label: mainLabel,
      value: widget.loading
          ? '加载中'
          : widget.playing
          ? '正在播放'
          : null,
      onTap: _enabled ? _activate : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: _enabled,
        includeFocusSemantics: false,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onFocusChange: (value) {
          setState(() => _hasFocus = value);
          if (value) unawaited(Scrollable.ensureVisible(context));
        },
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
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: widget.loading ? .32 : 1,
                    child: YYArtworkPlaceholder(
                      kind: widget.artwork,
                      dimension: 36,
                      role: YYArtworkRole.track,
                      semanticLabel: '${widget.title} 封面占位',
                    ),
                  ),
                  if (widget.playing)
                    IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xDBFFFFFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.loading ? '正在加载曲目' : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.trackTitle.copyWith(
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.loading ? '请稍候' : widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.trackMeta.copyWith(
                        color: colors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: phone ? 72 : 120),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.subtle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    child: Text(
                      widget.sourceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.sourceChip.copyWith(
                        color: colors.tertiary,
                      ),
                    ),
                  ),
                ),
              ),
              if (!phone) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    widget.durationLabel,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: YYTypography.trackMeta.copyWith(
                      color: colors.tertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: _enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: _enabled ? 1 : .45,
        child: AnimatedScale(
          duration: theme.motion(YYMotion.press),
          curve: YYMotion.standard,
          scale: _pressed && _enabled ? .995 : 1,
          child: AnimatedContainer(
            key: const ValueKey('yy-track-tile-surface'),
            duration: theme.motion(YYMotion.press),
            curve: YYMotion.standard,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.fromLTRB(8, 7, 4, 7),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(YYRadius.trackRow),
              border: Border.all(
                color: _focused && _hasFocus
                    ? colors.text
                    : const Color(0x00000000),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: primary),
                const SizedBox(width: 2),
                YYIconButton(
                  glyph: YYGlyph.more,
                  label: '${widget.title} 的更多操作',
                  style: YYButtonStyle.quiet,
                  onPressed: _enabled ? widget.onMore : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
