import 'package:flutter/widgets.dart';

import '../common/home_sections.dart';

class PhoneHomeLayout extends StatelessWidget {
  const PhoneHomeLayout({super.key, required this.sections});
  final HomeSections sections;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      sections.error,
      sections.hero(wide: false),
      const SizedBox(height: 28),
      sections.continuing(columns: 2),
      const SizedBox(height: 28),
      sections.recent,
      const SizedBox(height: 20),
      sections.sources,
      const SizedBox(height: 28),
      sections.history,
    ],
  );
}
