import 'package:flutter/widgets.dart';

import '../common/search_sections.dart';

class WindowsSearchLayout extends StatelessWidget {
  const WindowsSearchLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final SearchSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 948),
      child: CustomScrollView(
        key: const ValueKey('screen-search'),
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
