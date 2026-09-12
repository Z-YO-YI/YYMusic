import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import test from 'node:test';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('independent queue route borrows root state, bounded projection and original native components', () => {
  const router = read('lib/app/app_router.dart');
  assert.match(router, /path: '\/queue'/);
  assert.match(router, /_restorePath\('\/queue'\)/);
  assert.match(read('lib/app/yy_music_app.dart'), /queueController: ref.read\(dependencyGraphProvider\).queue/);
  const binding = read('lib/features/queue/common/queue_page_controller.dart');
  for (const guard of ['identical(queue.state, _expected)', 'row.entryId != entry.id', 'row.reference != entry.track', 'row.addedAt != entry.addedAt', 'snapshot.totalCount != _expected.entries.length', 'snapshot.currentQueueEntryId != _expected.currentEntryId']) assert(binding.includes(guard));
  assert.match(binding, /sessions.open\(SystemPlaylistType.queue\)/);
  assert.match(binding, /read.refreshQueueProjection\(\)/);
  assert.match(binding, /read.removeListener\(_readChanged\)/);
  assert.match(binding, /queue.removeListener\(_rootChanged\)/);
  const screen = read('lib/features/queue/common/queue_screen.dart');
  for (const token of ['YYBottomSheet(', 'YYDialog(', 'PopScope(', 'ModalRoute.isCurrentOf', 'controller.invalidate()', 'controller.close()']) assert(screen.includes(token));
  const sections = read('lib/features/queue/common/queue_sections.dart');
  for (const token of ['YYQueueTile(', 'allowManagementWhenDisabled: valid', 'retryEdit(', 'canRetryEdit(', 'QueueEdit.move(', 'QueueEdit.remove(', 'QueueEdit.clear(']) assert(sections.includes(token));
  for (const folder of ['common', 'phone', 'tablet', 'windows']) {
    for (const file of readdirSync(new URL(`../lib/features/queue/${folder}/`, import.meta.url))) {
      const source = read(`lib/features/queue/${folder}/${file}`);
      assert.doesNotMatch(source, /WebView|LinearGradient|RadialGradient|SweepGradient|Icons\.|AudioPlayer\(|PlaybackController\(|QueueController\(|Database\(/);
    }
  }
});
