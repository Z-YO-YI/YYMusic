import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:just_audio_platform_interface/method_channel_just_audio.dart';
import 'package:yymusic/playback/windows_just_audio_error_compatibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const mainChannel = MethodChannel('com.ryanheise.just_audio.methods');
  const codec = StandardMethodCodec();
  late JustAudioPlatform original;
  late MethodChannelJustAudio stock;
  late List<String> channels;
  late List<String> calls;

  setUp(() {
    original = JustAudioPlatform.instance;
    stock = MethodChannelJustAudio();
    JustAudioPlatform.instance = stock;
    channels = [];
    calls = [];
    messenger.setMockMethodCallHandler(mainChannel, (call) async {
      calls.add(call.method);
      return <String, Object?>{};
    });
  });
  tearDown(() {
    JustAudioPlatform.instance = original;
    messenger.setMockMethodCallHandler(mainChannel, null);
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  Future<AudioPlayerPlatform> player(String id) async {
    configureWindowsJustAudioErrors(isWindows: true);
    final channel = 'com.ryanheise.just_audio.events.$id';
    channels.add(channel);
    messenger.setMockMethodCallHandler(MethodChannel(channel), (call) async {
      calls.add('$id:${call.method}');
      return null;
    });
    return JustAudioPlatform.instance.init(InitRequest(id: id));
  }

  Future<void> emit(String id, ByteData data) async {
    await messenger.handlePlatformMessage(
      'com.ryanheise.just_audio.events.$id',
      data,
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  ByteData event(int index, {int? errorCode}) => codec.encodeSuccessEnvelope({
    'processingState': 3,
    'updateTime': 1000,
    'updatePosition': 125000,
    'bufferedPosition': 500000,
    'duration': 10000000,
    'currentIndex': index,
    'errorCode': errorCode,
    'errorMessage': errorCode == null ? null : 'structured-error',
  });

  ByteData error() => codec.encodeErrorEnvelope(
    code: 'unknown',
    message: 'private-native-locator',
    details: {'header': 'private-header'},
  );

  test('registration is Windows-only, idempotent and preserves overrides', () {
    configureWindowsJustAudioErrors(isWindows: false);
    expect(JustAudioPlatform.instance, same(stock));
    configureWindowsJustAudioErrors(isWindows: true);
    final adapted = JustAudioPlatform.instance;
    expect(adapted, isNot(same(stock)));
    configureWindowsJustAudioErrors(isWindows: true);
    expect(JustAudioPlatform.instance, same(adapted));
    final custom = _CustomPlatform();
    JustAudioPlatform.instance = custom;
    configureWindowsJustAudioErrors(isWindows: true);
    expect(JustAudioPlatform.instance, same(custom));
    expect(calls, isEmpty);
  });

  test(
    'ordinary and structured-error events keep their native fields',
    () async {
      final native = await player('normal');
      final events = <PlaybackEventMessage>[];
      final subscription = native.playbackEventMessageStream.listen(events.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);
      await emit('normal', event(2));
      await emit('normal', event(2, errorCode: 7));
      expect(events, hasLength(2));
      expect(events.first.processingState, ProcessingStateMessage.ready);
      expect(events.first.currentIndex, 2);
      expect(events.first.updatePosition, const Duration(milliseconds: 125));
      expect(
        events.first.updateTime,
        DateTime.fromMillisecondsSinceEpoch(1000),
      );
      expect(events.first.errorCode, isNull);
      expect(events.last.errorCode, 7);
      expect(events.last.errorMessage, 'structured-error');
      expect(calls.where((call) => call == 'init'), hasLength(1));
    },
  );

  test(
    'legacy error before first event has unknown identity and no secrets',
    () async {
      final native = await player('early');
      final events = <PlaybackEventMessage>[];
      final subscription = native.playbackEventMessageStream.listen(events.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);
      await emit('early', error());
      final failure = events.single;
      expect(failure.processingState, ProcessingStateMessage.idle);
      expect(failure.errorCode, -1);
      expect(failure.errorMessage, 'Windows audio playback failed');
      expect(failure.currentIndex, isNull);
      expect(failure.duration, isNull);
      expect(failure.updatePosition, Duration.zero);
      expect(failure.bufferedPosition, Duration.zero);
      expect(failure.icyMetadata, isNull);
    },
  );

  test('legacy error preserves last position but never advances it', () async {
    final native = await player('position');
    final events = <PlaybackEventMessage>[];
    final subscription = native.playbackEventMessageStream.listen(events.add);
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);
    await emit('position', event(5));
    await emit('position', error());
    expect(events, hasLength(2));
    expect(events.last.errorCode, -1);
    expect(events.last.currentIndex, 5);
    expect(events.last.updatePosition, const Duration(milliseconds: 125));
    expect(events.last.bufferedPosition, const Duration(milliseconds: 500));
    expect(events.last.duration, const Duration(seconds: 10));
    expect(events.last.errorMessage, isNot(contains('private')));
    expect(events.last.androidAudioSessionId, isNull);
  });

  test(
    'malformed envelopes become safe failures instead of swallowed errors',
    () async {
      final native = await player('malformed');
      final events = <PlaybackEventMessage>[];
      final subscription = native.playbackEventMessageStream.listen(events.add);
      addTearDown(subscription.cancel);
      await Future<void>.delayed(Duration.zero);
      await emit(
        'malformed',
        codec.encodeSuccessEnvelope('private-bad-payload'),
      );
      expect(events.single.errorCode, -1);
      expect(events.single.errorMessage, 'Windows audio playback failed');
      expect(events.single.currentIndex, isNull);
    },
  );

  test(
    'cached broadcast stream owns only one native listener and cancellation',
    () async {
      final native = await player('shared');
      final stream = native.playbackEventMessageStream;
      expect(native.playbackEventMessageStream, same(stream));
      expect(stream.isBroadcast, isTrue);
      final first = <PlaybackEventMessage>[];
      final second = <PlaybackEventMessage>[];
      final a = stream.listen(first.add);
      final b = stream.listen(second.add);
      addTearDown(a.cancel);
      addTearDown(b.cancel);
      await Future<void>.delayed(Duration.zero);
      await emit('shared', error());
      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(calls.where((call) => call == 'shared:listen'), hasLength(1));
      await a.cancel();
      expect(calls.where((call) => call == 'shared:cancel'), isEmpty);
      await b.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((call) => call == 'shared:cancel'), hasLength(1));
      await emit('shared', error());
      expect(first, hasLength(1));
      expect(second, hasLength(1));
    },
  );

  test('two player identities never share the last event', () async {
    final a = await player('a');
    final b = await player('b');
    final first = <PlaybackEventMessage>[];
    final second = <PlaybackEventMessage>[];
    final subA = a.playbackEventMessageStream.listen(first.add);
    final subB = b.playbackEventMessageStream.listen(second.add);
    addTearDown(subA.cancel);
    addTearDown(subB.cancel);
    await Future<void>.delayed(Duration.zero);
    await emit('a', event(4));
    await emit('b', event(9));
    await emit('a', error());
    await emit('b', error());
    expect(first.last.currentIndex, 4);
    expect(second.last.currentIndex, 9);
    expect(first.last.errorCode, -1);
    expect(second.last.errorCode, -1);
  });
}

final class _CustomPlatform extends MethodChannelJustAudio {}
