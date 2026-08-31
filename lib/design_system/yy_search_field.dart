import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_button.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Native editing only: the caller owns text, query scheduling and real results.
class YYSearchField extends StatefulWidget {
  const YYSearchField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder = '搜索歌曲、专辑或歌手',
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.loading = false,
    this.errorText,
  });
  final TextEditingController controller;
  final String label, placeholder;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FocusNode? focusNode;
  final bool enabled, loading;
  final String? errorText;
  @override
  State<YYSearchField> createState() => _YYSearchFieldState();
}

class _YYSearchFieldState extends State<YYSearchField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final _ownedFocus = FocusNode(debugLabel: 'YYSearchField');
  bool _hovered = false;
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);
  FocusNode get _focus => widget.focusNode ?? _ownedFocus;
  bool get _interactive => widget.enabled && !widget.loading;
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => _interactive;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(YYSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocus).removeListener(_refresh);
      _focus.addListener(_refresh);
    }
    if (!_interactive && _focus.hasFocus) _focus.unfocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _ownedFocus.dispose();
    super.dispose();
  }

  void _clear() {
    if (!_interactive || widget.controller.text.isEmpty) return;
    editableTextKey.currentState?.hideToolbar();
    widget.controller.clear();
    widget.onChanged?.call('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context), colors = YYTheme.of(context).colors;
    final phone = MediaQuery.sizeOf(context).width < 600;
    final height = math.max(
      phone ? 52.0 : 58.0,
      MediaQuery.textScalerOf(context).scale(15) * 1.45 + 24,
    );
    final ink = colors.text;
    final error = widget.errorText;
    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: _interactive
                ? SystemMouseCursors.text
                : SystemMouseCursors.basic,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _interactive
                  ? () => editableTextKey.currentState?.requestKeyboard()
                  : null,
              child: AnimatedContainer(
                key: const ValueKey('search-surface'),
                duration: theme.motion(YYMotion.hover),
                height: height,
                padding: const EdgeInsetsDirectional.only(start: 16, end: 6),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(phone ? 18 : 20),
                  border: Border.all(
                    color: _focus.hasFocus
                        ? ink
                        : error != null
                        ? YYPalette.error
                        : _hovered && _interactive
                        ? colors.strongBorder
                        : colors.border,
                    width: _focus.hasFocus ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(
                        theme.brightness == Brightness.dark
                            ? 0x3D000000
                            : 0x140F1214,
                      ),
                      offset: Offset(
                        0,
                        theme.brightness == Brightness.dark ? 10 : 8,
                      ),
                      blurRadius: theme.brightness == Brightness.dark ? 28 : 24,
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: _interactive ? 1 : .5,
                  child: Row(
                    children: [
                      YYIcon(
                        glyph: YYGlyph.search,
                        size: 20,
                        color: colors.secondaryIcon,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Semantics(
                          label: widget.label,
                          hint:
                              error ??
                              (widget.loading ? '加载中' : widget.placeholder),
                          enabled: _interactive,
                          child: ExcludeFocus(
                            excluding: !_interactive,
                            child: IgnorePointer(
                              ignoring: !_interactive,
                              child: _gestures.buildGestureDetector(
                                behavior: HitTestBehavior.translucent,
                                child: Stack(
                                  alignment: AlignmentDirectional.centerStart,
                                  children: [
                                    if (widget.controller.text.isEmpty)
                                      ExcludeSemantics(
                                        child: Text(
                                          widget.placeholder,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: YYTypography.text(
                                            size: 15,
                                            weight: 460,
                                            color: colors.secondary,
                                          ),
                                        ),
                                      ),
                                    EditableText(
                                      key: editableTextKey,
                                      controller: widget.controller,
                                      focusNode: _focus,
                                      readOnly: !_interactive,
                                      rendererIgnoresPointer: true,
                                      enableInteractiveSelection: _interactive,
                                      style: YYTypography.text(
                                        size: 15,
                                        weight: 460,
                                        color: ink,
                                      ),
                                      cursorColor: ink,
                                      backgroundCursorColor: colors.border,
                                      selectionColor: theme.accent
                                          .readableOn(colors.elevated)
                                          .withValues(alpha: .20),
                                      selectionControls: _YYSelectionHandles(
                                        ink,
                                      ),
                                      contextMenuBuilder: (context, state) =>
                                          _editingMenu(theme, state),
                                      textInputAction: TextInputAction.search,
                                      onChanged: (value) {
                                        if (_interactive) {
                                          widget.onChanged?.call(value);
                                        }
                                      },
                                      onSubmitted: (value) {
                                        if (_interactive &&
                                            widget
                                                .controller
                                                .value
                                                .composing
                                                .isCollapsed) {
                                          widget.onSubmitted?.call(value);
                                        }
                                      },
                                      onTapOutside: (_) => _focus.unfocus(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (widget.loading)
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: YYIcon(
                              glyph: YYGlyph.more,
                              size: 20,
                              semanticLabel: '加载中',
                            ),
                          ),
                        )
                      else if (widget.controller.text.isNotEmpty)
                        YYIconButton(
                          key: const ValueKey('clear-search'),
                          glyph: YYGlyph.close,
                          label: '清空搜索',
                          style: YYButtonStyle.quiet,
                          onPressed: _interactive ? _clear : null,
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Semantics(
              container: true,
              liveRegion: true,
              child: Text(
                error,
                style: YYTypography.caption.copyWith(color: ink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _editingMenu(YYThemeData theme, EditableTextState state) {
  final labels = {
    ContextMenuButtonType.cut: '剪切',
    ContextMenuButtonType.copy: '复制',
    ContextMenuButtonType.paste: '粘贴',
    ContextMenuButtonType.selectAll: '全选',
  };
  return YYTheme(
    data: theme,
    child: CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: state.contextMenuAnchors.primaryAnchor,
        anchorBelow:
            state.contextMenuAnchors.secondaryAnchor ??
            state.contextMenuAnchors.primaryAnchor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.elevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colors.border),
            boxShadow: YYShadows.floating(theme.brightness),
          ),
          child: Wrap(
            children: [
              for (final item in state.contextMenuButtonItems)
                if (labels.containsKey(item.type))
                  YYButton(
                    label: labels[item.type]!,
                    onPressed: item.onPressed,
                    style: YYButtonStyle.quiet,
                  ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Native text-editing chrome, not an application icon or a Material control.
class _YYSelectionHandles extends TextSelectionControls
    with TextSelectionHandleControls {
  _YYSelectionHandles(this.color);
  final Color color;
  @override
  Size getHandleSize(double textLineHeight) => const Size(22, 22);
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      const Offset(11, 0);
  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) => GestureDetector(
    onTap: onTap,
    child: SizedBox.square(
      dimension: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}
