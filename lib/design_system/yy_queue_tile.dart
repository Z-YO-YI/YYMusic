import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'src/yy_control_action.dart';
import 'yy_artwork_placeholder.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

enum YYQueueTileDensity { standard, immersive }

/// Controlled queue row. It never reorders, removes, persists or starts audio.
class YYQueueTile extends StatefulWidget {
  const YYQueueTile({
    super.key,
    required this.title,
    required this.meta,
    required this.durationLabel,
    required this.artwork,
    required this.onPressed,
    this.onMoveUp,
    this.onMoveDown,
    this.onRemove,
    this.current = false,
    this.loading = false,
    this.density = YYQueueTileDensity.standard,
    this.focusNode,
  });

  final String title;
  final String meta;
  final String durationLabel;
  final YYArtworkKind artwork;
  final VoidCallback? onPressed;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onRemove;
  final bool current;
  final bool loading;
  final YYQueueTileDensity density;
  final FocusNode? focusNode;

  @override
  State<YYQueueTile> createState() => _YYQueueTileState();
}

class _YYQueueTileState extends State<YYQueueTile> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _hasMainFocus = false;
  int _focusedActions = 0;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  void _actionFocusChanged(bool focused) {
    setState(() => _focusedActions += focused ? 1 : -1);
  }

  @override
  void didUpdateWidget(YYQueueTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context);
    final colors = theme.colors;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final immersive = widget.density == YYQueueTileDensity.immersive;
    final selectedSurface = Color.alphaBlend(
      theme.accent.soft,
      colors.elevated,
    );
    final surface = widget.current
        ? selectedSurface
        : _pressed && _enabled
        ? colors.pressed
        : _hovered && _enabled
        ? colors.subtle
        : const Color(0x00000000);
    final titleColor = widget.current
        ? theme.accent.readableOn(selectedSurface)
        : colors.text;
    final actionsVisible =
        phone || _hovered || _hasMainFocus || _focusedActions > 0;
    final artworkDimension = immersive
        ? YYQueueLyricsMetrics.queueImmersiveArtwork
        : YYQueueLyricsMetrics.queueArtwork;
    final mainLabel = '${widget.title}，${widget.meta}，${widget.durationLabel}';

    final primary = Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      selected: widget.current,
      inMutuallyExclusiveGroup: false,
      label: mainLabel,
      value: widget.loading
          ? '加载中'
          : widget.current
          ? '当前队列项'
          : null,
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
          setState(() => _hasMainFocus = value);
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
              Opacity(
                opacity: widget.loading ? .32 : 1,
                child: YYArtworkPlaceholder(
                  kind: widget.artwork,
                  dimension: artworkDimension,
                  role: YYArtworkRole.queue,
                  semanticLabel: '${widget.title} 封面占位',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.loading ? '正在加载队列项' : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: immersive ? 12 : 11,
                        weight: 660,
                        height: 1.25,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.loading ? '请稍候' : widget.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: immersive ? 10 : 9,
                        weight: 500,
                        height: 1.3,
                        color: colors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget action(
      YYGlyph glyph,
      String label,
      VoidCallback? callback, {
      bool danger = false,
    }) => Focus(
      onFocusChange: _actionFocusChanged,
      child: _QueueMiniAction(
        glyph: glyph,
        label: '${widget.title}：$label',
        danger: danger,
        loading: widget.loading,
        onPressed: _enabled ? callback : null,
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
            key: const ValueKey('yy-queue-tile-surface'),
            duration: theme.motion(YYMotion.press),
            curve: YYMotion.standard,
            constraints: BoxConstraints(
              minHeight: immersive
                  ? YYQueueLyricsMetrics.queueImmersiveMinHeight
                  : YYQueueLyricsMetrics.queueMinHeight,
            ),
            padding: EdgeInsets.all(
              immersive
                  ? YYQueueLyricsMetrics.queueImmersivePadding
                  : YYQueueLyricsMetrics.queuePadding,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused && _hasMainFocus
                    ? colors.text
                    : const Color(0x00000000),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(child: primary),
                const SizedBox(width: 4),
                AnimatedOpacity(
                  key: const ValueKey('yy-queue-actions'),
                  alwaysIncludeSemantics: true,
                  duration: theme.motion(const Duration(milliseconds: 120)),
                  opacity: actionsVisible ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !actionsVisible && !phone,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        action(YYGlyph.up, '上移', widget.onMoveUp),
                        action(YYGlyph.down, '下移', widget.onMoveDown),
                        action(
                          YYGlyph.close,
                          '移除',
                          widget.onRemove,
                          danger: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 42,
                  child: Text(
                    widget.durationLabel,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: YYTypography.queueMeta.copyWith(
                      color: colors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QueueMiniAction extends StatelessWidget {
  const _QueueMiniAction({
    required this.glyph,
    required this.label,
    required this.onPressed,
    required this.loading,
    required this.danger,
  });

  final YYGlyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) => YYControlAction(
    label: label,
    onActivate: onPressed,
    loading: loading,
    builder: (context, interaction) {
      final theme = YYTheme.of(context);
      final colors = theme.colors;
      final fill = interaction.pressed
          ? colors.pressed
          : interaction.hovered || interaction.focused
          ? colors.subtle
          : const Color(0x00000000);
      final foreground = danger && (interaction.hovered || interaction.focused)
          ? YYPalette.error
          : colors.secondaryIcon;
      return SizedBox.square(
        dimension: YYSpace.touchTarget,
        child: Center(
          child: AnimatedContainer(
            duration: theme.motion(YYMotion.press),
            key: ValueKey('queue-action-${glyph.assetName}'),
            width: YYQueueLyricsMetrics.queueActionVisual,
            height: YYQueueLyricsMetrics.queueActionVisual,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: interaction.focused
                    ? colors.text
                    : const Color(0x00000000),
              ),
            ),
            child: Center(
              child: YYIcon(glyph: glyph, size: 15, color: foreground),
            ),
          ),
        ),
      );
    },
  );
}
