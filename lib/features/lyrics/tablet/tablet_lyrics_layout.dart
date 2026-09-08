import 'package:flutter/widgets.dart';

class TabletLyricsLayout extends StatelessWidget {
  const TabletLyricsLayout({
    super.key,
    required this.header,
    required this.body,
    required this.dock,
  });
  final Widget header, body, dock;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth > box.maxHeight;
      return Padding(
        padding: EdgeInsets.fromLTRB(wide ? 24 : 30, 12, wide ? 24 : 30, 14),
        child: Column(
          children: [
            header,
            const SizedBox(height: 10),
            Expanded(
              child: Align(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 980 : 740),
                  child: body,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: dock,
            ),
          ],
        ),
      );
    },
  );
}
