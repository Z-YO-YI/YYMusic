import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/library_graph_fixture.dart';
import 'library_controller_test.dart' show flushLibrary;

void main() {
  late LibraryGraphFixture f;
  late LibraryController controller;
  setUp(() async {
    f = LibraryGraphFixture(count: 4);
    await f.graph.initialize();
    controller = f.graph.libraryController
      ..start()
      ..selectCategory(LibraryCategory.tracks);
    await flushLibrary();
  });
  tearDown(() => f.close());
  test('missing file is a valid queue reference but not playable', () {
    final track = f.tracks[2];
    expect(controller.canPlay(track), isFalse);
    expect(controller.queueSourcePermit(track)!(), isTrue);
    expect(f.engine.calls, isEmpty);
  });
  test('same reference from a different metadata object is not authorized', () {
    final track = f.tracks.first;
    final clone = Track(
      id: track.id,
      sourceId: track.sourceId,
      sourceType: track.sourceType,
      title: 'different metadata',
      artists: track.artists,
      duration: track.duration,
      localPath: track.localPath,
    );
    expect(clone.ref, track.ref);
    expect(controller.queueSourcePermit(clone), isNull);
  });
  for (final reason in ['refresh', 'category', 'hide', 'close']) {
    test('old source permit stays revoked after $reason', () async {
      final permit = controller.queueSourcePermit(f.tracks.first)!;
      switch (reason) {
        case 'refresh':
          controller.refresh();
          await flushLibrary();
        case 'category':
          controller.selectCategory(LibraryCategory.albums);
        case 'hide':
          controller.setActive(false);
          controller.setActive(true);
        case 'close':
          await controller.close();
      }
      expect(permit(), isFalse);
    });
  }
}
