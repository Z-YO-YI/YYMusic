import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Tablet composition uses a centered vertical stage or a spacious split view.
class TabletPlayerLayout extends StatelessWidget {
  const TabletPlayerLayout({
    super.key,
    required this.artwork,
    required this.controls,
  });
  final Widget Function(double) artwork;
  final Widget controls;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth > box.maxHeight) {
        return Row(
          children: [
            Expanded(
              child: Center(
                child: artwork(
                  math
                      .min(box.maxHeight * .78, box.maxWidth * .43)
                      .clamp(1, 540),
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  vertical: box.maxHeight < 500 ? 8 : 24,
                ),
                child: controls,
              ),
            ),
          ],
        );
      }
      return SingleChildScrollView(
        key: const PageStorageKey('tablet-player-scroll'),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                artwork(
                  math
                      .min(box.maxWidth * .67, box.maxHeight * .46)
                      .clamp(1, 480),
                ),
                const SizedBox(height: 40),
                controls,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );
}
