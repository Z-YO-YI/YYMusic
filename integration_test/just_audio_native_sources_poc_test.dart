import 'dart:io';

import 'just_audio_android_sources_poc_test.dart' as android_sources;
import 'just_audio_native_https_poc_test.dart' as https;
import 'just_audio_native_local_poc_test.dart' as local;

void main() {
  if (Platform.isAndroid) {
    android_sources.main();
  } else {
    local.main();
  }
  https.main();
}
