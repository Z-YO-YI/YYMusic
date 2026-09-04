import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_bootstrap.dart';
import 'package:yymusic/app/app_data_services.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/domain/repositories/collection_repository.dart';
import 'package:yymusic/domain/repositories/library_repository.dart';
import 'package:yymusic/domain/repositories/lyrics_repository.dart';
import 'package:yymusic/domain/repositories/music_source_repository.dart';
import 'package:yymusic/platform/contracts/secure_credential_gateway.dart';

import '../support/fake_domain_repositories.dart';

void main() {
  testWidgets('bootstrap shows loading, then owns and disposes injected data', (
    tester,
  ) async {
    final completer = Completer<AppDataServices>();
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.windows,
        dataServicesFactory: (_) => completer.future,
      ),
    );
    expect(find.text('YYMusic 正在准备本地数据'), findsOneWidget);

    completer.complete(services);
    await tester.pumpAndSettle();
    expect(find.text('YYMusic 正在准备本地数据'), findsNothing);
    expect(find.byType(YYMusicApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(services.disposeCount, 1);
  });

  testWidgets('bootstrap reports a fixed log-safe initialization failure', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.android,
        dataServicesFactory: (_) async =>
            throw StateError('private-database-path-marker'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YYMusic 无法初始化本地数据'), findsOneWidget);
    expect(find.textContaining('private-database-path-marker'), findsNothing);
  });

  testWidgets('late data completion is disposed after bootstrap unmounts', (
    tester,
  ) async {
    final completer = Completer<AppDataServices>();
    final services = _FakeAppDataServices();
    await tester.pumpWidget(
      AppBootstrap(
        platform: YYPlatform.windows,
        dataServicesFactory: (_) => completer.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    completer.complete(services);
    await tester.pump();

    expect(services.disposeCount, 1);
  });
}

final class _FakeAppDataServices implements AppDataServices {
  @override
  final LibraryRepository library = FakeLibraryRepository();

  @override
  final CollectionRepository collection = FakeCollectionRepository();

  @override
  final LyricsRepository lyrics = FakeLyricsRepository();

  @override
  final MusicSourceRepository musicSources = FakeMusicSourceRepository();

  @override
  final SecureCredentialGateway credentials = FakeSecureCredentialGateway();

  int disposeCount = 0;

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    await library.dispose();
    await (collection as FakeCollectionRepository).dispose();
    await (musicSources as FakeMusicSourceRepository).dispose();
  }
}
