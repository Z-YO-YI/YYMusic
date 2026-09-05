import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('detail sessions read scoped catalog contracts without owning storage, engines or fixtures', () => {
  for (const path of walk('lib/features/catalog_detail').filter(path => path.endsWith('.dart'))) {
    assert(!/AppDatabase|Drift|dart:io|AudioEngine|PlaybackController\(|Fake|Fixture|WebView|credentialRef|baseUrl|localPath|\.network\(|watchTracks\(|upsertTracks/.test(read(path)), path);
  }
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  for (const method of ['getAlbum', 'getArtist', 'browseTracks', 'browseAlbums']) {
    assert(controller.includes(`repository.${method}(`), method);
  }
  assert.match(controller, /offset: previous.rawCount/);
  assert.match(controller, /rawCount: previous.rawCount \+ raw.length/);
  assert.match(controller, /token.isCancelled/);
  assert.match(controller, /album.ref != reference/);
  assert.match(controller, /artist.ref != reference/);
  assert.match(controller, /track.sourceId == target.sourceId/);
  assert.match(controller, /track.albumId == reference.albumId/);
  const state = read('lib/features/catalog_detail/common/catalog_detail_state.dart');
  assert.match(state, /pageSize = 20/);
  assert.match(state, /maxRawCount = 200/);
  assert.match(state, /List.unmodifiable\(items\)/);
});

test('root retains closing detail sessions until real work drains before shared database close', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /catalogDetails = CatalogDetailSessions\([\s\S]*?repository: this.catalogBrowse/);
  assert.match(graph, /playback: playback,[\s\S]*?sources: this.musicSources/);
  assert.match(graph, /catalogDetails.dispose\(\)/);
  assert.match(graph, /catalogDetails.close,[\s\S]*?services.dispose/);
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  assert.match(controller, /Future.wait<void>\(_pending\)[\s\S]*?_onClosed\(\)/);
  const registry = read('lib/features/catalog_detail/common/catalog_detail_sessions.dart');
  assert.match(registry, /if \(_disposed\) throw StateError/);
  assert.match(registry, /\(\) => _sessions.remove\(session\)/);
});

test('detail routes keep native state above app-provided chrome and scroll identity across layouts', () => {
  const router = read('lib/app/app_router.dart');
  assert.match(router, /CatalogDetailScreen\([\s\S]*?frame: \(child\) => AdaptiveRoot\(/);
  assert.match(router, /parseCatalogDetailLocation\(state.uri\)/);
  for (const [platform, layout] of [['phone', 'Phone'], ['tablet', 'Tablet'], ['windows', 'Windows']]) {
    const path = `lib/features/catalog_detail/${platform}/${platform}_catalog_detail_layout.dart`;
    const source = read(path);
    assert(source.includes(`class ${layout}CatalogDetailLayout`));
    assert(source.includes("PageStorageKey('detail-scroll')"));
    assert(!/sessions.open|\.start\(|\.refresh\(|playCatalogTrack/.test(source));
  }
  const screen = read('lib/features/catalog_detail/common/catalog_detail_screen.dart');
  assert.match(screen, /controller = widget.sessions.open\(widget.target\)/);
  assert.match(screen, /final active = TickerMode.valuesOf\(context\).enabled/);
  assert.match(screen, /controller.setActive\(active\)/);
  assert.match(screen, /controller.close\(\)/);
});

test('detail actions borrow root playback and expose honest availability without dummy overflow', () => {
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  assert.match(controller, /_playback!\.playCatalogTrack\(/);
  assert.match(controller, /canPlay: \(\) => !_disposed && _active && intent == _intent/);
  assert.match(controller, /_sources\?\.getSource\(target.sourceId\)/);
  const sections = read('lib/features/catalog_detail/common/catalog_detail_sections.dart');
  assert.match(sections, /onMore: \(\) => menu\(track\)/);
  assert.match(sections, /allowMoreWhenDisabled: true/);
  assert.match(sections, /sourceLabel: _availability\(track\)/);
  assert.match(sections, /ArtistRef\(sourceId: album.sourceId, artistId: credit.id\)/);
  assert.match(sections, /navigation.openAlbum\(album.ref\)/);
  assert(!/Material|Cupertino|LinearGradient|Image\.network/.test(sections));
});

test('detail favorites are lazy borrowed projections whose subscription work is registered and drained', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /catalogDetails = CatalogDetailSessions\([\s\S]*?collection: this.collection/);
  const controller = read('lib/features/catalog_detail/common/catalog_detail_controller.dart');
  assert.match(controller, /_collection!\.setFavorite\(reference, favorite: next\)/);
  assert.match(controller, /canOpenActions\(reference\) && !_busy && _favorites.ready/);
  assert.match(controller, /_favorites.close\(\);[\s\S]*?Future.wait<void>\(_pending\)/);
  const favorites = read('lib/features/catalog_detail/common/catalog_detail_favorites.dart');
  assert.match(favorites, /unawaited\([\s\S]*?_track\(\(\) async/);
  assert.match(favorites, /_current\(generation\)/);
  assert.match(favorites, /await subscription.cancel\(\)/);
  assert.match(favorites, /ready = false/);
  assert.match(favorites, /onDone: \(\) => _failed\(generation\)/);
});

test('native detail menu actions remain controlled and dismiss before route navigation', () => {
  const menu = read('lib/features/catalog_detail/common/catalog_detail_track_menu.dart');
  assert.match(menu, /YYContextMenu\(/);
  for (const id of ['play', 'favorite', 'retry-favorites', 'close']) assert(menu.includes(`id: '${id}'`));
  assert(!/setFavorite\(|watchFavorites\(|showDialog|showModalBottomSheet|Material/.test(menu));
  const screen = read('lib/features/catalog_detail/common/catalog_detail_screen.dart');
  assert.match(screen, /controller.prepareTrackActions\(\)/);
  assert.match(screen, /canPop: track == null/);
  assert.match(screen, /ExcludeFocus\([\s\S]*?excluding: track != null/);
  assert.match(screen, /focus\?\.context != null/);
});
