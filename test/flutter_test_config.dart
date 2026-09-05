import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/windows/windows_window_gateway.dart';

/// Widget/golden tests have no Win32 runner. Model the missing plugin explicitly;
/// channel unit tests replace this handler, and integration_test uses real IPC.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(WindowsWindowGateway.channelName),
          (_) async => throw MissingPluginException(),
        );
  });
  await testMain();
}
