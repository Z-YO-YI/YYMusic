import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('sound settings hosts use fixed OS targets and never claim an observed route', () => {
  const android = read('android/app/src/main/kotlin/io/github/z_y_o_y_i/yymusic/AudioOutputHost.kt');
  assert.match(android, /Intent\(Settings\.ACTION_SOUND_SETTINGS\)/);
  assert.match(android, /call\.arguments != null/);
  assert.match(android, /ActivityNotFoundException/);
  assert.match(android, /SecurityException/);
  assert.match(android, /hasWindowFocus\(\)/);
  assert.match(android, /"observation" to "unknown"/);
  assert.match(android, /fun close\(\) = channel\.setMethodCallHandler\(null\)/);
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android\.settings\.SOUND_SETTINGS/);
  const windows = read('windows/runner/audio_output_control.cpp');
  assert.match(windows, /L"ms-settings:sound"/);
  assert.match(windows, /launched > 32 \? "opened" : "failed"/);
  assert.match(windows, /GetForegroundWindow\(\) != GetHandle\(\)/);
  assert.match(windows, /EncodableValue\("unknown"\)/);
  assert.match(read('windows/runner/CMakeLists.txt'), /"audio_output_control\.cpp"/);
  assert.match(read('windows/runner/CMakeLists.txt'), /"shell32\.lib"/);
  assert(!/getDevices|setPreferredDevice|setVolume/.test(android + windows));
});
