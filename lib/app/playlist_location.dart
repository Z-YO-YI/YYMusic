import '../domain/models/domain_validation.dart';

/// Query encoding preserves opaque IDs, including slash, percent and dot segments.
Uri playlistLocation(String id) => Uri(
  path: '/playlist',
  queryParameters: {'id': DomainValidation.identifier(id, 'playlistId')},
);

String? parsePlaylistLocation(Uri uri) {
  try {
    final ids = uri.queryParametersAll['id'];
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        uri.path != '/playlist' ||
        uri.queryParametersAll.length != 1 ||
        ids == null ||
        ids.length != 1) {
      return null;
    }
    return DomainValidation.identifier(ids.single, 'playlistId');
  } catch (_) {
    return null;
  }
}
