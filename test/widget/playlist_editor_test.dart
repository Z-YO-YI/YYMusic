import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_dialog.dart';
import 'package:yymusic/design_system/yy_text_field.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/library/common/library_controller.dart';
import 'package:yymusic/features/library/common/library_screen.dart';
import 'package:yymusic/features/playlists/common/playlist_controller.dart';
import 'package:yymusic/features/playlists/common/playlist_editor_host.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_domain_repositories.dart';
import '../support/library_graph_fixture.dart';
import 'library_screen_test.dart' show mountLibrary, closeLibrary;

Playlist editorPlaylist({
  String id = 'custom',
  String name = '夜间聆听',
  SystemPlaylistType? system,
}) => Playlist(
  id: id,
  name: name,
  createdAt: DateTime.utc(2026, 9, 8),
  updatedAt: DateTime.utc(2026, 9, 8),
  isSystem: system != null,
  systemType: system,
);

Finder editorKey(Object key) => find.byWidgetPredicate(
  (widget) => widget.key is ValueKey && (widget.key! as ValueKey).value == key,
);
Future<void> settlePlaylist(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(Duration.zero);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  await tester.pumpAndSettle();
}

Future<void> showPlaylists(
  WidgetTester tester,
  LibraryGraphFixture fixture, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 1000),
}) async {
  await mountLibrary(tester, fixture, platform: platform, size: size);
  fixture.graph.libraryController.selectCategory(LibraryCategory.playlists);
  await settlePlaylist(tester);
}

Future<void> openPlaylistEditor(WidgetTester tester, Object key) async {
  await tester.ensureVisible(editorKey(key));
  await tester.pumpAndSettle();
  await tester.tap(editorKey(key));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 1000)),
    ('tablet', YYPlatform.android, Size(800, 1000)),
    ('windows', YYPlatform.windows, Size(1024, 900)),
  ]) {
    testWidgets(
      '$name creates, renames and explicitly confirms deletion through the shared projection',
      (tester) async {
        final fixture = LibraryGraphFixture();
        await showPlaylists(tester, fixture, platform: platform, size: size);
        final initialCalls = List.of(fixture.engine.calls);
        await openPlaylistEditor(tester, 'playlist-create');
        expect(
          find.byType(YYBottomSheet),
          name == 'phone' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(YYDialog),
          name == 'phone' ? findsNothing : findsOneWidget,
        );
        await tester.enterText(find.byType(EditableText), '  我的歌单  ');
        await tester.tap(editorKey('playlist-submit'));
        await settlePlaylist(tester);
        expect(find.byType(YYTextField), findsNothing);
        final created =
            fixture.graph.libraryController.page.items.single as Playlist;
        expect(created.name, '我的歌单');
        expect(await fixture.collection.getPlaylist(created.id), isNotNull);
        await openPlaylistEditor(tester, ('playlist-rename', created.id));
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          '我的歌单',
        );
        await tester.enterText(find.byType(EditableText), '远行');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settlePlaylist(tester);
        expect((await fixture.collection.getPlaylist(created.id))!.name, '远行');
        await openPlaylistEditor(tester, ('playlist-delete', created.id));
        expect(fixture.collection.playlistMutationCalls, ['create', 'rename']);
        expect(find.textContaining('不删除歌曲文件或来源内容'), findsOneWidget);
        await tester.tap(editorKey('playlist-cancel'));
        await tester.pumpAndSettle();
        expect(await fixture.collection.getPlaylist(created.id), isNotNull);
        await openPlaylistEditor(tester, ('playlist-delete', created.id));
        await tester.tap(editorKey('playlist-submit'));
        await settlePlaylist(tester);
        expect(await fixture.collection.getPlaylist(created.id), isNull);
        expect(fixture.graph.libraryController.page.items, isEmpty);
        expect(fixture.engine.calls, initialCalls);
        expect(tester.takeException(), isNull);
        await closeLibrary(tester, fixture);
      },
    );
  }

  testWidgets(
    'draft and selection survive Phone/Tablet replacement, rotation and keyboard insets',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      final text = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      const value = TextEditingValue(
        text: '夜间聆听 • 草稿',
        selection: TextSelection(baseOffset: 0, extentOffset: 4),
      );
      text.value = value;
      for (final size in [
        const Size(600, 960),
        const Size(1024, 768),
        const Size(844, 390),
        const Size(390, 1000),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).controller,
          same(text),
        );
        expect(text.value, value);
        expect(tester.takeException(), isNull, reason: '$size');
      }
      tester.view.padding = const FakeViewPadding(top: 30, bottom: 24);
      tester.view.viewInsets = const FakeViewPadding(bottom: 620);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(editorKey('playlist-submit'));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(editorKey('playlist-submit')).bottom,
        lessThanOrEqualTo(380),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(editorKey('playlist-cancel'));
      await tester.pumpAndSettle();
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'invalid names and IME composition never write; failure preserves draft for retry',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      final field = find.byType(EditableText);
      final text = tester.widget<EditableText>(field).controller;
      for (final name in ['   ', 'x' * 513, '夜\u0001曲']) {
        await tester.enterText(field, name);
        await tester.tap(editorKey('playlist-submit'));
        await settlePlaylist(tester);
        expect(text.text, name);
        expect(find.textContaining('请输入1–512'), findsOneWidget);
      }
      await tester.showKeyboard(field);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '夜曲',
          composing: TextRange(start: 0, end: 2),
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump();
      expect(text.value.composing.isCollapsed, isFalse);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settlePlaylist(tester);
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      text.value = text.value.copyWith(composing: TextRange.empty);
      fixture.collection.onPlaylistMutation = (_, _) async {
        throw StateError('private-editor-error');
      };
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      expect(find.text('歌单操作未完成，请重试。'), findsOneWidget);
      expect(find.textContaining('private-editor-error'), findsNothing);
      expect(text.text, '夜曲');
      fixture.collection.onPlaylistMutation = null;
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      expect(
        (fixture.graph.libraryController.page.items.single as Playlist).name,
        '夜曲',
      );
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'busy disables duplicate submits; dismissal does not cancel accepted creation',
    (tester) async {
      final fixture = LibraryGraphFixture();
      final gate = Completer<void>();
      fixture.collection.onPlaylistMutation = (_, _) => gate.future;
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      await tester.enterText(find.byType(EditableText), '保存中的歌单');
      final submit = tester
          .widget<YYButton>(editorKey('playlist-submit'))
          .onPressed!;
      submit();
      submit();
      await settlePlaylist(tester);
      expect(fixture.collection.playlistMutationCalls, ['create']);
      expect(
        tester.widget<YYTextField>(find.byType(YYTextField)).enabled,
        isFalse,
      );
      expect(
        tester.widget<YYButton>(editorKey('playlist-submit')).loading,
        isTrue,
      );
      await tester.tap(editorKey('playlist-cancel'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<YYButton>(editorKey('playlist-create')).onPressed,
        isNull,
      );
      gate.complete();
      await settlePlaylist(tester);
      expect(find.byType(YYTextField), findsNothing);
      expect(
        (fixture.graph.libraryController.page.items.single as Playlist).name,
        '保存中的歌单',
      );
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'system playlists have no edit controls and forged UI requests are rejected',
    (tester) async {
      final system = editorPlaylist(system: SystemPlaylistType.favorites);
      final fixture = LibraryGraphFixture(
        collections: FakeCollectionRepository(playlists: [system]),
      );
      await showPlaylists(tester, fixture);
      expect(editorKey(('playlist-rename', system.id)), findsNothing);
      expect(editorKey(('playlist-delete', system.id)), findsNothing);
      final scope = PlaylistEditorScope.maybeOf(
        tester.element(find.byType(LibraryScreen)),
      )!;
      scope.open!(PlaylistEditorRequest.delete(system));
      await tester.pumpAndSettle();
      expect(find.byType(YYBottomSheet), findsNothing);
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'rename of a concurrently deleted target fails without recreating it',
    (tester) async {
      final fixture = LibraryGraphFixture(
        collections: FakeCollectionRepository(playlists: [editorPlaylist()]),
      );
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, ('playlist-rename', 'custom'));
      await tester.enterText(find.byType(EditableText), '保留我的草稿');
      await fixture.collection.deletePlaylist('custom');
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      expect(find.text('此歌单或歌曲条目已不存在，请刷新列表。'), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '保留我的草稿',
      );
      expect(await fixture.collection.getPlaylist('custom'), isNull);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'Windows Escape restores focus; typing Space does not trigger root playback',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await showPlaylists(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(599, 900),
      );
      final buttonContext = tester.element(editorKey('playlist-create'));
      FocusScope.of(buttonContext).nextFocus();
      await tester.pump();
      final previous = FocusManager.instance.primaryFocus;
      final calls = List.of(fixture.engine.calls);
      await openPlaylistEditor(tester, 'playlist-create');
      expect(find.byType(YYDialog), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'space name');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(fixture.engine.calls, calls);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(YYDialog), findsNothing);
      expect(FocusManager.instance.primaryFocus, same(previous));
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'Android Back and keyboard navigation close drafts without writing',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(YYBottomSheet), findsNothing);
      expect(find.byType(LibraryScreen), findsOneWidget);
      await openPlaylistEditor(tester, 'playlist-create');
      await tester.enterText(find.byType(EditableText), '不保存');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(YYTextField), findsNothing);
      await tester.tap(editorKey('nav-library'));
      await tester.pumpAndSettle();
      await openPlaylistEditor(tester, 'playlist-create');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'covering the Shell with another route discards only the unsubmitted draft',
    (tester) async {
      final fixture = LibraryGraphFixture();
      await showPlaylists(tester, fixture);
      final router = GoRouter.of(tester.element(find.byType(LibraryScreen)));
      await openPlaylistEditor(tester, 'playlist-create');
      unawaited(router.push<void>('/settings/licenses'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(YYTextField), findsNothing);
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'root close drains a UI-accepted write after the editor unmounts',
    (tester) async {
      final fixture = LibraryGraphFixture();
      final gate = Completer<void>();
      fixture.collection.onPlaylistMutation = (_, _) => gate.future;
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      await tester.enterText(find.byType(EditableText), '关闭后仍保存');
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      var closed = false;
      final closing = fixture.graph.close().then((_) => closed = true);
      await tester.pump();
      expect(closed, isFalse);
      gate.complete();
      await closeGraph(tester, fixture.graph);
      await closing;
      expect(fixture.collection.playlistMutationCalls, ['create']);
      expect(
        (await fixture.collection.watchPlaylists().first).single.name,
        '关闭后仍保存',
      );
      expect(tester.takeException(), isNull);
      await tester.runAsync(fixture.disposeFakes);
    },
  );

  testWidgets('zero drawable area preserves the draft without overflow', (
    tester,
  ) async {
    final fixture = LibraryGraphFixture();
    await showPlaylists(tester, fixture);
    await openPlaylistEditor(tester, 'playlist-create');
    await tester.enterText(find.byType(EditableText), '恢复后继续编辑');
    tester.view.physicalSize = Size.zero;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '恢复后继续编辑',
    );
    expect(fixture.collection.playlistMutationCalls, isEmpty);
    await closeLibrary(tester, fixture);
  });

  testWidgets('missing storage disables the scope without fabricating a list', (
    tester,
  ) async {
    final controller = PlaylistController();
    await tester.pumpWidget(
      designHarness(
        PlaylistEditorHost(
          controller: controller,
          platform: YYPlatform.android,
          active: true,
          child: Builder(
            builder: (context) {
              expect(PlaylistEditorScope.maybeOf(context)!.open, isNull);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.close();
  });

  testWidgets('late completion cannot dismiss a subsequently opened draft', (
    tester,
  ) async {
    final fixture = LibraryGraphFixture();
    final gate = Completer<void>();
    fixture.collection.onPlaylistMutation = (_, _) => gate.future;
    await showPlaylists(tester, fixture);
    final open = PlaylistEditorScope.maybeOf(
      tester.element(find.byType(LibraryScreen)),
    )!.open!;
    await openPlaylistEditor(tester, 'playlist-create');
    await tester.enterText(find.byType(EditableText), '第一个歌单');
    await tester.tap(editorKey('playlist-submit'));
    await settlePlaylist(tester);
    await tester.tap(editorKey('playlist-cancel'));
    await tester.pumpAndSettle();
    void reopen() {
      if (!fixture.graph.playlists.busy) {
        fixture.graph.playlists.removeListener(reopen);
        open(const PlaylistEditorRequest.create());
      }
    }

    fixture.graph.playlists.addListener(reopen);
    gate.complete();
    await settlePlaylist(tester);
    expect(find.byType(YYTextField), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
    expect(fixture.graph.libraryController.page.items.length, 1);
    await closeLibrary(tester, fixture);
  });

  testWidgets(
    'native name field selects and copies only on explicit user action',
    (tester) async {
      final fixture = LibraryGraphFixture();
      var clipboard = '粘贴的歌单';
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.hasStrings') {
            return {'value': clipboard.isNotEmpty};
          }
          if (call.method == 'Clipboard.getData') {
            reads++;
            return {'text': clipboard};
          }
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      final field = find.byType(EditableText);
      await tester.enterText(field, 'YY music');
      await tester.pumpAndSettle();
      final state = tester.state<EditableTextState>(field);
      final caret = state.renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 4),
      );
      await tester.longPressAt(
        state.renderEditable.localToGlobal(caret.center),
      );
      await tester.pumpAndSettle();
      expect(state.widget.controller.selection.isCollapsed, isFalse);
      expect(reads, 0);
      await tester.tap(find.text('复制'));
      await tester.pumpAndSettle();
      expect(clipboard, 'music');
      clipboard = '粘贴的歌单';
      state.widget.controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 8,
      );
      state.showToolbar();
      await tester.pumpAndSettle();
      await tester.tap(find.text('粘贴'));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(state.widget.controller.text, '粘贴的歌单');
      expect(fixture.collection.playlistMutationCalls, isEmpty);
      await closeLibrary(tester, fixture);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'modal tab focus remains trapped and busy Space cannot reach the player',
    (tester) async {
      final fixture = LibraryGraphFixture();
      final gate = Completer<void>();
      fixture.collection.onPlaylistMutation = (_, _) => gate.future;
      await showPlaylists(
        tester,
        fixture,
        platform: YYPlatform.windows,
        size: const Size(1024, 900),
      );
      await openPlaylistEditor(tester, 'playlist-create');
      final calls = List.of(fixture.engine.calls);
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<YYDialog>(),
          isNotNull,
        );
      }
      await tester.enterText(find.byType(EditableText), '后台保存');
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(fixture.engine.calls, calls);
      gate.complete();
      await settlePlaylist(tester);
      await closeLibrary(tester, fixture);
    },
  );

  testWidgets(
    'closed-editor write failures remain visible on returning to Library',
    (tester) async {
      final fixture = LibraryGraphFixture();
      final gate = Completer<void>();
      fixture.collection.onPlaylistMutation = (_, _) => gate.future;
      await showPlaylists(tester, fixture);
      await openPlaylistEditor(tester, 'playlist-create');
      await tester.enterText(find.byType(EditableText), '保存失败的草稿');
      await tester.tap(editorKey('playlist-submit'));
      await settlePlaylist(tester);
      await tester.tap(editorKey('playlist-cancel'));
      await tester.pumpAndSettle();
      await tester.tap(editorKey('nav-home'));
      await tester.pumpAndSettle();
      gate.completeError(StateError('private-late-failure'));
      await settlePlaylist(tester);
      await tester.tap(editorKey('nav-library'));
      await tester.pumpAndSettle();
      expect(find.text('关闭面板后的歌单操作未完成'), findsOneWidget);
      expect(find.text('新建歌单：歌单操作未完成，请重试。'), findsOneWidget);
      expect(find.textContaining('private-late-failure'), findsNothing);
      expect(fixture.graph.libraryController.page.items, isEmpty);
      await tester.tap(find.text('知道了'));
      await tester.pumpAndSettle();
      expect(find.text('关闭面板后的歌单操作未完成'), findsNothing);
      await closeLibrary(tester, fixture);
    },
  );
}
