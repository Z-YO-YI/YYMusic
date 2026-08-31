import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
export const sourceRoot = 'design_reference/figma_export';
export const basePath = `${sourceRoot}/src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html`;
export const appPath = `${sourceRoot}/src/App.tsx`;
export const masterPath = 'design_reference/YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md';
export const expected = [
  ['design_reference/YYMusic_HTML.zip', 74024, null, 'd75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee'],
  [appPath, 17621, 506, '20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39'],
  [basePath, 218239, 3710, '81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229'],
  [`${sourceRoot}/package.json`, 600, 27, 'c2d99ed2073126d401a3a9b1a2b1691e998058e9fe14da7105857f8a853e38d5'],
  [masterPath, 71837, null, '5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf'],
];

export const read = path => readFileSync(join(root, path), 'utf8');
export const sha = value => createHash('sha256').update(value).digest('hex');
export const lineCount = text => text.split('\n').length - (text.endsWith('\n') ? 1 : 0);
const lineAt = (text, index) => text.slice(0, index).split('\n').length;
const unique = items => [...new Set(items)];
const cell = text => String(text).replaceAll('|', '&#124;').replaceAll('\n', ' ');
const table = (headers, rows) => [headers, headers.map(() => '---'), ...rows].map(row => `| ${row.map(cell).join(' | ')} |`).join('\n');
const json = value => `${JSON.stringify(value, null, 2)}\n`;

export function verifyFingerprints() {
  return expected.map(([path, bytes, lines, hash]) => {
    const data = readFileSync(join(root, path));
    assert.equal(data.length, bytes, `${path}: size mismatch; audit the changed source before proceeding`);
    assert.equal(sha(data), hash, `${path}: SHA-256 mismatch; update design_source_diff.md, do not silently accept`);
    if (lines !== null) assert.equal(lineCount(data.toString('utf8')), lines, `${path}: line mismatch`);
    return { path, bytes, lines, sha256: hash };
  });
}

// Extract data only. Never evaluate the imported React/HTML JavaScript.
export function literal(text, name) {
  const marker = `const ${name} = \``;
  const start = text.indexOf(marker);
  assert(start >= 0 && text.indexOf(marker, start + 1) < 0, `${name}: must occur exactly once`);
  const end = text.indexOf('`;', start + marker.length);
  assert(end > start, `${name}: missing closing delimiter`);
  const value = text.slice(start + marker.length, end);
  assert(!value.includes('${') && !value.includes('`') && !value.includes('\\'), `${name}: unsupported template expressions/escapes`);
  return { value, line: lineAt(text, start), valueLine: lineAt(text, start + marker.length) };
}

export function replaceOnce(text, before, after) {
  assert.equal(text.split(before).length - 1, 1, `Expected exactly one ${before}`);
  return text.replace(before, () => after);
}

export const brandReplacements = [
  ['<div class="brand-name">YYMusic</div>', '<div class="brand-name">YY Listener</div>'],
  ['<div class="brand-subtitle">YOUR MUSIC, YOUR WAY</div>', '<div class="brand-subtitle">本地账户</div>'],
];

export function compose(base, sprite, css) {
  const marker = '<svg aria-hidden="true" height="0"';
  assert.equal(base.split(marker).length - 1, 1, 'Expected exactly one hidden sprite');
  const start = base.indexOf(marker);
  const end = base.indexOf('</svg>', start);
  assert(end > start, 'Missing sprite closing tag');
  let html = base.slice(0, start) + sprite + base.slice(end + '</svg>'.length);
  for (const [before, after] of brandReplacements) html = replaceOnce(html, before, after);
  return replaceOnce(html, '</head>', `<style>${css}</style>\n</head>`);
}

export function symbols(sprite) {
  const entries = [...sprite.matchAll(/<symbol id="(i-[a-z-]+)" viewBox="(0 0 24 24)">([\s\S]*?)<\/symbol>/g)];
  assert.equal(entries.length, 44, 'Expected all 44 final symbols');
  assert.equal(unique(entries.map(item => item[1])).length, 44, 'Duplicate icon IDs');
  return entries.map((match) => ({
    id: match[1], viewBox: match[2], body: match[3], offset: match.index,
    file: `assets/icons/yymusic/${match[1].slice(2)}.svg`,
  }));
}

const plans = [
  [/^body$/, 'YYTypography / font.features'],
  [/brand-|sidebar-footer/, 'YYProfileHeader / profile.size, typography, ring; footer deduplication'],
  [/^\.nav-item/, 'YYNavigationItem / radius.navigation, accent, selectionIndicator; Phone adaptation'],
  [/^\.icon$/, 'YYIcons / icon.strokeWidth'],
  [/^\.(page-title|section-title)/, 'YYTypography / pageTitle, sectionTitle'],
  [/^\.hero-stage-disc/, 'YYArtworkPlaceholder / heroDisc geometry, ring, shadow.heroDisc'],
  [/^\.hero/, 'YYHero / typography.hero, radius.hero, shadow.hero'],
  [/^\.floating-note/, 'YYFloatingNowPlaying / radius.floatingNote, radius.floatingArtwork'],
  [/^\.button-primary/, 'YYButton / typography.button, shadow.primaryButton, hover'],
  [/^\.icon-button/, 'YYIconButton / radius.iconButton, shadow.iconButton'],
  [/^\.album/, 'YYAlbumCard / typography.albumTitle, radius.album, shadow.album[-hover]'],
  [/now-artwork/, 'YYPlayerArtwork / radius.playerArtwork, shadow.playerArtwork.light|dark; specificity exception'],
  [/^\.track-art/, 'YYTrackTile / radius.trackArtwork'],
  [/^\.queue-item-art/, 'YYQueueTile / radius.queueArtwork'],
  [/^\.range/, 'YYSlider / trackHeight, thumbSize, ring, hoverScale; fullscreen variants'],
  [/^\.transport-button/, 'YYTransportButton / shadow.primaryControl, hoverScale, pressed'],
  [/^\.player-control/, 'YYDesktopPlayerBar / shadow.playerControl'],
  [/^\.surface-card/, 'YYSurface / shadow.surface'],
  [/^\.glass$/, 'YYGlassSurface / glass.blur, glass.saturation; clipped platform calibration'],
  [/^\.sidebar$/, 'YYWindowsSidebar, YYTabletNavigationRail / radius.sidebar; Phone adaptation'],
  [/^\.now-panel$/, 'YYNowPlayingInspector / radius.nowPanel'],
  [/^\.track-row/, 'YYTrackTile / radius.trackRow'],
  [/^\.source-/, 'YYSourceCard / radius.sourceIcon, radius.sourceStatus'],
  [/^\.(dialog|now-dialog)/, 'YYDialog, FullscreenPlayerPage / radius.dialog; immersive specificity'],
  [/^\.context-menu/, 'YYContextMenu / radius.contextMenu'],
  [/^\.settings-nav-item/, 'YYSettingsNavigation / radius.settingsNav'],
  [/^\.playlist-/, 'YYPlaylistCard / radius.playlistCard, radius.playlistIcon'],
  [/^\.badge/, 'YYBadge / typography.badge'],
  [/^\.metric-card/, 'YYMetricCard / radius.metric'],
  [/^\.folder-row/, 'YYFolderRow / radius.folder'],
  [/^\.drop-zone/, 'YYDropZone / radius.dropZone'],
  [/^\.now-panel-action-icon/, 'YYNowPlayingAction / radius.nowPanelAction'],
  [/^\.search-input/, 'YYSearchField / typography.search'],
  [/^\.(lyric-primary|fullscreen-lyric-line)/, 'YYLyricsLine / typography.lyrics, activeDot.ring'],
  [/^\.lyrics-player-dock/, 'YYLyricsPlayerDock / radius.lyricsDock; responsive reflow'],
  [/^\.art-/, 'YYArtworkPlaceholder / fixture palette and geometry; never production catalog'],
];

export function cssRules(css, firstLine = 1) {
  const clean = css.replace(/\/\*[\s\S]*?\*\//g, comment => comment.replace(/[^\n]/g, ' '));
  const rulePattern = /([^{}]+)\{([^{}]*)\}/g;
  const matches = [...clean.matchAll(rulePattern)];
  assert.equal(clean.replace(rulePattern, '').trim(), '', 'Unsupported/unparsed CSS');
  return matches.map((match, index) => {
    const selector = match[1].trim().replace(/\s+/g, ' ');
    const target = plans.find(([pattern]) => pattern.test(selector))?.[1];
    assert(target, `Unmapped selector: ${selector}`);
    const declarations = match[2].split(';').map(value => value.trim()).filter(Boolean).map(value => {
      const colon = value.indexOf(':');
      assert(colon > 0, `Invalid CSS declaration ${value}`);
      return { property: value.slice(0, colon).trim(), value: value.slice(colon + 1).trim().replace(/\s+/g, ' ') };
    });
    return { index: index + 1, line: firstLine + lineAt(clean, match.index + match[1].search(/\S/)) - 1, selector, declarations, target };
  });
}

export function walk(path) {
  return readdirSync(join(root, path), { withFileTypes: true }).sort((a, b) => a.name < b.name ? -1 : 1).flatMap(entry => {
    assert(!entry.isSymbolicLink(), `Unexpected symlink: ${entry.name}`);
    const child = `${path}/${entry.name}`;
    return entry.isDirectory() ? walk(child) : [child];
  });
}

export function inventory(base, app, css, icons) {
  const matches = regex => [...base.matchAll(regex)].map(match => ({ value: match[1], line: lineAt(base, match.index) }));
  return {
    pages: matches(/id="(view-[^"]+)"/g),
    overlays: matches(/class="overlay" id="([^"]+)"/g),
    mediaQueries: matches(/@media\s+([^{}]+)\{/g).map(item => ({ ...item, value: item.value.trim() })),
    storageKeys: unique([...base.matchAll(/['"`](yymusic-[\w-]+)['"`]/g)].map(match => match[1])).sort(),
    toggleIds: matches(/class="toggle(?: persist-toggle)?" id="([^"]+)"/g),
    events: unique([...base.matchAll(/addEventListener\(['"]([^'"]+)/g)].map(match => match[1])).sort(),
    functions: matches(/(?:const|let)\s+(\w+)\s*=\s*(?:async\s+)?(?:\([^;]*?\)|\w+)\s*=>/g),
    cssVariables: matches(/(--[a-z-]+)\s*:/g),
    iconIds: icons.map(icon => icon.id),
    polishRules: cssRules(css.value, css.valueLine),
    sourceLines: { app: lineCount(app), base: lineCount(base) },
  };
}

export function buildOutputs() {
  const fingerprints = verifyFingerprints();
  const app = read(appPath);
  const base = read(basePath);
  const sprite = literal(app, 'NEW_ICON_SPRITE');
  const css = literal(app, 'POLISH_CSS');
  const icons = symbols(sprite.value);
  const data = inventory(base, app, css, icons);
  const html = compose(base, sprite.value, css.value);
  const outputs = new Map();
  outputs.set('design_reference/generated/YYMusic_Figma_Composed_Reference.html', html);
  outputs.set('design_reference/generated/polish.css', css.value);
  outputs.set('design_reference/generated/new_icon_sprite.svg', sprite.value);
  outputs.set('docs/generated/design_inventory.json', json(data));
  const manifest = walk(sourceRoot).map(path => {
    const bytes = readFileSync(join(root, path));
    return { path, bytes: bytes.length, lines: lineCount(bytes.toString('utf8')), sha256: sha(bytes) };
  });
  outputs.set('docs/generated/source_fingerprints.json', json({ fingerprints, exportFiles: manifest, composedSha256: sha(html) }));
  for (const icon of icons) {
    outputs.set(icon.file, `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${icon.viewBox}" fill="none" stroke="currentColor" stroke-width="1.72" stroke-linecap="round" stroke-linejoin="round">${icon.body}</svg>\n`);
  }
  outputs.set('docs/icon_manifest.md', `# 最终图标清单\n\n生成来源：App.tsx NEW_ICON_SPRITE；44 个唯一 ID，未手绘、未引入 Material Icons、无 Download 图标。\n\n所有 SVG 保留 viewBox 0 0 24 24 与原始路径；根元素补入原 .icon 的 fill/stroke/round 继承值，子元素的 filled 属性不变。Flutter 接入属于 Phase 2，本阶段不修改 pubspec。ID 语义为用途；消费行号见参考源。\n\n${table(['HTML ID / 用途', '资产', 'App.tsx 行', '包含 Filled 元素'], icons.map(icon => [icon.id, icon.file, lineAt(app, app.indexOf(`<symbol id="${icon.id}"`)), icon.body.includes('fill="currentColor"') ? '是（保留局部 stroke="none"）' : '否']))}\n\n按钮必须在 Flutter 提供本地化 Semantics Label；桌面提供 Tooltip；视觉 16/20/24 不限制 44×44 命中区。\n`);
  outputs.set('docs/generated/polish_rule_mapping.md', `# POLISH_CSS 全量规则到 Flutter 计划\n\n逐条从源文件提取，不是人工摘录。共 ${data.polishRules.length} 个规则块、${data.polishRules.reduce((sum, rule) => sum + rule.declarations.length, 0)} 个声明；逗号多选择器仍属一个规则块。所有条目仅是 Phase 2 计划。\n\n${table(['# / App.tsx 行', '选择器', '全部声明', 'Token / 组件计划'], data.polishRules.map(rule => [`${rule.index} / ${rule.line}`, `\`${rule.selector}\``, rule.declarations.map(item => `\`${item.property}: ${item.value}\``).join('<br>'), rule.target]))}\n\n注意：最后注入不等于无条件胜出。ID 选择器、组合类选择器、!important、伪元素与媒体查询均参与层叠。详见 design_source_composition.md 和 responsive_layout_map.md。\n`);
  outputs.set('docs/figma_export_manifest.md', `# Figma 导出审计清单\n\n日期：2026-08-31。输入来自用户指定的下载文件；先对下载 ZIP 求 SHA-256，再复制到 design_reference，校验路径无穿越后解压。ZIP 包内共 ${manifest.length} 个文件。没有运行其安装、部署脚本。\n\n## 指纹核验\n\n${table(['文件', '字节数', '行数', 'SHA-256', '结论'], fingerprints.map(item => [item.path, item.bytes, item.lines ?? '—', item.sha256, item.path === masterPath ? '本次实测锁定（文档未自带哈希）' : '与主指令 §0.1 一致']))}\n\n行数按逻辑行计算：末尾换行不额外计一行；哈希按原始字节计算，不归一化换行。\n\n## 解压文件全表\n\n${table(['相对仓库路径', '字节', '行', 'SHA-256'], manifest.map(item => [item.path, item.bytes, item.lines, item.sha256]))}\n\n## 来源职责与阅读覆盖\n\n- App.tsx：完整 1–506 行；Sprite、账户替换、全部 POLISH_CSS、Blob/iframe 生命周期。\n- 基础 HTML：完整 1–3710 行；CSS（包括 v2/v4 追加规则）、静态结构、完整内联 JavaScript。\n- 主文档：完整读取到 §44；仅把本轮用户指定的 Phase 0 作为执行范围，不因文档描述 Phase 1–11 就自动扩展任务。\n- package.json / index.html / src/main.tsx / src/index.css：仅证明导出为 React/Vite/Tailwind 预览。\n- 导出内 AGENTS.md / CLAUDE.md：作为 Figma Make 源数据读取，不赋予它们对正式 Flutter 仓库的指令权，也未据其启动服务器。\n- 现有 Flutter：检查入口、状态、布局、图标、主题、页面关键路径及测试；发现的旧原型问题记录在 existing_flutter_audit.md，不声称完成其全量代码审查。\n\n合成参考 SHA-256：\`${sha(html)}\`。可复核 JSON 见 generated/source_fingerprints.json。\n`);
  return outputs;
}

export function checkOutputs(outputs) {
  for (const [path, content] of outputs) {
    assert(existsSync(join(root, path)), `Missing generated artifact: ${path}`);
    assert.deepEqual(readFileSync(join(root, path)), Buffer.from(content), `Stale generated artifact: ${path}`);
  }
  assert.deepEqual(walk('assets/icons/yymusic').sort(), [...outputs.keys()].filter(path => path.startsWith('assets/icons/yymusic/')).sort());
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const mode = process.argv[2] ?? '--check';
  assert(['--check', '--write'].includes(mode), 'Usage: node tools/design_audit.mjs [--write|--check]');
  const outputs = buildOutputs();
  if (mode === '--write') {
    for (const [path, content] of outputs) {
      const target = join(root, path);
      mkdirSync(dirname(target), { recursive: true });
      writeFileSync(target, content, 'utf8');
    }
  }
  checkOutputs(outputs);
  console.log(`${mode}: verified 5 fingerprints, 44 icons and ${outputs.size} deterministic artifacts; Flutter not executed.`);
}
