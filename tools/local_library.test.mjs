import test from 'node:test';
import assert from 'node:assert/strict';
import { read } from './design_audit.mjs';

test('local overview reads one bounded snapshot on the existing library connection', () => {
  const repository = read('lib/data/repositories/drift_library_repository.dart');
  assert.match(repository, /CatalogBrowseRepository,\s+LocalLibraryRepository/);
  assert.match(repository, /part 'drift_local_library.dart'/);
  const query = read('lib/data/repositories/drift_local_library.dart');
  assert.equal((query.match(/\.customSelect\(/g) ?? []).length, 1);
  assert.match(query, /FROM tracks WHERE source_type = 'local'/);
  assert.match(query, /FROM track_stats CROSS JOIN folder_stats LEFT JOIN folder_page/);
  assert.match(query, /LIMIT \? OFFSET \?/);
  assert.match(query, /Variable\(page.limit\), Variable\(page.offset\)/);
  assert(!/\b(?:INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP)\b|AppDatabase\(|watchTracks\(|track_artists|\.transaction\(|dart:io/.test(query));
});

test('local overview excludes private media fields and watches only index tables', () => {
  const query = read('lib/data/repositories/drift_local_library.dart');
  assert(!/local_path|content_uri|grant_ref|\.localPath|\.contentUri|\.grantRef/.test(query));
  const watch = query.split('Stream<void> _watchLocalChanges()')[1];
  assert.match(watch, /TableUpdateQuery.onAllTables/);
  assert.match(watch, /_database.trackRecords/);
  assert.match(watch, /_database.localFolderRecords/);
  assert(!/\.get\(|\.watch\(|favoriteRecords|queueEntryRecords/.test(watch));
  assert.match(query, /_guard\('local-overview'/);
  assert((query.match(/_searchCheckpoint\(cancellation\)/g) ?? []).length >= 2);
});

test('local overview domain and contract remain immutable and platform independent', () => {
  const model = read('lib/domain/models/local_library_overview.dart');
  assert.match(model, /Map.unmodifiable/);
  assert.match(model, /List.unmodifiable\(folders\)/);
  assert.match(model, /folderCount - page.offset/);
  assert.match(model, /LocalFolderSummary\(<redacted>\)/);
  assert.match(model, /LocalLibraryOverview\(<redacted>\)/);
  const contract = read('lib/domain/repositories/local_library_repository.dart');
  assert(!/package:flutter|package:drift|dart:io|scan\(|pickFiles\(|delete|saveGrant/.test(contract));
  assert.match(contract, /SearchCancellation\? cancellation/);
});

test('local music root borrows the same repository and drains before database shutdown', () => {
  assert.match(read('lib/app/database_app_data_services.dart'), /LocalLibraryRepository get localLibrary => _library/);
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /localMusic = LocalMusicController\(repository: this.localLibrary\)/);
  assert.match(graph, /localMusic.dispose\(\)/);
  assert(graph.indexOf('localMusic.close,') < graph.indexOf('services.dispose'));
  const state = read('lib/features/local_music/common/local_music_controller.dart');
  assert.match(state, /_token\?\.cancel\(\)/);
  assert.match(state, /!identical\(content, expected\)/);
  assert.match(state, /Future.wait<void>\(_pending\)/);
  assert(!/AppDatabase|PlaybackController\(|scan\(|setFavorite\(|saveQueue\(/.test(state));
});

test('local native layouts reuse exact folder glyph and controlled opaque surfaces', () => {
  const panel = read('lib/features/local_music/common/local_music_panel.dart');
  assert.match(panel, /ModalRoute.isCurrentOf\(context\)/);
  assert.match(panel, /TickerMode.valuesOf\(context\).enabled/);
  assert.match(panel, /size.width > 0 &&/);
  const sections = read('lib/features/local_music/common/local_music_sections.dart');
  assert.match(sections, /YYGlyph.folder/);
  assert.match(sections, /YYRadius.metricCard/);
  assert.match(sections, /YYRadius.folderRow/);
  assert(!/YYGlass|File\(|Directory\(|scan\(|pickFiles\(|grantRef/.test(sections));
  for (const platform of ['phone', 'tablet', 'windows']) {
    assert.match(read(`lib/features/local_music/${platform}/${platform}_local_music_layout.dart`), /extends StatelessWidget/);
  }
});
