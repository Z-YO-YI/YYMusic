import 'package:flutter/widgets.dart';

import '../common/catalog_detail_sections.dart';

class PhoneCatalogDetailLayout extends StatelessWidget {
  const PhoneCatalogDetailLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final CatalogDetailSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('detail-scroll'),
    controller: scroll,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: sections.toolbar),
            SliverToBoxAdapter(
              child: sections.summary(horizontal: false, artworkSize: 132),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ...sections.content,
          ],
        ),
      ),
    ],
  );
}
