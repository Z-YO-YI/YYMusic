import 'package:flutter/widgets.dart';

import '../common/library_sections.dart';

class WindowsLibraryLayout extends StatelessWidget {
  const WindowsLibraryLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final LibrarySections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: CustomScrollView(
        key: const ValueKey('screen-library'),
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: sections.header(wide: true)),
                ...sections.results,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
