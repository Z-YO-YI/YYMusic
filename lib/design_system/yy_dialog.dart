import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'yy_button.dart';
import 'yy_icon.dart';
import 'yy_theme.dart';
import 'yy_tokens.dart';

/// Opaque desktop/tablet dialog surface. Overlay insertion stays external.
class YYDialog extends StatelessWidget {
  const YYDialog({
    super.key,
    required this.title,
    required this.body,
    required this.onClose,
    this.subtitle,
    this.actions = const [],
    this.autofocus = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback onClose;
  final List<Widget> actions;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.max(
      0.0,
      math.min(YYOverlayMetrics.dialogMaxWidth, size.width - 48),
    );
    final maxHeight = math.max(120.0, size.height - 48);
    return _YYModalFocusScope(
      autofocus: autofocus,
      onDismiss: onClose,
      builder: (context, initialFocus) => Semantics(
        container: true,
        explicitChildNodes: true,
        scopesRoute: true,
        namesRoute: true,
        label: '对话框，$title',
        child: SizedBox(
          key: const ValueKey('yy-dialog'),
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _ModalSurface(
              borderRadius: const BorderRadius.all(
                Radius.circular(YYRadius.dialog),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModalHeader(
                    title: title,
                    subtitle: subtitle,
                    onClose: onClose,
                    closeFocusNode: initialFocus,
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _ModalBody(child: body),
                  ),
                  if (actions.isNotEmpty) _ModalFooter(actions: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone adaptation for dialog-like actions; no Material BottomSheet defaults.
class YYBottomSheet extends StatelessWidget {
  const YYBottomSheet({
    super.key,
    required this.title,
    required this.body,
    required this.onClose,
    this.subtitle,
    this.actions = const [],
    this.autofocus = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final VoidCallback onClose;
  final List<Widget> actions;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      120.0,
      media.size.height - media.padding.top - 24,
    );
    return _YYModalFocusScope(
      autofocus: autofocus,
      onDismiss: onClose,
      builder: (context, initialFocus) => Semantics(
        container: true,
        explicitChildNodes: true,
        scopesRoute: true,
        namesRoute: true,
        label: '底部面板，$title',
        child: ConstrainedBox(
          key: const ValueKey('yy-bottom-sheet'),
          constraints: BoxConstraints(
            minWidth: double.infinity,
            maxHeight: maxHeight,
          ),
          child: _ModalSurface(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(YYRadius.dialog),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: media.padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ModalHeader(
                    title: title,
                    subtitle: subtitle,
                    onClose: onClose,
                    closeFocusNode: initialFocus,
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _ModalBody(child: body),
                  ),
                  if (actions.isNotEmpty) _ModalFooter(actions: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalSurface extends StatelessWidget {
  const _ModalSurface({required this.borderRadius, required this.child});

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return DecoratedBox(
      key: const ValueKey('yy-modal-surface'),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: borderRadius,
        border: Border.all(color: colors.border),
        boxShadow: YYShadows.dialog,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
    required this.closeFocusNode,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final FocusNode closeFocusNode;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return ConstrainedBox(
      key: const ValueKey('yy-modal-header'),
      constraints: const BoxConstraints(
        minHeight: YYOverlayMetrics.dialogSectionMinHeight,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: YYTypography.text(
                        size: 18,
                        weight: 750,
                        spacing: -.35,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: YYTypography.text(
                          size: 10,
                          weight: 500,
                          color: colors.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              YYIconButton(
                glyph: YYGlyph.close,
                label: '关闭$title',
                onPressed: onClose,
                focusNode: closeFocusNode,
                style: YYButtonStyle.quiet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalBody extends StatelessWidget {
  const _ModalBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('yy-modal-body'),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
    child: child,
  );
}

class _ModalFooter extends StatelessWidget {
  const _ModalFooter({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return ConstrainedBox(
      key: const ValueKey('yy-modal-footer'),
      constraints: const BoxConstraints(
        minHeight: YYOverlayMetrics.dialogSectionMinHeight,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Wrap(
            alignment: WrapAlignment.end,
            runAlignment: WrapAlignment.center,
            spacing: 9,
            runSpacing: 8,
            children: actions,
          ),
        ),
      ),
    );
  }
}

typedef _ModalFocusBuilder = Widget Function(
  BuildContext context,
  FocusNode initialFocus,
);

class _YYModalFocusScope extends StatefulWidget {
  const _YYModalFocusScope({
    required this.autofocus,
    required this.onDismiss,
    required this.builder,
  });

  final bool autofocus;
  final VoidCallback onDismiss;
  final _ModalFocusBuilder builder;

  @override
  State<_YYModalFocusScope> createState() => _YYModalFocusScopeState();
}

class _YYModalFocusScopeState extends State<_YYModalFocusScope> {
  late final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'YY modal focus scope',
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
    onKeyEvent: _handleKey,
  );
  final FocusNode _initialFocus = FocusNode(debugLabel: 'YY modal close');
  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();
    _previousFocus = FocusManager.instance.primaryFocus;
    _scheduleAutofocus();
  }

  @override
  void didUpdateWidget(_YYModalFocusScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.autofocus && widget.autofocus) _scheduleAutofocus();
  }

  void _scheduleAutofocus() {
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _initialFocus.canRequestFocus) {
        _initialFocus.requestFocus();
      }
    });
  }

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    final previous = _previousFocus;
    if (widget.autofocus &&
        previous != null &&
        previous.context != null &&
        previous.canRequestFocus) {
      previous.requestFocus();
    }
    _initialFocus.dispose();
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FocusScope.withExternalFocusNode(
    focusScopeNode: _scope,
    child: FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: widget.builder(context, _initialFocus),
    ),
  );
}
