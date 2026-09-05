import 'package:flutter/widgets.dart';

import '../common/catalog_detail_sections.dart';

class WindowsCatalogDetailLayout extends StatelessWidget {
  const WindowsCatalogDetailLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final CatalogDetailSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          key: const PageStorageKey('detail-scroll'),
          controller: scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(child: sections.toolbar),
                  SliverToBoxAdapter(
                    child: sections.summary(
                      horizontal: constraints.maxWidth >= 560,
                      artworkSize: constraints.maxWidth >= 700 ? 200 : 132,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ...sections.content,
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
