import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../design_system/yy_feedback.dart';
import '../design_system/yy_tokens.dart';
import '../design_system/yy_window_toolbar.dart';
import 'window_presenter.dart';

class WindowChrome extends StatelessWidget {
  const WindowChrome({super.key, required this.presenter});
  final WindowPresenter presenter;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: presenter,
    builder: (context, _) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        YYWindowToolbar(
          showWindowControls: presenter.available,
          maximized: presenter.maximized,
          onMinimize: presenter.canControl
              ? () => unawaited(presenter.minimize())
              : null,
          onToggleMaximize: presenter.canControl
              ? () => unawaited(presenter.toggleMaximize())
              : null,
          onClose: presenter.canControl
              ? () => unawaited(presenter.requestClose())
              : null,
          onStartDrag: presenter.canControl
              ? () => unawaited(presenter.startDrag())
              : null,
        ),
        if (presenter.errorMessage case final message?)
          YYErrorBanner(title: '窗口操作失败', message: message),
      ],
    ),
  );
}

/// Keeps native window controls reachable on modal and non-Shell routes too.
class WindowFrame extends StatefulWidget {
  const WindowFrame({super.key, required this.presenter, required this.child});
  final WindowPresenter presenter;
  final Widget child;
  @override
  State<WindowFrame> createState() => _WindowFrameState();
}

class _WindowFrameState extends State<WindowFrame> {
  Size? _lastSize;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.presenter,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final visible =
            constraints.maxHeight > YYWindowsMetrics.toolbarHeight &&
            constraints.maxWidth > 0;
        if (visible) _lastSize = constraints.biggest;
        final size = _lastSize;
        if (size == null) return const SizedBox.shrink();
        // Minimize must not unmount Navigator or lose route-owned sessions.
        // Keep the previous finite layout offstage, with input and tickers off.
        return Offstage(
          offstage: !visible,
          child: ExcludeFocus(
            excluding: !visible,
            child: TickerMode(
              enabled: visible,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: size.height,
                maxHeight: size.height,
                child: _frame(context),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _frame(BuildContext context) {
    final presenter = widget.presenter;
    final child = widget.child;
    if (!presenter.available) {
      final error = presenter.errorMessage;
      return error == null
          ? child
          : Column(
              children: [
                YYErrorBanner(title: '窗口控制不可用', message: error),
                Expanded(child: child),
              ],
            );
    }
    return Overlay.wrap(
      child: Column(
        // Paint native chrome after Navigator's modal semantics barrier.
        verticalDirection: VerticalDirection.up,
        children: [
          Expanded(child: WindowFrameScope(child: child)),
          Semantics(
            container: true,
            explicitChildNodes: true,
            sortKey: const OrdinalSortKey(-1),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 1024 ? 12 : 16,
              ),
              child: WindowChrome(presenter: presenter),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowFrameScope extends InheritedWidget {
  const WindowFrameScope({super.key, required super.child});
  static bool active(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WindowFrameScope>() != null;
  @override
  bool updateShouldNotify(WindowFrameScope oldWidget) => false;
}
