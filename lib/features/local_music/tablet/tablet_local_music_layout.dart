import 'package:flutter/widgets.dart';

import '../common/local_music_sections.dart';

class TabletLocalMusicLayout extends StatelessWidget {
  const TabletLocalMusicLayout({
    super.key,
    required this.sections,
    required this.landscape,
  });
  final LocalMusicSections sections;
  final bool landscape;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.heading,
      const SizedBox(height: 16),
      if (landscape)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: sections.metrics(columns: 1)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: sections.folders),
          ],
        )
      else ...[
        sections.metrics(columns: 3),
        const SizedBox(height: 16),
        sections.folders,
      ],
    ],
  );
}
