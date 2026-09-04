import 'dart:async';
import 'dart:io';

import '../domain/models/domain_failure.dart';
import 'playable_source.dart';

enum NetworkHeadFailureKind { offline, timeout, tls, unknown }

/// Transport-only failure without a URL, header, response body or raw error.
final class NetworkHeadFailure implements Exception {
  const NetworkHeadFailure(this.kind);

  final NetworkHeadFailureKind kind;

  @override
  String toString() => 'NetworkHeadFailure(${kind.name})';
}

abstract interface class NetworkHeadTransport {
  Future<int> head(PlayableSource source, {required Duration timeout});
}

/// Read-only HTTPS transport. Responses are discarded and never persisted.
final class DartIoNetworkHeadTransport implements NetworkHeadTransport {
  DartIoNetworkHeadTransport({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;

  final HttpClient Function() _clientFactory;

  @override
  Future<int> head(PlayableSource source, {required Duration timeout}) async {
    if (source.kind != PlayableSourceKind.networkStream) {
      throw ArgumentError.value(source.kind, 'source', 'must be HTTPS');
    }
    final client = _clientFactory();
    client.connectionTimeout = timeout;
    try {
      final request = await client
          .openUrl('HEAD', source.uri!)
          .timeout(timeout);
      request.followRedirects = false;
      for (final header in source.headers.entries) {
        request.headers.set(header.key, header.value);
      }
      final response = await request.close().timeout(timeout);
      await response.drain<void>().timeout(timeout);
      return response.statusCode;
    } on TimeoutException {
      throw const NetworkHeadFailure(NetworkHeadFailureKind.timeout);
    } on HandshakeException {
      throw const NetworkHeadFailure(NetworkHeadFailureKind.tls);
    } on CertificateException {
      throw const NetworkHeadFailure(NetworkHeadFailureKind.tls);
    } on SocketException {
      throw const NetworkHeadFailure(NetworkHeadFailureKind.offline);
    } on NetworkHeadFailure {
      rethrow;
    } catch (_) {
      throw const NetworkHeadFailure(NetworkHeadFailureKind.unknown);
    } finally {
      client.close(force: true);
    }
  }
}

/// Classifies a short-lived network source before native playback.
///
/// This POC is not wired into production source resolution. It proves the
/// status and transport mapping without retaining media bytes or secrets.
final class NetworkPlayableSourceProbe {
  NetworkPlayableSourceProbe(
    this._transport, {
    this.timeout = const Duration(seconds: 5),
  }) {
    if (timeout <= Duration.zero || timeout > const Duration(seconds: 30)) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'must be between 0 and 30 seconds',
      );
    }
  }

  final NetworkHeadTransport _transport;
  final Duration timeout;

  Future<void> validate(PlayableSource source) async {
    if (source.kind != PlayableSourceKind.networkStream) {
      throw ArgumentError.value(
        source.kind,
        'source',
        'must be a network stream',
      );
    }
    final int statusCode;
    try {
      statusCode = await _transport.head(source, timeout: timeout);
    } on NetworkHeadFailure catch (failure) {
      throw _failure(source, _transportCode(failure.kind));
    } catch (_) {
      throw _failure(source, DomainFailureCode.playbackOpenFailed);
    }
    if (statusCode >= 200 && statusCode < 300) return;
    throw _failure(source, _statusCode(statusCode));
  }

  DomainFailure _failure(PlayableSource source, DomainFailureCode code) =>
      DomainFailure(
        code: code,
        diagnosticId: 'playback.network-probe.${code.name}',
        sourceId: source.track.sourceId,
        retryable: switch (code) {
          DomainFailureCode.networkOffline ||
          DomainFailureCode.networkTimeout ||
          DomainFailureCode.rateLimited ||
          DomainFailureCode.serverError ||
          DomainFailureCode.streamUrlExpired => true,
          _ => false,
        },
      );
}

DomainFailureCode _transportCode(NetworkHeadFailureKind kind) => switch (kind) {
  NetworkHeadFailureKind.offline => DomainFailureCode.networkOffline,
  NetworkHeadFailureKind.timeout => DomainFailureCode.networkTimeout,
  NetworkHeadFailureKind.tls => DomainFailureCode.tlsFailed,
  NetworkHeadFailureKind.unknown => DomainFailureCode.playbackOpenFailed,
};

DomainFailureCode _statusCode(int value) => switch (value) {
  401 => DomainFailureCode.unauthorized,
  403 => DomainFailureCode.forbidden,
  404 => DomainFailureCode.notFound,
  408 => DomainFailureCode.networkTimeout,
  410 => DomainFailureCode.streamUrlExpired,
  429 => DomainFailureCode.rateLimited,
  >= 300 && < 400 => DomainFailureCode.streamUrlExpired,
  >= 500 && < 600 => DomainFailureCode.serverError,
  _ => DomainFailureCode.playbackOpenFailed,
};
