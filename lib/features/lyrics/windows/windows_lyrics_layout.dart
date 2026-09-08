import 'package:flutter/widgets.dart';

class WindowsLyricsLayout extends StatelessWidget {
  const WindowsLyricsLayout({
    super.key,
    required this.header,
    required this.body,
    required this.dock,
  });
  final Widget header, body, dock;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
    child: Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: header,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Align(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: body,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: dock,
        ),
      ],
    ),
  );
}
