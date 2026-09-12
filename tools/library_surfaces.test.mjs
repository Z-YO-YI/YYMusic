import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

test('library queue menus capture root and source, reuse original glyphs and guarded root feedback', () => {
  const menu = read('lib/features/library/common/library_track_menu.dart');
  for (const token of ['YYContextMenu(', "id: 'next'", "id: 'queue'", 'YYGlyph.next', 'YYGlyph.listPlus', 'enabled: canInsert']) assert(menu.includes(token));
  const screen = read('lib/features/library/common/library_screen.dart');
  for (const token of ['_menuQueue = widget.queue?.state', '_queueEpoch++', 'ModalRoute.isCurrentOf', 'widget.queue?.removeListener(_queueChanged)', 'generation != _menuGeneration']) assert(screen.includes(token));
  const actions = read('lib/features/library/common/library_queue_actions.dart');
  for (const token of ['prepareInsertion(expected, track.ref', 'queue.submitEdit(', 'pagePermit() && sourcePermit!()', 'identical(noticeIdentity, _noticeIdentity)']) assert(actions.includes(token));
  const controller = read('lib/features/library/common/library_controller.dart');
  assert(controller.includes('page.items.any((item) => identical(item, track))'));
  const feedback = read('lib/features/queue/common/queue_operation_feedback.dart');
  for (const token of ['queue.canRetryEdit(failure)', 'queue.retryEdit(failure, canEdit: permit)', 'queue.dismissEditFailure(failure)', 'liveRegion: true']) assert(feedback.includes(token));
  assert(!/QueueController\(|PlaybackController\(|Repository|WebView/.test(actions));
});

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
  assert.match(controller, /offset: target\._offset,[\s\S]*?limit: \(200 - target\._offset\).clamp\(1, 20\)/);
  assert.match(controller, /result.items.take\(request.limit\)/);
  assert.match(controller, /_offset >= 200/);
  assert.match(controller, /token.isCancelled/);
  assert.match(controller, /playback.playCatalogTrack/);
  assert.match(controller, /collection!.setFavorite/);
  assert(!/replaceQueue\(|watchTracks\(|AppDatabase\(|AudioEngine\(/.test(controller));
  assert.match(read('lib/app/dependency_graph.dart'), /libraryController.close,[\s\S]*?services.dispose/);
  assert.match(read('lib/app/app_router.dart'), /LibraryScreen\(/);
});
