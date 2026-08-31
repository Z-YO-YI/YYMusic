import assert from 'node:assert/strict';
import test from 'node:test';
import { read, walk } from './design_audit.mjs';

const sources = walk('lib').filter(path => path.endsWith('.dart'));

test('formal source does not embed WebViews, fixture catalogs or source archives', () => {
  for (const path of sources) {
    assert(!/WebView|InAppWebView|dart:html|SonicGallery|sonic_gallery|LinearGradient|RadialGradient|SweepGradient/.test(read(path)), path);
    assert(!/import\s+['"][^'"]*(design_reference|archive)\//.test(read(path)), path);
  }
  const pubspec = read('pubspec.yaml');
  assert.match(pubspec, /uses-material-design: false/);
  const bundled = [...pubspec.matchAll(/^\s+-\s+(?:asset:\s+)?(assets\/[^\s]+)\s*$/gm)].map(match => match[1]);
  assert.deepEqual(bundled, [
    'assets/icons/yymusic/',
    'assets/fonts/inter/OFL.txt',
    'assets/fonts/noto_sans_sc/OFL.txt',
    'assets/fonts/inter/InterVariable.ttf',
    'assets/fonts/noto_sans_sc/NotoSansSCVariable.ttf',
  ], 'Only audited icons, pinned fonts and licenses may be bundled');
  for (const path of sources) {
    assert(!/package:flutter\/material.dart|SvgPicture\.network|GoogleFonts\./.test(read(path)), path);
  }
});

test('routing and injection packages remain inside the app composition boundary', () => {
  for (const path of sources.filter(path => !path.startsWith('lib/app/'))) {
    assert(!/package:(go_router|flutter_riverpod)\//.test(read(path)), path);
  }
  for (const path of sources.filter(path => path.startsWith('lib/shells/'))) {
    assert(!/DependencyGraph\(|PlaybackController\(|QueueController\(|dart:io|package:dio/.test(read(path)), path);
  }
});

test('native runners are branded and Android release does not use debug signing', () => {
  assert.match(read('android/app/src/main/AndroidManifest.xml'), /android:label="YYMusic"/);
  assert.match(read('windows/runner/main.cpp'), /window\.Create\(L"YYMusic"/);
  assert(!read('android/app/build.gradle.kts').includes('signingConfigs.getByName("debug")'));
});

test('CI validates both debug targets with read-only, pinned actions', () => {
  const workflow = read('.github/workflows/foundation.yml');
  assert.match(workflow, /contents: read/);
  assert.match(workflow, /flutter build windows --debug --no-pub/);
  assert.match(workflow, /flutter build apk --debug --no-pub/);
  const actions = [...workflow.matchAll(/uses: (\S+)/g)].map(match => match[1]);
  assert(actions.length >= 4);
  assert(actions.every(action => /@[a-f0-9]{40}$/.test(action)));
  assert(!/pull_request_target|secrets\.|contents: write/.test(workflow));
});
