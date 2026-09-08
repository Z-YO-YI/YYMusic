import 'package:flutter/widgets.dart';

import '../common/local_music_sections.dart';

class WindowsLocalMusicLayout extends StatelessWidget {
  const WindowsLocalMusicLayout({super.key, required this.sections});
  final LocalMusicSections sections;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.heading,
      const SizedBox(height: 16),
      sections.metrics(columns: 3),
      const SizedBox(height: 20),
      sections.folders,
    ],
  );
}
