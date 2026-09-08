import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('playlist windows stay bounded and reject obsolete group callbacks before any new query', () => {
  const controller = read('lib/features/playlists/common/playlist_content_controller.dart');
  assert.match(controller, /pageSize = 20, maxVisibleCount = 200/);
  assert.match(controller, /_active && isCurrent && !busy/);
  assert.match(controller, /showNextWindow\(PlaylistContent expected\)/);
  assert.match(controller, /showPreviousWindow\(PlaylistContent expected\)/);
  assert.equal((controller.match(/!identical\(content, expected\)/g) ?? []).length, 3);
  assert.match(controller, /PageRequest\(limit: limit, offset: offset\)/);
  assert.match(controller, /result.page.offset != offset/);
  assert.match(controller, /offset >= result.totalCount/);
  assert.match(controller, /\(result.totalCount - 1\) ~\/ maxVisibleCount/);
  assert(!/\.addAll\(|getPlaylistEntries\(|getTrack\(|HttpClient|AppDatabase|dart:io/.test(controller));
});

test('native group navigation displays ranges with original controls and route-owned scroll', () => {
  const sections = read('lib/features/playlists/common/playlist_content_sections.dart');
  assert.match(sections, /SliverList.builder/);
  assert.match(sections, /_windowNavigation\(PlaylistContent snapshot/);
  assert.match(sections, /Wrap\(/);
  assert.match(sections, /if \(canInteract\(\)\) controller.showNextWindow\(snapshot\)/);
  assert.match(sections, /if \(canInteract\(\)\) controller.showPreviousWindow\(snapshot\)/);
  assert(!sections.includes('完整大歌单浏览仍在开发'));
  const screen = read('lib/features/playlists/common/playlist_content_screen.dart');
  assert.match(screen, /controller.isCurrent && offset != _shownOffset/);
  assert.match(screen, /mounted && _active && _menu == null/);
  assert.match(screen, /scroll.jumpTo\(0\)/);
});
