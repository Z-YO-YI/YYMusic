import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_playlist_card.dart';
import 'package:yymusic/design_system/yy_source_card.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  for (final (name, mode, accent, reduced) in const [
    ('light_coral', YYThemeMode.light, '#FF3B5C', false),
    ('dark_jade', YYThemeMode.dark, '#00A67E', false),
    ('light_white_reduced', YYThemeMode.light, '#FFFFFF', true),
  ]) {
    testWidgets(
      'Phase2I collection cards $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final appearance = YYAppearanceController()
          ..setMode(mode)
          ..setCustomAccent(accent)
          ..setReduceGlass(reduced)
          ..setReduceMotion(true);
        addTearDown(appearance.dispose);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            designHarness(
              const _GoldenFrame(
                key: ValueKey('collection-cards-board'),
                child: _CollectionCardsBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('collection-cards-board')),
            matchesGoldenFile('baselines/collection_cards_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(color: YYTheme.of(context).colors.base, child: child),
  );
}

class _CollectionCardsBoard extends StatelessWidget {
  const _CollectionCardsBoard();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YYMusic · Collection Cards', style: YYTypography.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Phase 2I · 受控 Fixture / 130% / 无来源请求、曲库、歌单写入',
          style: YYTypography.caption,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 470,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    YYSourceCard(
                      name: '本地音乐 Fixture',
                      meta: '未读取设备目录',
                      glyph: YYGlyph.folder,
                      statusLabel: '可用',
                      statusTone: YYSourceStatusTone.positive,
                      selected: true,
                      onPressed: _noop,
                    ),
                    SizedBox(height: 10),
                    YYSourceCard(
                      name: '用户 API Fixture',
                      meta: '未发送连接请求',
                      glyph: YYGlyph.cloud,
                      statusLabel: '异常',
                      statusTone: YYSourceStatusTone.error,
                      onPressed: _noop,
                    ),
                    SizedBox(height: 10),
                    YYSourceCard(
                      name: '测试中 Fixture',
                      meta: '未启动计时器',
                      glyph: YYGlyph.refresh,
                      statusLabel: '测试中',
                      statusTone: YYSourceStatusTone.warning,
                      loading: true,
                      onPressed: _noop,
                    ),
                    SizedBox(height: 10),
                    YYSourceCard(
                      name: '停用 Fixture',
                      meta: '受控禁用状态',
                      glyph: YYGlyph.cloud,
                      statusLabel: '已停用',
                      statusTone: YYSourceStatusTone.neutral,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 14.0;
                    final width = (constraints.maxWidth - gap * 2) / 3;
                    const cards = [
                      _PlaylistFixture('喜欢的音乐', '0 首 · Fixture', YYGlyph.heart),
                      _PlaylistFixture('当前队列', '0 首 · Fixture', YYGlyph.queue),
                      _PlaylistFixture('专注工作', '禁用状态', YYGlyph.playlist),
                      _PlaylistFixture('稍后播放', '加载状态', YYGlyph.history),
                    ];
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var index = 0; index < cards.length; index++)
                          SizedBox(
                            width: width,
                            child: YYPlaylistCard(
                              title: cards[index].title,
                              meta: cards[index].meta,
                              glyph: cards[index].glyph,
                              selected: index == 0,
                              loading: index == 3,
                              onPressed: index == 2 ? null : _noop,
                            ),
                          ),
                        SizedBox(
                          width: width,
                          child: const YYPlaylistCard(
                            title: '新建歌单',
                            meta: '仅通知 Fixture',
                            glyph: YYGlyph.plus,
                            variant: YYPlaylistCardVariant.create,
                            onPressed: _noop,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PlaylistFixture {
  const _PlaylistFixture(this.title, this.meta, this.glyph);

  final String title;
  final String meta;
  final YYGlyph glyph;
}

void _noop() {}
