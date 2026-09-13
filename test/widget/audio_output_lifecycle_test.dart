import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_audio_output_gateway.dart';
import '../support/fake_fullscreen_gateway.dart';
import '../support/fake_window_gateway.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final platform in YYPlatform.values) {
    testWidgets(
      '$platform refreshes only on foreground transitions and detaches on unmount',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final gateway = FakeAudioOutputGateway();
        final graph = DependencyGraph(audioOutputGateway: gateway);
        await graph.initialize();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [dependencyGraphProvider.overrideWithValue(graph)],
            child: YYMusicApp(
              platform: platform,
              fullscreenGateway: FakeFullscreenGateway(),
              windowGateway: FakeWindowGateway(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final observer = graph.audioOutput;
        expect(gateway.calls, ['initialize']);
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await tester.pump(Duration.zero);
        expect(gateway.calls, ['initialize']);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(gateway.calls, ['initialize', 'refresh']);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(gateway.calls, ['initialize', 'refresh']);
        expect(graph.audioOutput, same(observer));
        await tester.pumpWidget(const SizedBox.shrink());
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        expect(gateway.calls, ['initialize', 'refresh']);
        await closeGraph(tester, graph);
        expect(gateway.calls, ['initialize', 'refresh', 'close']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
