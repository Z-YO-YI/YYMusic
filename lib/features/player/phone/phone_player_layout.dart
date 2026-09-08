import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Phone composition: artwork above controls, compact side-by-side when short.
class PhonePlayerLayout extends StatelessWidget {
  const PhonePlayerLayout({
    super.key,
    required this.artwork,
    required this.controls,
  });
  final Widget Function(double) artwork;
  final Widget controls;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth > box.maxHeight && box.maxWidth >= 460) {
        return Row(
          children: [
            Expanded(
              child: Center(
                child: artwork(
                  math
                      .min(box.maxHeight * .72, box.maxWidth * .38)
                      .clamp(1, 350),
                ),
              ),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: controls,
              ),
            ),
          ],
        );
      }
      return SingleChildScrollView(
        key: const PageStorageKey('phone-player-scroll'),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            artwork(
              math.min(box.maxWidth - 12, box.maxHeight * .47).clamp(1, 390),
            ),
            const SizedBox(height: 28),
            controls,
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
