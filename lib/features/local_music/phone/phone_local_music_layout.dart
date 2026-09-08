import 'package:flutter/widgets.dart';

import '../common/local_music_sections.dart';

class PhoneLocalMusicLayout extends StatelessWidget {
  const PhoneLocalMusicLayout({super.key, required this.sections});
  final LocalMusicSections sections;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.heading,
      const SizedBox(height: 16),
      sections.metrics(columns: 1),
      const SizedBox(height: 16),
      sections.folders,
    ],
  );
}
