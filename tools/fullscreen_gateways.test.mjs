import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('native fullscreen adapter serializes accepted work and revokes queued commands at close', () => {
  const dart = read('lib/platform/fullscreen/native_fullscreen_gateway.dart');
  assert.match(dart, /_tail\.then/);
  assert.match(dart, /await _tail/);
  assert.match(dart, /_closed = true/);
  assert.match(dart, /_invoke\('detach'\)/);
  assert.match(dart, /on MissingPluginException/);
  assert(!/HWND|invokeMethod<Object\?>\(method,|SystemChrome|Timer\.periodic/.test(dart.replaceAll('HWND, paths or UI flags', 'restricted input')));
  assert(!/NativeFullscreenGateway\(/.test(read('lib/app/yy_music_app.dart')));
});

test('Windows fullscreen preserves exact native restoration state and rejects arbitrary targets', () => {
  const native = read('windows/runner/fullscreen_control.cpp');
  for (const pattern of [/GetWindowPlacement/, /SetWindowPlacement/, /GWL_EXSTYLE/, /MONITOR_DEFAULTTONEAREST/, /rcMonitor/, /SWP_NOACTIVATE/, /std::holds_alternative<std::monostate>/, /WPF_RESTORETOMAXIMIZED/]) assert.match(native, pattern);
  assert(!/FindWindow|EnumWindows|OpenProcess|SetForegroundWindow|SendInput|ChangeDisplaySettings|ShellExecute/.test(native));
  assert.match(read('windows/runner/flutter_window.cpp'), /WM_DISPLAYCHANGE/);
  assert.match(read('windows/runner/window_control.cpp'), /fullscreen_ && !SetFullscreen\(false\)/);
  assert.match(read('integration_test/windows_window_gateway_test.dart'), /Restored \$key/);
  assert.match(native, /normal\.showCmd = SW_SHOWNOACTIVATE/);
  assert.match(native, /!preserve_minimized && placement\.showCmd == SW_SHOWMAXIMIZED/);
  assert.match(native, /style && extended && prepared && position && frame/);
});

test('Android restores original system bars on lifecycle exit without consuming Flutter insets', () => {
  const base = 'android/app/src/main/kotlin/io/github/z_y_o_y_i/yymusic/';
  const native = read(`${base}FullscreenHost.kt`);
  assert.match(native, /BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE/);
  assert.match(native, /getRootWindowInsets/);
  assert.match(native, /original\.visible/);
  assert.match(native, /original\.hidden/);
  assert.match(native, /original\.behavior/);
  assert.match(native, /call\.arguments != null/);
  assert(!/setOnApplyWindowInsetsListener|setDecorFitsSystemWindows|Settings\.Global|WRITE_SETTINGS/.test(native));
  const activity = read(`${base}MainActivity.kt`);
  for (const event of ['onPause', 'onWindowFocusChanged', 'cleanUpFlutterEngine', 'onDestroy']) assert.match(activity, new RegExp(`override fun ${event}`));
});
