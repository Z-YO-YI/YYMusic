import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'deterministic_pcm_wav.dart';

const String _certificateBase64 = String.fromEnvironment(
  'YYMUSIC_POC_TLS_CERT_B64',
);
const String _privateKeyBase64 = String.fromEnvironment(
  'YYMUSIC_POC_TLS_KEY_B64',
);

const String pocRequestHeaderName = 'X-YYMusic-Poc';
const String pocRequestHeaderValue = 'phase-4d-public-fixture';

final class ControlledHttpsAudioServer {
  static Future<ControlledHttpsAudioServer> start() async {
    if (_certificateBase64.isEmpty || _privateKeyBase64.isEmpty) {
      throw StateError('The ephemeral Phase 4D TLS fixture is unavailable');
    }
    final context = SecurityContext(withTrustedRoots: false)
      ..useCertificateChainBytes(base64Decode(_certificateBase64))
      ..usePrivateKeyBytes(base64Decode(_privateKeyBase64));
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    final fixture = ControlledHttpsAudioServer._(
      server,
      buildDeterministicPcmWav(),
    );
    fixture._subscription = server.listen(
      fixture._handle,
      onError: (Object _, StackTrace _) {},
    );
    return fixture;
  }

  ControlledHttpsAudioServer._(this._server, this._wavBytes);

  final HttpServer _server;
  final Uint8List _wavBytes;
  late final StreamSubscription<HttpRequest> _subscription;
  int audioGetCount = 0;
  int expectedHeaderCount = 0;

  int get port => _server.port;

  Uri uri(String path) => Uri(
    scheme: 'https',
    host: InternetAddress.loopbackIPv4.address,
    port: port,
    path: path,
  );

  HttpClient trustedClient() {
    final client = HttpClient();
    client.badCertificateCallback = (
      X509Certificate _,
      String host,
      int checkedPort,
    ) => host == InternetAddress.loopbackIPv4.address && checkedPort == port;
    return client;
  }

  void resetAudioRequestCounters() {
    audioGetCount = 0;
    expectedHeaderCount = 0;
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path == '/audio.wav') {
        await _serveAudio(request);
        return;
      }
      if (path == '/timeout') {
        await Future<void>.delayed(const Duration(seconds: 2));
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      final statusCode = switch (path) {
        '/status/401' => HttpStatus.unauthorized,
        '/status/403' => HttpStatus.forbidden,
        '/status/404' => HttpStatus.notFound,
        '/status/429' => HttpStatus.tooManyRequests,
        '/status/503' => HttpStatus.serviceUnavailable,
        _ => HttpStatus.notFound,
      };
      request.response.statusCode = statusCode;
      await request.response.close();
    } on HttpException {
      // A timeout probe can close its socket before the delayed response.
    } on SocketException {
      // The fixture owns no durable state and logs no peer information.
    }
  }

  Future<void> _serveAudio(HttpRequest request) async {
    final hasExpectedHeader =
        request.headers.value(pocRequestHeaderName) == pocRequestHeaderValue;
    if (hasExpectedHeader) expectedHeaderCount++;
    if (!hasExpectedHeader) {
      request.response.statusCode = HttpStatus.unauthorized;
      await request.response.close();
      return;
    }

    final range = _byteRange(
      request.headers.value(HttpHeaders.rangeHeader),
      _wavBytes.length,
    );
    final start = range?.$1 ?? 0;
    final end = range?.$2 ?? _wavBytes.length - 1;
    final body = Uint8List.sublistView(_wavBytes, start, end + 1);
    request.response.headers.contentType = ContentType('audio', 'wav');
    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    request.response.contentLength = body.length;
    if (range != null) {
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$end/${_wavBytes.length}',
      );
    }
    if (request.method == 'GET') {
      audioGetCount++;
      request.response.add(body);
    }
    await request.response.close();
  }
}

(int, int)? _byteRange(String? value, int length) {
  if (value == null) return null;
  final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(value);
  if (match == null) return null;
  final start = int.tryParse(match.group(1)!);
  final requestedEnd = match.group(2)!.isEmpty
      ? length - 1
      : int.tryParse(match.group(2)!);
  if (start == null ||
      requestedEnd == null ||
      start < 0 ||
      start >= length ||
      requestedEnd < start) {
    return null;
  }
  return (start, requestedEnd.clamp(start, length - 1));
}
