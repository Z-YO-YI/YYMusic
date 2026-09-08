import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('playlist editor borrows the root writer and checks request identity after accepted writes', () => {
  const host = read('lib/features/playlists/common/playlist_editor_host.dart');
  assert(!/AppDatabase|Drift|dart:io|watchPlaylists|getPlaylist\(|savePlaylist\(|AudioEngine|WebView|Fake|Fixture/.test(host));
  assert.match(host, /if \(!mounted\) return/);
  assert.match(host, /if \(generation != _generation\)/);
  assert.match(host, /final generation = \+\+_generation/);
  assert.match(host, /PlaylistEditorKind.delete => widget.controller.deletePlaylist/);
  assert.match(host, /只删除歌单及其条目，不删除歌曲文件或来源内容/);
  assert.match(host, /request.playlist\?\.isSystem == true/);
  assert.match(host, /canPop: request == null/);
  assert.match(host, /MediaQuery.viewInsetsOf/);
  assert.match(host, /YYBottomSheet/);
  assert.match(host, /YYDialog/);
  const router = read('lib/app/app_router.dart');
  assert.match(router, /PlaylistEditorHost\([\s\S]*?child: frame/);
  assert.match(read('lib/app/yy_music_app.dart'), /playlistController: ref.read\(dependencyGraphProvider\).playlists/);
});

test('form field uses native done semantics and shared non-Material editing chrome', () => {
  const field = read('lib/design_system/yy_text_field.dart');
  const search = read('lib/design_system/yy_search_field.dart');
  for (const text of [field, search]) {
    assert.match(text, /YYSelectionHandles/);
    assert.match(text, /yyEditingMenu/);
    assert(!/package:flutter\/material|WebView/.test(text));
  }
  assert.match(field, /TextInputAction.done/);
  assert.match(field, /composing\s*.isCollapsed/);
  assert(!/YYSearchField|TextInputAction.search|清空搜索/.test(field));
  assert.match(search, /TextInputAction.search/);
});
