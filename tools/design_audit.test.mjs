import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import test from 'node:test';
import { Script } from 'node:vm';
import { appPath, basePath, brandReplacements, buildOutputs, checkOutputs, compose, cssRules, inventory, literal, read, replaceOnce, root, symbols, verifyFingerprints, walk } from './design_audit.mjs';

const app = read(appPath);
const base = read(basePath);
const sprite = literal(app, 'NEW_ICON_SPRITE');
const css = literal(app, 'POLISH_CSS');

test('all original binary fingerprints, sizes and logical line counts match', () => {
  assert.equal(verifyFingerprints().length, 5);
});

test('independent replacement expression reproduces App.tsx composition byte-for-byte', () => {
  let reference = base.replace(/<svg aria-hidden="true" height="0"[\s\S]*?<\/svg>/, () => sprite.value);
  for (const [before, after] of brandReplacements) reference = reference.replace(before, () => after);
  reference = reference.replace('</head>', () => `<style>${css.value}</style>\n</head>`);
  assert.equal(compose(base, sprite.value, css.value), reference);
  assert.match(reference, /<title>YYMusic/);
  assert(!reference.includes('<div class="brand-name">YYMusic</div>'));
  assert(!reference.includes('<iframe'));
  assert.equal(reference.match(/<symbol id=/g).length, 44);
});

test('ambiguous/missing anchors and template expressions fail closed', () => {
  assert.throws(() => replaceOnce('aa', 'a', 'b'));
  assert.throws(() => compose(base.replace('</head>', ''), sprite.value, css.value));
  assert.throws(() => literal('const A = `${malicious}`;', 'A'));
  assert.throws(() => literal('const A = `a\\n`;', 'A'));
});

test('all SVG geometry and filled shapes are preserved in standalone assets', () => {
  const icons = symbols(sprite.value);
  assert.equal(icons.length, 44);
  assert(!icons.some(icon => /download/i.test(icon.id)));
  for (const icon of icons) {
    const svg = readFileSync(join(root, icon.file), 'utf8');
    assert(svg.includes(`>${icon.body}</svg>`), icon.id);
    assert.match(svg, /viewBox="0 0 24 24"/);
    assert.match(svg, /stroke-width="1.72"/);
  }
  for (const id of ['i-play', 'i-pause', 'i-prev', 'i-next', 'i-more']) {
    assert(icons.find(icon => icon.id === id).body.includes('fill="currentColor"'));
  }
});

test('every CSS block and declaration has a component/token plan', () => {
  const rules = cssRules(css.value, css.valueLine);
  assert.equal(rules.length, 81);
  assert.equal(rules.reduce((count, rule) => count + rule.declarations.length, 0), 203);
  assert.equal(rules.length, (css.value.match(/{/g) ?? []).length);
  assert(rules.every(rule => rule.target && rule.declarations.length));
  assert(rules.some(rule => rule.selector === '.glass' && rule.declarations.some(item => item.value === 'blur(42px) saturate(1.3)')));
  assert.throws(() => cssRules('.unmapped { color: red; }'));
});

test('inventory covers four pages, seven overlays, persistence and responsive exceptions', () => {
  const data = inventory(base, app, css, symbols(sprite.value));
  assert.equal(data.pages.length, 4);
  assert.equal(data.overlays.length, 7);
  assert.equal(data.toggleIds.length, 7);
  assert(data.storageKeys.includes('yymusic-sources'));
  assert(data.mediaQueries.some(item => item.value.includes('max-height: 620px')));
  assert(data.mediaQueries.some(item => item.value.includes('max-width: 599px')));
});

test('inline reference JavaScript is syntactically valid, without executing it', () => {
  const script = base.match(/<script>([\s\S]*?)<\/script>/)?.[1];
  assert(script);
  assert.doesNotThrow(() => new Script(script));
});

test('regeneration is deterministic and all checked-in derived files are current', () => {
  const first = buildOutputs();
  assert.deepEqual(first, buildOutputs());
  checkOutputs(first);
});

test('every icon referenced by the base HTML has a final sprite symbol', () => {
  const ids = new Set(symbols(sprite.value).map(icon => icon.id));
  const refs = [...base.matchAll(/(?:href|xlink:href)="#(i-[a-z-]+)"/g)];
  assert(refs.length > 44);
  for (const match of refs) assert(ids.has(match[1]), `Missing final icon: ${match[1]}`);
});

test('required Phase 0 documents and all local Markdown links exist', () => {
  const required = ['figma_export_manifest', 'design_source_composition', 'design_source_diff', 'html_to_flutter_mapping', 'icon_manifest', 'design_tokens', 'responsive_layout_map', 'visual_parity_plan'];
  for (const name of required) assert(read(`docs/${name}.md`).trim().length > 100, name);
  const docs = ['README.md', 'CHANGELOG.md', ...walk('docs').filter(path => path.endsWith('.md'))];
  for (const path of docs) {
    for (const match of read(path).matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
      const target = match[1].split('#')[0];
      if (!target || /^https?:\/\//.test(target)) continue;
      assert(existsSync(resolve(root, dirname(path), target)), `${path}: broken local link ${target}`);
    }
  }
});
