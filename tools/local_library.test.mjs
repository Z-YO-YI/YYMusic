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
