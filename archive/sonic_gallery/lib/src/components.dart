import 'dart:ui';

import 'package:flutter/material.dart';

import 'icons.dart';
import 'models.dart';
import 'theme.dart';

typedef SgStateBuilder = Widget Function(
  BuildContext context,
  bool hovered,
  bool focused,
  bool pressed,
);

class SgPressable extends StatefulWidget {
  const SgPressable({
    super.key,
    required this.builder,
    this.onPressed,
    this.onSecondaryTap,
    this.semanticLabel,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(SgRadius.button)),
  });

  final SgStateBuilder builder;
  final VoidCallback? onPressed;
  final VoidCallback? onSecondaryTap;
  final String? semanticLabel;
  final bool enabled;
  final BorderRadius borderRadius;

  @override
  State<SgPressable> createState() => _SgPressableState();
}

class _SgPressableState extends State<SgPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(context, _hovered, _focused, _pressed);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: FocusableActionDetector(
          enabled: widget.enabled,
          onFocusChange: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? widget.onPressed : null,
            onSecondaryTap:
                widget.enabled ? widget.onSecondaryTap : null,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            child: AnimatedScale(
              scale: _pressed ? .97 : 1,
              duration: SgDuration.press,
              curve: Curves.easeOutCubic,
              child: ClipRRect(borderRadius: widget.borderRadius, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class SgIconButton extends StatelessWidget {
  const SgIconButton({
    super.key,
    required this.glyph,
    this.onPressed,
    this.tooltip,
    this.size = 44,
    this.iconSize = 21,
    this.selected = false,
    this.filled = false,
  });

  final SgGlyph glyph;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool selected;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      enabled: onPressed != null,
      semanticLabel: tooltip,
      borderRadius: BorderRadius.circular(SgRadius.icon),
      builder: (context, hovered, focused, pressed) {
        final background = selected
            ? p.accentSoft
            : hovered || focused
                ? p.surfaceSecondary
                : p.surface.withValues(alpha: 0);
        final foreground = selected ? p.accent : p.textPrimary;
        return AnimatedContainer(
          duration: SgDuration.hover,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(SgRadius.icon),
            border: focused ? Border.all(color: p.accent, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: SgIcon(
            glyph,
            size: iconSize,
            color: onPressed == null ? p.textTertiary : foreground,
            filled: filled || selected,
          ),
        );
      },
    );
  }
}

enum SgButtonKind { primary, secondary, text }

class SgButton extends StatelessWidget {
  const SgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.glyph,
    this.kind = SgButtonKind.primary,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SgGlyph? glyph;
  final SgButtonKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      enabled: onPressed != null,
      semanticLabel: label,
      builder: (context, hovered, focused, pressed) {
        Color background;
        Color foreground;
        Border? border;
        switch (kind) {
          case SgButtonKind.primary:
            background = pressed ? p.accentPressed : p.accent;
            foreground = p.surface;
            break;
          case SgButtonKind.secondary:
            background = hovered ? p.surfaceTertiary : p.surfaceSecondary;
            foreground = p.textPrimary;
            border = Border.all(color: p.divider);
            break;
          case SgButtonKind.text:
            background = hovered
                ? p.surfaceSecondary
                : p.surface.withValues(alpha: 0);
            foreground = p.textPrimary;
            break;
        }
        if (onPressed == null) {
          background = p.surfaceSecondary;
          foreground = p.textTertiary;
        }
        return AnimatedContainer(
          duration: SgDuration.hover,
          constraints: BoxConstraints(minHeight: compact ? 40 : 48),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? SgSpace.x4 : SgSpace.x5,
            vertical: compact ? SgSpace.x2 : SgSpace.x3,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(SgRadius.button),
            border: focused ? Border.all(color: p.accent, width: 2) : border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (glyph != null) ...[
                SgIcon(glyph!, size: 18, color: foreground),
                const SizedBox(width: SgSpace.x2),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SgGlassPanel extends StatelessWidget {
  const SgGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = SgRadius.glass,
    this.padding,
    this.reduceTransparency = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool reduceTransparency;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final decoration = BoxDecoration(
      color: reduceTransparency ? p.surface : p.glass,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: p.glassBorder),
      boxShadow: [
        BoxShadow(
          color: p.shadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
    if (reduceTransparency) return content;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: content,
      ),
    );
  }
}

class SgAlbumArt extends StatelessWidget {
  const SgAlbumArt({
    super.key,
    required this.index,
    required this.size,
    this.radius = SgRadius.cover,
  });

  final int index;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final col = index % 3;
    final row = (index ~/ 3).clamp(0, 1).toInt();
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size * 3,
              maxWidth: size * 3,
              minHeight: size * 3,
              maxHeight: size * 3,
              child: Transform.translate(
                offset: Offset(-col * size, -(row * 1.5 + .25) * size),
                child: Image.asset(
                  'assets/images/album_atlas.png',
                  width: size * 3,
                  height: size * 3,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: (size * 6).round(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SgSectionHeader extends StatelessWidget {
  const SgSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: SgSpace.x1),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (action != null)
          SgPressable(
            onPressed: onAction,
            semanticLabel: action,
            builder: (context, hovered, focused, pressed) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SgSpace.x2,
                vertical: SgSpace.x2,
              ),
              child: Text(
                action!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hovered ? p.accent : p.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class SgAlbumCard extends StatelessWidget {
  const SgAlbumCard({
    super.key,
    required this.album,
    required this.width,
    this.onPressed,
  });

  final Album album;
  final double width;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: width,
      child: SgPressable(
        onPressed: onPressed,
        semanticLabel: '${album.title} · ${album.artist}',
        builder: (context, hovered, focused, pressed) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AnimatedContainer(
                  duration: SgDuration.hover,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(SgRadius.cover),
                    boxShadow: hovered
                        ? [
                            BoxShadow(
                              color: p.shadow,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                    border: focused
                        ? Border.all(color: p.accent, width: 2)
                        : null,
                  ),
                  child: SgAlbumArt(index: album.atlasIndex, size: width),
                ),
                if (hovered)
                  Positioned(
                    right: SgSpace.x3,
                    bottom: SgSpace.x3,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SgIcon(SgGlyph.play, size: 16, color: p.surface),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SgSpace.x3),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class SgTag extends StatelessWidget {
  const SgTag(
    this.label, {
    super.key,
    this.accent = false,
    this.success = false,
  });

  final String label;
  final bool accent;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = success
        ? p.success
        : accent
            ? p.accent
            : p.textSecondary;
    final background = success
        ? p.success.withValues(alpha: .12)
        : accent
            ? p.accentSoft
            : p.surfaceSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class SgTrackRow extends StatelessWidget {
  const SgTrackRow({
    super.key,
    required this.track,
    this.index,
    this.desktop = false,
    this.onPressed,
    this.onMore,
  });

  final Track track;
  final int? index;
  final bool desktop;
  final VoidCallback? onPressed;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      onSecondaryTap: onMore,
      semanticLabel: '${track.title} · ${track.artist}',
      builder: (context, hovered, focused, pressed) {
        final textStyle = Theme.of(context).textTheme.bodyMedium;
        return AnimatedContainer(
          duration: SgDuration.hover,
          height: desktop ? 58 : 68,
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? SgSpace.x3 : 0,
            vertical: SgSpace.x2,
          ),
          decoration: BoxDecoration(
            color: hovered ? p.surfaceSecondary : p.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(SgRadius.input),
            border: focused ? Border.all(color: p.accent, width: 2) : null,
          ),
          child: Row(
            children: [
              if (desktop && index != null)
                SizedBox(
                  width: 34,
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: textStyle?.copyWith(color: p.textTertiary),
                  ),
                ),
              SgAlbumArt(index: track.atlasIndex, size: desktop ? 40 : 52),
              const SizedBox(width: SgSpace.x3),
              Expanded(
                flex: desktop ? 3 : 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
              if (desktop) ...[
                Expanded(
                  flex: 2,
                  child: Text(track.album, style: textStyle),
                ),
                SizedBox(
                  width: 110,
                  child: Text(track.source, style: textStyle),
                ),
              ],
              SgTag(track.quality),
              if (desktop) ...[
                const SizedBox(width: SgSpace.x5),
                SizedBox(
                  width: 48,
                  child: Text(track.duration, style: textStyle),
                ),
              ],
              SgIconButton(
                glyph: SgGlyph.more,
                onPressed: onMore,
                tooltip: '更多操作',
                size: 40,
                iconSize: 18,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SgProgressBar extends StatelessWidget {
  const SgProgressBar({
    super.key,
    required this.value,
    this.height = 4,
    this.onChanged,
  });

  final double value;
  final double height;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      slider: true,
      value: '${(value * 100).round()}%',
      child: MouseRegion(
        cursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onChanged == null
              ? null
              : (details) {
                  final box = context.findRenderObject() as RenderBox;
                  onChanged!((details.localPosition.dx / box.size.width)
                      .clamp(0, 1)
                      .toDouble());
                },
          onHorizontalDragUpdate: onChanged == null
              ? null
              : (details) {
                  final box = context.findRenderObject() as RenderBox;
                  onChanged!((details.localPosition.dx / box.size.width)
                      .clamp(0, 1)
                      .toDouble());
                },
          child: SizedBox(
            height: 18,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(height),
                child: Stack(
                  children: [
                    Container(height: height, color: p.surfaceTertiary),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0, 1).toDouble(),
                      child: Container(height: height, color: p.accent),
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

class SgSegmentedControl extends StatelessWidget {
  const SgSegmentedControl({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.surfaceSecondary,
        borderRadius: BorderRadius.circular(SgRadius.input),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final active = index == selected;
          return Flexible(
            child: SgPressable(
              onPressed: () => onChanged(index),
              semanticLabel: items[index],
              borderRadius: BorderRadius.circular(9),
              builder: (context, hovered, focused, pressed) => AnimatedContainer(
                duration: SgDuration.page,
                constraints: const BoxConstraints(minHeight: 38),
                padding: const EdgeInsets.symmetric(horizontal: SgSpace.x4),
                decoration: BoxDecoration(
                  color: active
                      ? p.surface
                      : hovered
                          ? p.surfaceTertiary
                          : p.surface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(9),
                  border: focused ? Border.all(color: p.accent, width: 2) : null,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : const [],
                ),
                alignment: Alignment.center,
                child: Text(
                  items[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: active ? p.textPrimary : p.textSecondary,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class SgSearchField extends StatefulWidget {
  const SgSearchField({
    super.key,
    this.initialValue = '',
    this.hint = '搜索歌曲、专辑、艺术家',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String initialValue;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<SgSearchField> createState() => _SgSearchFieldState();
}

class _SgSearchFieldState extends State<SgSearchField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: SgDuration.hover,
      height: 48,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(SgRadius.input),
        border: Border.all(
          color: _focused ? p.accent : p.divider,
          width: _focused ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: SgSpace.x4),
          SgIcon(SgGlyph.search, size: 20, color: p.textSecondary),
          const SizedBox(width: SgSpace.x3),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              cursorColor: p.accent,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: p.textTertiary),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            SgIconButton(
              glyph: SgGlyph.close,
              onPressed: () {
                _controller.clear();
                widget.onChanged?.call('');
                setState(() {});
              },
              tooltip: '清除',
              size: 40,
              iconSize: 16,
            ),
          const SizedBox(width: SgSpace.x1),
        ],
      ),
    );
  }
}

class SgSourceSelector extends StatelessWidget {
  const SgSourceSelector({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SgPressable(
      onPressed: onPressed,
      semanticLabel: '音乐来源：$label',
      builder: (context, hovered, focused, pressed) => AnimatedContainer(
        duration: SgDuration.hover,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: SgSpace.x3),
        decoration: BoxDecoration(
          color: hovered ? p.surfaceTertiary : p.surfaceSecondary,
          borderRadius: BorderRadius.circular(SgRadius.button),
          border: focused ? Border.all(color: p.accent, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
            ),
            const SizedBox(width: SgSpace.x2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: SgSpace.x2),
            SgIcon(SgGlyph.arrowDown, size: 14, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

class SgToggle extends StatelessWidget {
  const SgToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: SgSpace.x3),
        ],
        SgPressable(
          onPressed: () => onChanged(!value),
          semanticLabel: label,
          borderRadius: BorderRadius.circular(11),
          builder: (context, hovered, focused, pressed) => AnimatedContainer(
            duration: SgDuration.press,
            width: 42,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? p.accent : p.surfaceTertiary,
              borderRadius: BorderRadius.circular(12),
              border: focused ? Border.all(color: p.accent, width: 2) : null,
            ),
            child: AnimatedAlign(
              duration: SgDuration.press,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? p.surface : p.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
