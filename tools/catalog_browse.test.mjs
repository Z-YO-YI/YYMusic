import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('catalog browse shares the root library and stays a read-only data implementation', () => {
  const repository = read('lib/data/repositories/drift_library_repository.dart');
  assert.match(repository, /part 'drift_catalog_browse.dart';/);
  assert.match(repository, /implements\s+LibraryRepository,\s+CatalogSearchRepository,\s+CatalogBrowseRepository/);
  const services = read('lib/app/database_app_data_services.dart');
  assert.match(services, /CatalogBrowseRepository get catalogBrowse => _library/);
  assert.match(read('lib/app/dependency_graph.dart'), /dataServices\?\.catalogBrowse \?\? catalogBrowse/);
  const queries = read('lib/data/repositories/drift_catalog_browse.dart');
  assert.match(queries, /part of 'drift_library_repository.dart';/);
  assert(!/\b(?:INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP)\b|\.transaction\(|AppDatabase\(|dart:io|package:(dio|http)|watchTracks\(/.test(queries));
});

test('catalog browse sorts are closed enums and page entities precede credit expansion', () => {
  const queries = read('lib/data/repositories/drift_catalog_browse.dart');
  for (const sort of ['CatalogTrackSort', 'CatalogAlbumSort', 'CatalogArtistSort']) {
    assert.match(queries, new RegExp(`${sort}\\.`));
  }
  assert.match(queries, /\(item\.browse_sort IS NULL\) ASC/);
  assert.match(queries, /page AS \(SELECT item\.\* FROM ranked item ORDER BY \$order LIMIT \? OFFSET \?\)/);
  assert.match(queries, /FROM page item \$\{artistJoin/);
  assert.match(queries, /Variable<int>\(page\.limit \+ 1\)/);
  assert.match(queries, /Variable<int>\(page\.offset\)/);
  assert.match(queries, /Variable<String>\(artist\.sourceId\)/);
  assert.match(queries, /Variable<String>\(artist\.artistId\)/);
  assert.match(queries, /_searchCheckpoint\(cancellation\)/);
  assert(!/\$\{query\.|\$\{filter\.|\$\{artist\.sourceId\}|\$\{artist\.artistId\}/.test(queries));
});
