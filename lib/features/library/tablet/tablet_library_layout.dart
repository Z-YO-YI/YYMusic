import 'package:flutter/widgets.dart';

import '../common/library_sections.dart';

class TabletLibraryLayout extends StatelessWidget {
  const TabletLibraryLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.landscape,
  });
  final LibrarySections sections;
  final ScrollController scroll;
  final bool landscape;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: CustomScrollView(
        key: const ValueKey('screen-library'),
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(landscape ? 24 : 20),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: sections.header(wide: landscape)),
                ...sections.results,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
