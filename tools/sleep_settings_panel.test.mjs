import assert from 'node:assert/strict';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('native sleep panel borrows guarded root actions and existing modal surfaces', () => {
  const panel = read('lib/features/player/common/sleep_settings_panel.dart');
  for (const required of ['YYBottomSheet(', 'YYDialog(', 'sleepAction(',
    'PlaybackSleepChoice.values', 'ListenableBuilder(', '_allowed(generation)',
    'ModalRoute.isCurrentOf(context)', 'TickerMode.valuesOf(context)', 'LayoutBuilder(',
    'liveRegion: true', 'PlaybackSleepPhase.failed']) {
    assert(panel.includes(required), required);
  }
  assert(!/\bTimer\b|dart:io|Repository|PlaybackController\(|WebView|showDialog/.test(panel));
  const card = read('lib/design_system/yy_option_card.dart');
  for (const required of ['FocusableActionDetector(', 'LogicalKeyboardKey.enter',
    'LogicalKeyboardKey.space', 'selected: widget.selected', 'minHeight: 74',
    'EdgeInsets.all(13)', 'YYRadius.button', 'theme.motion(']) {
    assert(card.includes(required), required);
  }
  assert(!/PlaybackPresenter|PlaybackController|Repository|Timer|dart:io/.test(card));
});
