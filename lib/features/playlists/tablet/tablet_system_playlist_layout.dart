import 'package:flutter/widgets.dart';

import '../common/system_playlist_sections.dart';

class TabletSystemPlaylistLayout extends StatelessWidget {
  const TabletSystemPlaylistLayout({
    super.key,
    required this.sections,
    required this.scroll,
    required this.landscape,
  });
  final SystemPlaylistSections sections;
  final ScrollController scroll;
  final bool landscape;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (landscape &&
          constraints.maxWidth >= 620 &&
          constraints.maxHeight >= 260) {
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
                      width: 220,
                      child: SingleChildScrollView(child: sections.summary),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomScrollView(
                        key: const PageStorageKey('system-playlist-scroll'),
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
        key: const PageStorageKey('system-playlist-scroll'),
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: sections.toolbar),
                SliverToBoxAdapter(child: sections.summary),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ...sections.content,
              ],
            ),
          ),
        ],
      );
    },
  );
}
