import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('native search borrows contracts and has separate virtualized layouts', () => {
  for (const target of ['phone/phone_search_layout', 'tablet/tablet_search_layout', 'windows/windows_search_layout']) {
    assert.match(read(`lib/features/search/${target}.dart`), /CustomScrollView/);
  }
  for (const path of walk('lib/features/search').filter(path => path.endsWith('.dart'))) {
    assert(!/AppDatabase|Drift|AudioEngine\(|dart:io|Fake|Fixture|WebView|credentialRef|baseUrl|localPath|\.network\(/.test(read(path)), path);
  }
  const ui = read('lib/features/search/common/search_sections.dart');
  assert.match(ui, /SliverList.builder/);
  assert.match(ui, /YYSearchField/);
  assert.match(ui, /实时在线搜索和音乐导入仍在开发/);
  assert.match(ui, /确认清除搜索历史/);
  assert.match(ui, /只清除搜索记录，不删除歌曲/);
});

test('search keeps bounded independent generations and drains before storage', () => {
  const controller = read('lib/features/search/common/search_controller.dart');
  assert.match(controller, /Duration\(milliseconds: 300\)/);
  assert.match(controller, /PageRequest\(offset: _offset, limit: 20\)/);
  assert.match(controller, /_offset >= 200/);
  assert.match(controller, /_token.cancel\(\)/);
  assert.match(controller, /_historyTail.then/);
  assert.match(controller, /_validIntent\(intent\)/);
  assert(!/replaceQueue\(|watchTracks\(|getTrack\(/.test(controller));
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /search = CatalogSearchController\(/);
  assert.match(graph, /search.close,[\s\S]*?services.dispose/);
  const services = read('lib/app/database_app_data_services.dart');
  assert.match(services, /CatalogSearchRepository get catalogSearch => _library/);
  assert.match(services, /_searchHistory.dispose\(\)/);
  const player = read('lib/playback/playback_controller.dart');
  assert.match(player, /Future<void> playCatalogTrack/);
  assert.match(player, /entry.track == track/);
});
