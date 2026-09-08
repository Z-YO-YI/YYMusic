import '../domain/models/collection_models.dart';

/// Virtual system collections have a closed route identity, never a Playlist ID.
Uri systemPlaylistLocation(SystemPlaylistType type) =>
    Uri(path: '/system-playlist', queryParameters: {'type': type.name});

SystemPlaylistType? parseSystemPlaylistLocation(Uri uri) {
  try {
    final types = uri.queryParametersAll['type'];
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        uri.path != '/system-playlist' ||
        uri.queryParametersAll.length != 1 ||
        types == null ||
        types.length != 1) {
      return null;
    }
    return SystemPlaylistType.values
        .where((type) => type.name == types.single)
        .firstOrNull;
  } catch (_) {
    return null;
  }
}
