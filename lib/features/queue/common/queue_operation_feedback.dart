import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../playback/queue_controller.dart';

/// Controlled root feedback. The owner captures a revocable page permission.
class QueueOperationFeedback extends StatelessWidget {
  const QueueOperationFeedback({
    super.key,
    required this.queue,
    required this.permit,
    required this.onOpenQueue,
    required this.onDismissNotice,
    this.notice,
  });
  final QueueController queue;
  final bool Function() permit;
  final VoidCallback onOpenQueue, onDismissNotice;
  final String? notice;
  @override
  Widget build(BuildContext context) {
    final failure = queue.editFailure;
    if (!queue.editBusy && failure == null && notice == null) {
      return const SizedBox.shrink();
    }
    VoidCallback guarded(VoidCallback action) => () {
      if (permit()) action();
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (queue.editBusy)
            Semantics(liveRegion: true, child: const Text('正在更新播放队列…')),
          if (failure != null) ...[
            YYErrorBanner(title: '队列操作未完成', message: failure.message),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YYButton(
                  label: '重试队列操作',
                  onPressed: permit() && queue.canRetryEdit(failure)
                      ? guarded(
                          () => unawaited(
                            queue.retryEdit(failure, canEdit: permit),
                          ),
                        )
                      : null,
                ),
                YYButton(
                  label: '知道了',
                  onPressed: guarded(() => queue.dismissEditFailure(failure)),
                ),
              ],
            ),
          ],
          if (notice != null && failure == null) ...[
            Semantics(liveRegion: true, child: Text(notice!)),
            const SizedBox(height: 8),
            YYButton(label: '关闭队列提示', onPressed: guarded(onDismissNotice)),
          ],
          const SizedBox(height: 8),
          YYButton(label: '查看播放队列', onPressed: guarded(onOpenQueue)),
        ],
      ),
    );
  }
}
