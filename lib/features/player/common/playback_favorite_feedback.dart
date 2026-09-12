import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../design_system/yy_button.dart';
import '../../../design_system/yy_feedback.dart';
import '../../../playback/playback_favorite_controller.dart';

/// Controlled root feedback. The owner listens and supplies a page permission.
class PlaybackFavoriteFeedback extends StatelessWidget {
  const PlaybackFavoriteFeedback({
    super.key,
    required this.controller,
    required this.permit,
  });
  final PlaybackFavoriteController controller;
  final bool Function() permit;

  @override
  Widget build(BuildContext context) {
    final failure = controller.failure;
    bool current() => permit() && identical(controller.failure, failure);
    final readFailure = failure?.kind == PlaybackFavoriteFailureKind.read;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.busy)
          Semantics(liveRegion: true, child: const Text('正在保存收藏…')),
        if (failure != null) ...[
          YYErrorBanner(title: '收藏操作未完成', message: failure.message),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              YYButton(
                label: readFailure ? '重试读取收藏' : '重试收藏操作',
                onPressed:
                    permit() &&
                        !controller.busy &&
                        (readFailure || controller.canRetry(failure))
                    ? () {
                        if (!current() || controller.busy) return;
                        if (readFailure) {
                          controller.retryRead();
                        } else {
                          unawaited(controller.retry(failure, canEdit: permit));
                        }
                      }
                    : null,
              ),
              // A read failure must retain its recovery path while unknown.
              if (!readFailure)
                YYButton(
                  label: '知道了',
                  onPressed: () {
                    if (current()) controller.dismissFailure(failure);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
