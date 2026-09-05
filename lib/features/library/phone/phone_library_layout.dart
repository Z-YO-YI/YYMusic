import 'package:flutter/widgets.dart';

import '../common/library_sections.dart';

class PhoneLibraryLayout extends StatelessWidget {
  const PhoneLibraryLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final LibrarySections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const ValueKey('screen-library'),
    controller: scroll,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: sections.header(wide: false)),
            ...sections.results,
          ],
        ),
      ),
    ],
  );
}
