import 'package:flutter/widgets.dart';

import '../common/home_sections.dart';

class TabletHomeLayout extends StatelessWidget {
  const TabletHomeLayout({
    super.key,
    required this.sections,
    required this.landscape,
  });
  final HomeSections sections;
  final bool landscape;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.error,
      sections.hero(wide: landscape && sections.width >= 720),
      const SizedBox(height: 28),
      sections.continuing(columns: landscape ? 4 : 3),
      const SizedBox(height: 28),
      if (landscape && sections.width >= 800)
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
      const SizedBox(height: 28),
      sections.history,
    ],
  );
}
