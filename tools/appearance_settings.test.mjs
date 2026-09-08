import assert from 'node:assert/strict';
import test from 'node:test';
import {read} from './design_audit.mjs';

test('appearance storage is typed and whitelist-only on the existing database', () => {
  const model = read('lib/domain/models/appearance_settings.dart');
  const contract = read('lib/domain/repositories/appearance_settings_repository.dart');
  assert(!/package:flutter|package:drift|dart:io|credentialRef|dynamic/.test(model + contract));
  assert.match(model, /AppearanceSettings\(<redacted>\)/);
  assert.match(contract, /Future<void> save\(AppearanceSettings value\)/);
  const data = read('lib/data/repositories/drift_appearance_settings_repository.dart');
  for (const key of ['themeMode', 'accentPreset', 'customAccent', 'glassEnabled', 'reduceMotion']) assert(data.includes(`'${key}'`));
  assert.match(data, /row.settingKey.isIn\(keys\)/);
  assert.match(data, /_database.transaction\(/);
  assert.match(data, /valueJson.length > 512/);
  assert(!/customStatement|_database.close|SecureCredential|File\(|Directory\(/.test(data));
  assert.match(data, /Future<T>\(\(\) async/);
  assert.match(data, /Future.wait<void>\(_pending\)/);
});

test('root restores one visual state and drains appearance before owned storage', () => {
  const graph = read('lib/app/dependency_graph.dart');
  assert.match(graph, /appearance: appearance/);
  assert.match(graph, /repository: dataServices\?\.appearanceSettings \?\? appearanceRepository/);
  assert(graph.indexOf('await appearanceSettings.initialize()') < graph.indexOf('await playback.initialize()'));
  assert(graph.indexOf('appearanceSettings.close,') < graph.indexOf('services.dispose'));
  const state = read('lib/features/settings/common/appearance_settings_controller.dart');
  assert.match(state, /appearance.addListener\(_changed\)/);
  assert.match(state, /appearance.removeListener\(_changed\)/);
  assert.match(state, /appearance.restore\(/);
  assert.match(state, /while \(_worker != null\)/);
  assert(!/AppDatabase|PlaybackController|\.play\(|credentialRef|log\(|print\(/.test(state));
  const theme = read('lib/design_system/yy_theme.dart');
  assert(!/repository|database|Future<|save\(/i.test(theme));
});

test('native settings reuse the root theme and never access storage or platform plugins', () => {
  const screen = read('lib/features/settings/common/settings_screen.dart');
  const sections = read('lib/features/settings/common/settings_sections.dart');
  assert.match(read('lib/app/yy_music_app.dart').replace(/\s/g, ''), /appearanceSettings:ref.read\(dependencyGraphProvider\).appearanceSettings/);
  assert.match(read('lib/app/app_router.dart'), /SettingsScreen\(/);
  assert.match(screen, /generation != _generation/);
  assert.match(screen, /box.size.width > 0/);
  assert.match(screen, /if \(_dirty\) return/);
  assert.match(screen, /_hex.value.composing.isCollapsed/);
  assert.match(screen, /_panelKey = GlobalKey/);
  assert.match(screen, /widget.routeActive\?\.value \?\? true/);
  assert.match(read('lib/app/app_router.dart'), /currentConfiguration.uri.path/);
  for (const token of ['YYToggle(', 'YYThemeSwatch(', 'YYTextField(', 'YYSegmentedControl<', 'YYSurface(', 'YYRadius.settingsNavigation']) assert(sections.includes(token));
  assert.match(sections, /appearance.setReduceGlass\(!value\)/);
  assert.match(sections, /controller.retry/);
  for (const platform of ['phone', 'tablet', 'windows']) {
    const layout = read(`lib/features/settings/${platform}/${platform}_settings_layout.dart`);
    assert(layout.includes('sections.panel(context)'));
    assert(!/repository|Database|YYAppearanceController\(|PlaybackController\(/.test(layout));
  }
  assert(!/dart:io|package:drift|package:http|package:just_audio|WebView|AppDatabase|\.repository\.|\.initialize\(|\.save\(/.test(screen + sections));
});
