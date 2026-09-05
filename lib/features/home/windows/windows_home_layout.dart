import 'package:flutter/widgets.dart';

import '../common/home_sections.dart';

class WindowsHomeLayout extends StatelessWidget {
  const WindowsHomeLayout({super.key, required this.sections});
  final HomeSections sections;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.error,
      sections.hero(wide: sections.width >= 720),
      const SizedBox(height: 32),
      sections.continuing(columns: (sections.width / 148).floor().clamp(2, 6)),
      const SizedBox(height: 32),
      if (sections.width >= 800)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: sections.recent),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: sections.sources),
          ],
        )
      else ...[
        sections.recent,
        const SizedBox(height: 20),
        sections.sources,
      ],
      const SizedBox(height: 32),
      sections.history,
    ],
  );
}
