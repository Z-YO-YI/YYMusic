import 'package:flutter/widgets.dart';

import '../../../app/layout_class.dart';
import '../../../design_system/yy_icon.dart';
import '../../../design_system/yy_surface.dart';
import '../../../domain/models/queue_edit.dart';
import 'queue_drag_session.dart';

/// Key this Widget by the content, root and interaction revision. Replacing the
/// key cancels even pending recognizers and stale native semantic callbacks.
class QueueReorderSliver extends StatefulWidget {
  const QueueReorderSliver({
    super.key,
    required this.count,
    required this.enabled,
    required this.platform,
    required this.itemBuilder,
    required this.begin,
    required this.onMove,
  });
  final int count;
  final bool enabled;
  final YYPlatform platform;
  final IndexedWidgetBuilder itemBuilder;
  final QueueDragSession? Function(int) begin;
  final void Function(QueueDragSession, QueueEdit) onMove;
  @override
  State<QueueReorderSliver> createState() => _QueueReorderSliverState();
}

class _QueueReorderSliverState extends State<QueueReorderSliver> {
  final _list = GlobalKey<SliverReorderableListState>();
  QueueDragSession? _drag;
  bool _cancelling = false;
  int _generation = 0;

  @override
  void didUpdateWidget(QueueReorderSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _cancel();
  }

  void _cancel() {
    _drag = null;
    _cancelling = true;
    final generation = ++_generation;
    // Flutter invokes start before it has finished allocating its native drag.
    // Never reset that half-created state from inside its callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _list.currentState?.cancelReorder();
      setState(() => _cancelling = false);
    });
  }

  void _start(int index) {
    _generation++;
    _cancelling = false;
    final drag = widget.enabled ? widget.begin(index) : null;
    if (drag == null) {
      _cancel();
      return;
    }
    setState(() => _drag = drag);
  }

  void _reorder(int source, int target) {
    if (!mounted || _cancelling || !widget.enabled) return;
    // Native accessibility reorder actions do not call onReorderStart.
    final drag = _drag ?? widget.begin(source);
    _drag = null;
    if (drag == null || drag.sourceIndex != source) return;
    final edit = drag.moveTo(target);
    if (edit != null) widget.onMove(drag, edit);
  }

  @override
  Widget build(BuildContext context) => SliverReorderableList(
    key: _list,
    itemCount: widget.count,
    onReorderStart: _start,
    onReorderItem: _reorder,
    onReorderEnd: (target) {
      final source = _drag?.sourceIndex;
      if (source != null && (target == source || target == source + 1)) {
        setState(() => _drag = null);
      }
    },
    proxyDecorator: (child, _, _) => ExcludeSemantics(
      child: IgnorePointer(
        child: YYSurface(padding: EdgeInsets.zero, radius: 12, child: child),
      ),
    ),
    itemBuilder: (context, index) {
      final row = widget.itemBuilder(context, index);
      final content = IgnorePointer(
        ignoring: _drag != null,
        child: ExcludeFocus(excluding: _drag != null, child: row),
      );
      final child = widget.platform == YYPlatform.windows
          ? Row(
              children: [
                ReorderableDragStartListener(
                  key: ValueKey<Object>(('queue-drag-handle', row.key)),
                  index: index,
                  enabled: widget.enabled,
                  child: MouseRegion(
                    cursor: widget.enabled
                        ? SystemMouseCursors.grab
                        : SystemMouseCursors.basic,
                    child: Semantics(
                      label: '拖动队列条目排序，或使用上下移按钮',
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: YYIcon(glyph: YYGlyph.drag, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            )
          : ReorderableDelayedDragStartListener(
              index: index,
              enabled: widget.enabled,
              child: content,
            );
      return Listener(
        key: ValueKey(('queue-reorder-row', row.key)),
        onPointerCancel: (_) => _cancel(),
        child: child,
      );
    },
  );
}
