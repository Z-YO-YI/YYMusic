import 'package:flutter/widgets.dart';

import '../common/playlist_content_sections.dart';

class WindowsPlaylistContentLayout extends StatelessWidget {
  const WindowsPlaylistContentLayout({
    super.key,
    required this.sections,
    required this.scroll,
  });
  final PlaylistContentSections sections;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: CustomScrollView(
        key: const PageStorageKey('playlist-scroll'),
        controller: scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(child: sections.toolbar),
                SliverToBoxAdapter(child: sections.summary),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ...sections.content,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
