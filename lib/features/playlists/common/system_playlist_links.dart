import 'package:flutter/widgets.dart';

import '../../../app/app_routes.dart';
import '../../../design_system/yy_playlist_card.dart';
import '../../../domain/models/collection_models.dart';
import 'playlist_editor_host.dart';
import 'system_playlist_presentation.dart';

/// Entry cards use descriptions until a page reads the actual collection count.
class SystemPlaylistLinks extends StatelessWidget {
  const SystemPlaylistLinks({
    super.key,
    required this.navigation,
    required this.canNavigate,
  });
  final AppNavigation navigation;
  final bool Function() canNavigate;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 680
          ? 3
          : constraints.maxWidth >= 320
          ? 2
          : 1;
      final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final type in SystemPlaylistType.values)
            SizedBox(
              width: width,
              child: YYPlaylistCard(
                key: ValueKey(('system-playlist-open', type)),
                title: type.title,
                meta: type.description,
                glyph: type.glyph,
                onPressed: () {
                  if (context.mounted &&
                      canNavigate() &&
                      (PlaylistEditorScope.maybeOf(context)
                              ?.interactionEnabled ??
                          true) &&
                      TickerMode.valuesOf(context).enabled &&
                      (ModalRoute.isCurrentOf(context) ?? true)) {
                    navigation.openSystemPlaylist(type);
                  }
                },
              ),
            ),
        ],
      );
    },
  );
}
