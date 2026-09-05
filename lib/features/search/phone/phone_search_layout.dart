import 'package:flutter/widgets.dart';

import '../common/search_sections.dart';

class PhoneSearchLayout extends StatelessWidget {
  const PhoneSearchLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final SearchSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const ValueKey('screen-search'),
    controller: scroll,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
