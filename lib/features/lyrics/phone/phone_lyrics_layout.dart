import 'package:flutter/widgets.dart';

class PhoneLyricsLayout extends StatelessWidget {
  const PhoneLyricsLayout({
    super.key,
    required this.header,
    required this.body,
    required this.dock,
  });
  final Widget header, body, dock;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Column(
      children: [
        header,
        const SizedBox(height: 6),
        Expanded(child: body),
        const SizedBox(height: 8),
        dock,
      ],
    ),
  );
}
