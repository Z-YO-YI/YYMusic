import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Desktop always keeps artwork and independently scrollable controls in columns.
class WindowsPlayerLayout extends StatelessWidget {
  const WindowsPlayerLayout({
    super.key,
    required this.artwork,
    required this.controls,
  });
  final Widget Function(double) artwork;
  final Widget controls;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1320),
      child: LayoutBuilder(
        builder: (context, box) {
          final gap = (box.maxWidth * .06).clamp(20.0, 100.0);
          final column = (box.maxWidth - gap) / 2;
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: artwork(
                    math.min(box.maxHeight * .72, column * .94).clamp(1, 640),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: SingleChildScrollView(
                  key: const PageStorageKey('windows-player-scroll'),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: controls,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
