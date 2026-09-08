import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_text_editing.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Native single-line form field, based on the reference HTML .field.
/// The caller owns text, focus, validation and submission.
class YYTextField extends StatefulWidget {
  const YYTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    this.placeholder = '',
    this.enabled = true,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label, placeholder;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onChanged, onSubmitted;
  @override
  State<YYTextField> createState() => _YYTextFieldState();
}

class _YYTextFieldState extends State<YYTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final editableTextKey = GlobalKey<EditableTextState>();
  late final _gestures = TextSelectionGestureDetectorBuilder(delegate: this);
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => widget.enabled;

  @override
  Widget build(BuildContext context) {
    final theme = YYTheme.of(context), colors = theme.colors;
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.focusNode]),
      builder: (context, _) => TextFieldTapRegion(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: YYTypography.text(
                size: 10,
                weight: 680,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 7),
            MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: widget.enabled
                    ? () => editableTextKey.currentState?.requestKeyboard()
                    : null,
                child: Container(
                  key: const ValueKey('yy-text-field-surface'),
                  height: math.max(
                    44,
                    MediaQuery.textScalerOf(context).scale(11) * 1.45 + 24,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: colors.subtle,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: widget.errorText != null
                          ? YYPalette.error
                          : widget.focusNode.hasFocus
                          ? colors.text
                          : colors.border,
                      width: widget.focusNode.hasFocus ? 1.5 : 1,
                    ),
                  ),
                  child: Semantics(
                    label: widget.label,
                    hint: widget.errorText ?? widget.placeholder,
                    enabled: widget.enabled,
                    child: ExcludeFocus(
                      excluding: !widget.enabled,
                      child: IgnorePointer(
                        ignoring: !widget.enabled,
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
                                      size: 11,
                                      color: colors.tertiary,
                                    ),
                                  ),
                                ),
                              EditableText(
                                key: editableTextKey,
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                readOnly: !widget.enabled,
                                rendererIgnoresPointer: true,
                                enableInteractiveSelection: widget.enabled,
                                style: YYTypography.text(
                                  size: 11,
                                  color: colors.text,
                                ),
                                cursorColor: colors.text,
                                backgroundCursorColor: colors.border,
                                selectionColor: theme.accent
                                    .readableOn(colors.subtle)
                                    .withValues(alpha: .20),
                                selectionControls: YYSelectionHandles(
                                  colors.text,
                                ),
                                contextMenuBuilder: (context, state) =>
                                    yyEditingMenu(theme, state),
                                textInputAction: TextInputAction.done,
                                onEditingComplete: () {},
                                onChanged: (value) {
                                  if (widget.enabled) {
                                    widget.onChanged?.call(value);
                                  }
                                },
                                onSubmitted: (value) {
                                  if (widget.enabled &&
                                      widget
                                          .controller
                                          .value
                                          .composing
                                          .isCollapsed) {
                                    widget.onSubmitted?.call(value);
                                  }
                                },
                                onTapOutside: (_) => widget.focusNode.unfocus(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.errorText case final error?) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: YYTypography.caption.copyWith(color: colors.text),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
