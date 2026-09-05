import 'package:flutter/widgets.dart';

import '../common/catalog_detail_sections.dart';

class TabletCatalogDetailLayout extends StatelessWidget {
  const TabletCatalogDetailLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.landscape,
  });
  final CatalogDetailSections sections;
  final ScrollController scroll;
  final bool landscape;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (landscape && constraints.maxWidth >= 620) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              sections.toolbar,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: SingleChildScrollView(
                        key: const PageStorageKey('tablet-detail-info'),
                        child: sections.summary(
                          horizontal: false,
                          artworkSize: constraints.maxHeight < 500 ? 100 : 160,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomScrollView(
                        key: const PageStorageKey('detail-scroll'),
                        controller: scroll,
                        slivers: sections.content,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return CustomScrollView(
        key: const PageStorageKey('detail-scroll'),
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: sections.toolbar),
                SliverToBoxAdapter(
                  child: sections.summary(horizontal: true, artworkSize: 160),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ...sections.content,
              ],
            ),
          ),
        ],
      );
    },
  );
}
