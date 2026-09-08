import 'package:flutter/widgets.dart';

import '../common/playlist_content_sections.dart';

class PhonePlaylistContentLayout extends StatelessWidget {
  const PhonePlaylistContentLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final PlaylistContentSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: const PageStorageKey('playlist-scroll'),
    controller: scroll,
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(16),
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
}
