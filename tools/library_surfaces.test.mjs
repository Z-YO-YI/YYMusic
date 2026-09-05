import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('library uses three native virtualized layouts and no direct storage or plugin access', () => {
  for (const layout of ['phone/phone_library_layout', 'tablet/tablet_library_layout', 'windows/windows_library_layout']) {
    assert.match(read(`lib/features/library/${layout}.dart`), /CustomScrollView/);
  }
  for (const path of walk('lib/features/library').filter(path => path.endsWith('.dart'))) {
    assert(!/AppDatabase|Drift|dart:io|AudioEngine\(|Fake|Fixture|WebView|credentialRef|baseUrl|localPath|\.network\(/.test(read(path)), path);
  }
  const sections = read('lib/features/library/common/library_sections.dart');
  assert.match(sections, /SliverGrid.builder/);
  assert.match(sections, /SliverList.builder/);
  assert.match(sections, /onLongPress/);
  assert.match(sections, /onSecondaryTapUp/);
  assert.match(sections, /allowMoreWhenDisabled: true/);
});

test('library drains borrowed work before root storage and uses atomic catalog playback', () => {
  const controller = read('lib/features/library/common/library_controller.dart');
  assert.match(controller, /PageRequest\(offset: target\._offset, limit: 20\)/);
  assert.match(controller, /_offset >= 200/);
  assert.match(controller, /token.isCancelled/);
  assert.match(controller, /playback.playCatalogTrack/);
  assert.match(controller, /collection!.setFavorite/);
  assert(!/replaceQueue\(|watchTracks\(|AppDatabase\(|AudioEngine\(/.test(controller));
  assert.match(read('lib/app/dependency_graph.dart'), /libraryController.close,[\s\S]*?services.dispose/);
  assert.match(read('lib/app/app_router.dart'), /LibraryScreen\(/);
});
