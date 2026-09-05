import 'package:flutter/widgets.dart';

import '../common/search_sections.dart';

class TabletSearchLayout extends StatelessWidget {
  const TabletSearchLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.landscape,
  });
  final SearchSections sections;
  final ScrollController scroll;
  final bool landscape;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 948),
      child: CustomScrollView(
        key: const ValueKey('screen-search'),
        controller: scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
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
