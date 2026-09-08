import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/playlists/common/playlist_add_dialog.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../support/playlist_add_harness.dart';
import '../support/playlist_content_harness.dart';
import 'library_screen_test.dart' show mountLibrary, closeLibrary;

Finder newNameField() => find.descendant(
  of: find.byKey(const ValueKey('playlist-add-name')),
  matching: find.byType(EditableText),
);

Future<void> enterNewName(WidgetTester tester, String name) async {
  await tester.ensureVisible(newNameField());
  await tester.enterText(newNameField(), name);
  await tester.pump();
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in [
    (YYPlatform.android, const Size(390, 1000)),
    (YYPlatform.android, const Size(800, 1100)),
    (YYPlatform.windows, const Size(1440, 1000)),
  ]) {
    testWidgets(
      '$platform $size creates from an empty picker with the full unavailable reference',
      (tester) async {
        final f = CatalogDetailGraphFixture(trackCount: 5);
        await mountDetail(tester, f, platform: platform, size: size);
        await openDetailPicker(tester, f);
        expect(find.textContaining('还没有自定义歌单'), findsOneWidget);
        final state = pickerState(tester);
        state.input.text = '独立筛选草稿';
        await enterNewName(tester, '  新的夜晚  ');
        final before = f.collection.playlistMutationCalls.length;
        await tester.ensureVisible(pickerButton('新建并添加'));
        await tester.tap(pickerButton('新建并添加'));
        await settleContent(tester);
        expect(find.textContaining('已新建“新的夜晚”并添加歌曲'), findsOneWidget);
        expect(f.collection.playlistMutationCalls.skip(before), [
          'create-with-entry',
        ]);
        final parent = (await f.collection.watchPlaylists().first).single;
        expect(parent.name, '新的夜晚');
        expect(
          (await f.collection.getPlaylistEntries(parent.id)).single.track,
          f.repository.trackData[2].ref,
        );
        expect(f.engine.calls, isEmpty);
        await tester.tap(pickerButton('完成'));
        await settleContent(tester);
        expect(f.graph.playlistAdds.retainedSessionCount, 0);
        expect(tester.takeException(), isNull);
        await closeDetail(tester, f);
      },
    );
  }
  testWidgets(
    'native IME validation and retained draft callbacks cannot create the wrong name',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester);
      for (final invalid in [' ', 'a' * 513]) {
        await enterNewName(tester, invalid);
        expect(
          tester.widget<YYButton>(pickerButton('新建并添加')).onPressed,
          isNull,
        );
      }
      await enterNewName(tester, 'bad\nname');
      expect(state.nameInput.text, 'badname');
      state.nameInput.text = 'bad\nname';
      await tester.pump();
      expect(tester.widget<YYButton>(pickerButton('新建并添加')).onPressed, isNull);
      await enterNewName(tester, '旧草稿');
      final old = tester.widget<YYButton>(pickerButton('新建并添加')).onPressed!;
      state.nameInput.value = const TextEditingValue(
        text: '新',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      );
      await tester.pump();
      old();
      expect(tester.widget<YYButton>(pickerButton('新建并添加')).onPressed, isNull);
      state.nameInput.value = const TextEditingValue(
        text: '新草稿',
        selection: TextSelection.collapsed(offset: 3),
      );
      await tester.pump();
      old();
      await settleContent(tester);
      expect(f.collection.playlistMutationCalls, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleContent(tester);
      expect((await f.collection.watchPlaylists().first).single.name, '新草稿');
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'covered or closed create callbacks cannot write and the next picker owns a new draft',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      await enterNewName(tester, '保持名称');
      final state = pickerState(tester);
      final old = tester.widget<YYButton>(pickerButton('新建并添加')).onPressed!;
      final navigator = Navigator.of(
        tester.element(find.byType(PlaylistAddDialog)),
        rootNavigator: true,
      );
      unawaited(
        navigator.push<void>(
          RawDialogRoute<void>(
            transitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => const Center(child: Text('覆盖')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      old();
      await settleContent(tester);
      expect(f.collection.playlistMutationCalls, isEmpty);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(pickerState(tester), same(state));
      await tester.binding.handlePopRoute();
      await settleContent(tester);
      await openDetailPicker(tester, f);
      old();
      await settleContent(tester);
      expect(pickerState(tester).nameInput.text, isEmpty);
      expect(f.collection.playlistMutationCalls, isEmpty);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'name selection and composing draft survive rotation zero size and keyboard viewport',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      final state = pickerState(tester);
      state.input.text = '筛选草稿';
      state.nameInput.value = const TextEditingValue(
        text: '名称草稿',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
        composing: TextRange(start: 0, end: 4),
      );
      final draft = state.nameInput.value;
      for (final size in [
        const Size(800, 1100),
        const Size(1024, 768),
        Size.zero,
        const Size(590, 480),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(pickerState(tester), same(state));
        expect(state.nameInput.value, draft);
        expect(state.input.text, '筛选草稿');
        expect(tester.takeException(), isNull);
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(state.nameInput.value, draft);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'selection read failure remains visible while an independent create can succeed',
    (tester) async {
      final f = CatalogDetailGraphFixture(trackCount: 5);
      f.collection.selectionReader = (_, _) async =>
          throw StateError('private-marker');
      await mountDetail(tester, f);
      await openDetailPicker(tester, f);
      expect(find.text('歌单暂不可选'), findsOneWidget);
      await enterNewName(tester, '继续创建');
      await tester.ensureVisible(pickerButton('新建并添加'));
      await tester.tap(pickerButton('新建并添加'));
      await settleContent(tester);
      expect(find.textContaining('已新建“继续创建”'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect((await f.collection.watchPlaylists().first).length, 1);
      await closeDetail(tester, f);
    },
  );
  testWidgets(
    'busy double create is one command and dismissed failure remains in Library without a parent',
    (tester) async {
      final f = LibraryGraphFixture(count: 5);
      await mountLibrary(tester, f);
      f.graph.libraryController.selectCategory(LibraryCategory.tracks);
      await settleContent(tester);
      final row = find.byKey(ValueKey(f.tracks.first.ref));
      await tester.ensureVisible(row);
      await tester.longPress(row);
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加到歌单'));
      await settleContent(tester);
      await enterNewName(tester, '不会留下半成品');
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      f.collection.onPlaylistMutation = (_, _) async {
        await gate.future;
        throw StateError('private-marker');
      };
      final submit = tester.widget<YYButton>(pickerButton('新建并添加')).onPressed!;
      submit();
      submit();
      await settleContent(tester);
      expect(f.collection.playlistMutationCalls, ['create-with-entry']);
      expect(tester.widget<YYButton>(pickerButton('新建并添加')).onPressed, isNull);
      await tester.ensureVisible(pickerButton('关闭'));
      await tester.tap(pickerButton('关闭'));
      await settleContent(tester);
      gate.complete();
      await settleContent(tester);
      expect(find.textContaining('歌曲条目：'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(await f.collection.watchPlaylists().first, isEmpty);
      await closeLibrary(tester, f);
    },
  );
}
