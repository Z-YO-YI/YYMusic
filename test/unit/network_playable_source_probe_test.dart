import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/domain_failure.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/network_playable_source_probe.dart';
import 'package:yymusic/playback/playable_source.dart';

void main() {
  test(
    'accepts 2xx and forwards only the ephemeral validated source',
    () async {
      final transport = _FakeNetworkHeadTransport(statusCode: 204);
      final probe = NetworkPlayableSourceProbe(
        transport,
        timeout: const Duration(milliseconds: 750),
      );
      final source = _networkSource();

      await probe.validate(source);

      expect(transport.sources, [same(source)]);
      expect(transport.timeouts, [const Duration(milliseconds: 750)]);
      expect(source.toString(), isNot(contains('private-value')));
    },
  );

  test('maps HTTP status without retaining URI or header values', () async {
    final cases = <int, DomainFailureCode>{
      301: DomainFailureCode.streamUrlExpired,
      401: DomainFailureCode.unauthorized,
      403: DomainFailureCode.forbidden,
      404: DomainFailureCode.notFound,
      408: DomainFailureCode.networkTimeout,
      410: DomainFailureCode.streamUrlExpired,
      429: DomainFailureCode.rateLimited,
      503: DomainFailureCode.serverError,
      451: DomainFailureCode.playbackOpenFailed,
    };

    for (final entry in cases.entries) {
      final probe = NetworkPlayableSourceProbe(
        _FakeNetworkHeadTransport(statusCode: entry.key),
      );
      final failure = await _failureOf(probe.validate(_networkSource()));
      expect(failure.code, entry.value, reason: 'HTTP ${entry.key}');
      expect(failure.sourceId, 'source-rest');
      expect(failure.toString(), isNot(contains('audio.example')));
      expect(failure.toString(), isNot(contains('private-value')));
    }
  });

  test('maps typed transport failures and discards unknown errors', () async {
    final cases = <Object, DomainFailureCode>{
      const NetworkHeadFailure(NetworkHeadFailureKind.offline):
          DomainFailureCode.networkOffline,
      const NetworkHeadFailure(NetworkHeadFailureKind.timeout):
          DomainFailureCode.networkTimeout,
      const NetworkHeadFailure(NetworkHeadFailureKind.tls):
          DomainFailureCode.tlsFailed,
      const NetworkHeadFailure(NetworkHeadFailureKind.unknown):
          DomainFailureCode.playbackOpenFailed,
      StateError('https://secret.invalid Authorization: private-value'):
          DomainFailureCode.playbackOpenFailed,
    };

    for (final entry in cases.entries) {
      final probe = NetworkPlayableSourceProbe(
        _FakeNetworkHeadTransport(error: entry.key),
      );
      final failure = await _failureOf(probe.validate(_networkSource()));
      expect(failure.code, entry.value);
      expect(failure.toString(), isNot(contains('secret.invalid')));
      expect(failure.toString(), isNot(contains('private-value')));
    }
  });

  test('rejects non-network input and unsafe timeout configuration', () async {
    final probe = NetworkPlayableSourceProbe(_FakeNetworkHeadTransport());
    final local = PlayableSource.localFile(
      track: _track,
      path: r'C:\Music\tone.wav',
    );

    await expectLater(probe.validate(local), throwsArgumentError);
    expect(
      () => NetworkPlayableSourceProbe(
        _FakeNetworkHeadTransport(),
        timeout: Duration.zero,
      ),
      throwsArgumentError,
    );
  });
}

final _track = TrackRef(
  trackId: 'network-track',
  sourceId: 'source-rest',
  sourceType: MusicSourceType.rest,
);

PlayableSource _networkSource() => PlayableSource.networkStream(
  track: _track,
  uri: Uri.parse('https://audio.example.test/stream?token=private-value'),
  headers: const {'X-YYMusic-Poc': 'private-value'},
);

Future<DomainFailure> _failureOf(Future<void> operation) async {
  try {
    await operation;
  } on DomainFailure catch (failure) {
    return failure;
  }
  throw TestFailure('Expected DomainFailure');
}

final class _FakeNetworkHeadTransport implements NetworkHeadTransport {
  _FakeNetworkHeadTransport({this.statusCode = 200, this.error});

  final int statusCode;
  final Object? error;
  final List<PlayableSource> sources = [];
  final List<Duration> timeouts = [];

  @override
  Future<int> head(PlayableSource source, {required Duration timeout}) async {
    sources.add(source);
    timeouts.add(timeout);
    final failure = error;
    if (failure != null) throw failure;
    return statusCode;
  }
}
