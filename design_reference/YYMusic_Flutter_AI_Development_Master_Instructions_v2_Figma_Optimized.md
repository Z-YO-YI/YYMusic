# YYMusic Flutter 跨平台开发总指令（Figma 优化版）

> 文档版本：2.0  
> 设计源版本：Figma Make 优化导出包 + YYMusic v4 功能原型  
> 目标：依据最新 Figma 优化视觉和现有 HTML 交互原型，开发正式 Flutter 跨平台应用  
> 目标平台：Windows 10/11、Android 手机、Android 平板  
> UI 版本：Windows UI、Android Phone UI、Android Tablet UI  
> 发布产物：Windows 安装包 + 一个同时适配手机和平板的 Android APK/AAB  
> 开发方式：一个 Flutter 仓库、一套共用业务核心、三套独立 UI Shell、两套平台能力实现  
> 产品名称：始终为 **YYMusic**；“YY Listener / 本地账户”仅为账户展示文案

---

## 0. 使用方式与设计源身份

把以下内容同时提供给编码 AI：

1. `YYMusic_HTML.zip`：最新 Figma Make 优化导出包。
2. 解压后的设计源目录，尤其是：
   - `src/App.tsx`
   - `src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html`
3. `YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md`：本开发总指令。

推荐目录：

```text
design_reference/
├── YYMusic_HTML.zip
├── figma_export/
│   ├── src/
│   │   ├── App.tsx
│   │   ├── index.css
│   │   └── imports/
│   │       └── YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html
│   ├── package.json
│   ├── AGENTS.md
│   └── CLAUDE.md
└── YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md
```

### 0.1 设计源指纹

编码 AI 开始前必须校验：

```text
YYMusic_HTML.zip
size: 74024 bytes
SHA-256: d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee

src/App.tsx
size: 17621 bytes
lines: 506
SHA-256: 20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39

src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html
size: 218239 bytes
lines: 3710
SHA-256: 81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229

package.json
size: 600 bytes
lines: 27
SHA-256: c2d99ed2073126d401a3a9b1a2b1691e998058e9fe14da7105857f8a853e38d5
```

若任一指纹不同：

1. 不得假装使用了本版本。
2. 重新审计实际导出包。
3. 生成 `docs/design_source_diff.md`。
4. 记录新增、删除和变更的页面、组件、图标、Token、交互和响应式规则。
5. 产品与架构硬约束仍以本指令为准；视觉细节以实际新导出包为准。

### 0.2 最新视觉的合成方式

`src/App.tsx` 并不是一套新的业务应用。它以基础 HTML 为底，按以下顺序生成 Figma 优化后的最终网页参考：

```text
基础 HTML
→ 用 App.tsx 的 NEW_ICON_SPRITE 替换原隐藏 SVG Sprite
→ 将 Sidebar 顶部 “YYMusic / YOUR MUSIC, YOUR WAY”
  替换为 “YY Listener / 本地账户”
→ 将 App.tsx 的 POLISH_CSS 注入 </head> 前
→ 通过 Blob URL 和 iframe 显示最终网页
```

Flutter 开发必须理解这个合成结果，但不得复制其运行方式。

禁止：

- 把 React 项目当作正式 App 架构。
- 使用 WebView 或 iframe 承载 YYMusic 主界面。
- 在 Flutter 中运行该 HTML 的 JavaScript。
- 在 Flutter 启动时动态解析 `App.tsx` 或 HTML 生成 UI。
- 因为 Figma 导出使用 React/Vite/Tailwind，就给 Flutter 引入等价 Web 层。

正确做法：

```text
最终合成网页视觉
→ 设计 Token
→ SVG 图标资产
→ YYMusic Flutter 自定义组件
→ Windows / Phone / Tablet 三套 Shell
→ 共用业务、数据和播放核心
```

### 0.3 各源文件的职责

| 源文件 | 作为依据的内容 | 不作为依据的内容 |
|---|---|---|
| `src/App.tsx` | 最新图标、视觉覆盖、阴影、圆角、字重、账户区文案、示例封面配色 | React 组件结构、Blob、iframe、Web 运行架构 |
| 基础 HTML | 页面结构、交互流程、响应式断点、状态、功能演示、Overlay、键盘操作 | 浏览器存储、浏览器音频、模拟 API、DOM 全局状态 |
| `package.json` | 证明这是 Figma Make Web 预览工程 | Flutter 依赖选择和 Flutter 架构 |
| `AGENTS.md` / `CLAUDE.md` | Figma Make Web 项目说明 | 正式 Flutter 项目规范 |
| 本指令 | 产品、平台、架构、安全、测试、禁止项和验收 | 不覆盖最新导出包中明确的视觉优化 |

### 0.4 Phase 0 必须生成的设计审计文档

```text
docs/
├── figma_export_manifest.md
├── design_source_composition.md
├── design_source_diff.md
├── html_to_flutter_mapping.md
├── icon_manifest.md
├── design_tokens.md
├── responsive_layout_map.md
└── visual_parity_plan.md
```

其中 `design_source_composition.md` 必须写明：

- 基础 HTML 指纹。
- `App.tsx` 指纹。
- 44 个最终图标 ID。
- 两项品牌文字替换。
- `POLISH_CSS` 中的全部覆盖规则。
- 最终视觉是如何合成的。
- 哪些内容属于 Fixture，不能作为生产数据。

### 0.5 启动指令

```text
请解压并读取 design_reference/YYMusic_HTML.zip，完整审计 src/App.tsx 与基础 HTML，
再读取 YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md。
先校验文件指纹，然后严格从 Phase 0 开始。
不得一次性生成整个项目，不得使用 WebView，不得只读取旧 HTML 而忽略 App.tsx。
```

---

# 1. AI 角色与最终任务

你是 YYMusic 项目的 Flutter 首席架构师、Windows 桌面端工程师、Android 手机端工程师、Android 平板端工程师、音频播放系统工程师、本地音乐库工程师、第三方音乐源适配器工程师、设计系统实现工程师、测试与发布工程师。

你的任务不是把 HTML 放进 WebView，也不是逐行机械翻译 CSS、React 和 JavaScript。你的任务是：

1. 完整读取 `src/App.tsx`，提取 `NEW_ICON_SPRITE`、品牌文字替换和 `POLISH_CSS`。
2. 完整读取基础 HTML，理解页面、Overlay、功能、状态、响应式和键盘/触控交互。
3. 构造并记录最终视觉参考的合成规则。
4. 用原生 Flutter Widget 重建最终合成视觉，而不是只重建旧 HTML。
5. 建立可维护、可测试、可扩展的正式应用架构。
6. 共用音乐库、播放、搜索、收藏、歌单、队列、主题和音乐源逻辑。
7. 为 Windows、Android 手机、Android 平板分别提供独立 UI Shell。
8. 实现真实本地音乐读取、真实音频播放、真实持久化和可扩展第三方 API 接入。
9. 实现播放页与歌词页完全分离的独立全屏体验。
10. 不提供音乐下载、离线保存或批量抓取功能。
11. 为每个阶段提供真实分析、测试和构建证据。

---

# 2. 信息来源优先级与冲突处理

发生冲突时按以下顺序处理：

1. **本指令中的产品、安全、架构、平台和禁止项硬约束。**
2. **`src/App.tsx` 中的最新视觉覆盖：** `NEW_ICON_SPRITE`、品牌文字替换、`POLISH_CSS`。
3. **基础 HTML 中的页面结构、交互、响应式、状态和功能演示。**
4. 项目内已确认的 Architecture Decision Records。
5. Flutter、Windows、Android 当前官方平台要求。
6. 所选依赖的当前官方文档。
7. AI 的通用经验。

具体冲突规则：

- 产品名称、是否下载、平台范围、安全、架构：本指令优先。
- 图标形状、圆角、阴影、字重、字距和精修视觉：`App.tsx` 优先。
- 页面内容、Overlay、交互流程、响应式行为、存储状态：基础 HTML 优先。
- React/Vite/Tailwind/iframe 的实现方式：不适用于 Flutter，必须舍弃。
- Flutter 与 CSS 的渲染差异：以目标尺寸 Golden 对比达到视觉等价，不要求数值机械一一对应。
- 平台官方要求与网页模拟冲突：官方平台行为优先，但必须保留同等产品意图。

不得用通用 Material 设计覆盖最新合成参考中的 YYMusic 风格。

### 2.1 浏览器模拟到正式平台能力的替换

- `localStorage` → 数据库、普通设置存储和安全存储。
- 浏览器 Fullscreen API → Windows/Android `FullscreenGateway`。
- `URL.createObjectURL` → 平台媒体引用。
- `navigator.onLine` → `ConnectivityController`。
- HTML `<audio>` → `AudioEngine`。
- 模拟 API 延迟 → 真实连接测试。
- 写死歌词和曲目 → Dev Fixture 或真实数据。
- DOM `active` class → Typed Controller State。
- iframe → 原生 Flutter Route/Shell。
- CSS Hover → `MouseRegion`、`FocusableActionDetector` 和状态组件。
- HTML File Input → Windows 文件/文件夹选择器、Android MediaStore/系统授权。

### 2.2 产品名称澄清

`App.tsx` 将 Sidebar 顶部显示修改为：

```text
YY Listener
本地账户
```

这代表当前账户，不代表产品改名。

必须保持：

```text
产品名称：YYMusic
应用窗口标题：YYMusic
安装包显示名：YYMusic
设置关于页：YYMusic
账户显示名：YY Listener（Fixture，可被真实用户资料替换）
账户类型：本地账户
```

---

# 3. 不可违反的硬性约束

## 3.1 工程

- 只创建一个 Flutter 仓库。
- Figma Make 的 React/Vite/Tailwind 工程仅为设计参考，不是正式客户端工程。
- 不得把 `src/App.tsx` 的 iframe/Blob 结构迁入 Flutter。
- 不创建三个相互独立的 Flutter 项目。
- 不复制三份播放控制器、数据库、音乐源逻辑或数据模型。
- Windows、Android 手机、Android 平板只在 UI Shell、输入交互和平台能力层分开。
- Android 手机和平板使用同一个 APK/AAB。
- Android 根据当前窗口逻辑宽度切换，不根据设备型号判断。
- Windows 先根据平台判断，再依据当前窗口宽度切换桌面布局密度。
- 三套 UI 共用用户音乐库、收藏、历史、歌单、队列、主题和音乐源配置。

## 3.2 视觉

- 2026 高级、克制、苹果式内容优先风格。
- 不得像素级复制 Apple Music。
- 不得使用任何渐变：`LinearGradient`、`RadialGradient`、`SweepGradient` 全部禁止。
- 不得使用 AI 紫、紫色主题预设、紫色辉光。
- 不得使用 Material 3 原生视觉。
- 可以使用 `MaterialApp.router` 作为基础设施。
- 不直接采用默认外观的 `NavigationBar`、`NavigationRail`、`FilledButton`、`Card`、`SearchBar`、Dialog、BottomSheet、Slider。
- 创建 YYMusic 自有设计系统组件。
- 最新视觉必须是“基础 HTML + App.tsx 覆盖”的合成结果，不能只照旧 HTML 开发。
- 产品名称始终为 YYMusic；`YY Listener` 只属于账户展示。
- Liquid Glass 仅用于导航、Mini Player、桌面播放器、弹出菜单、临时工具条、播放和歌词 Dock。
- 普通内容卡片使用纯色表面，不得大面积玻璃化。
- 默认浅色，支持深色、跟随系统、自定义主题色。
- 自定义主题色必须自动计算可读 `onAccent`。
- 不提供紫色主题预设。

## 3.3 内容与版权

- YYMusic 不提供曲库。
- 在线内容由用户自行连接拥有合法访问权限的第三方 API。
- 不得实现歌曲下载、专辑下载、批量下载、离线保存、导出在线音频。
- UI 不得出现 Download 图标、下载按钮或“保存到本地”。
- `MusicSourceAdapter` 不得包含 `downloadTrack`、`saveOffline`、`batchDownload`、`downloadAlbum`。
- 技术性内存缓冲可存在，但不得向用户暴露、长期保留或用于离线播放。

## 3.4 安全

- API Key、Bearer Token、Basic 密码、OAuth Token 不得明文存入普通数据库或日志。
- 凭据放入平台安全存储，数据库只保存 `credentialRef`。
- 网络日志自动脱敏 Authorization、API Key、Cookie、敏感 Header 和 Query Token。
- 默认只允许 HTTPS。
- 不执行用户提供的 JavaScript、Dart 动态代码、Shell 命令。
- 第三方响应映射使用受限字段表达式。

---

# 4. 最新设计源功能与视觉清单

## 4.1 基础 HTML 的四个主页面

| HTML | Flutter |
|---|---|
| `view-home` | Home |
| `view-search` | Search |
| `view-library` | Library |
| `view-settings` | Settings |

## 4.2 七个独立交互层

| HTML Overlay | Flutter 目标 |
|---|---|
| `nowOverlay` | `FullscreenPlayerPage` |
| `lyricsOverlay` | `FullscreenLyricsPage` |
| `queueOverlay` | Queue 页面/弹层 |
| `sourceOverlay` | 添加/编辑音乐源 |
| `sourceManagerOverlay` | 音乐源管理中心 |
| `playlistOverlay` | 新建歌单/添加到歌单 |
| `optionsOverlay` | 设备、睡眠定时、播放选项 |

## 4.3 必须正式实现的功能

- 首页、全局搜索、音乐库、专辑、歌曲、艺人、歌单。
- 喜欢的音乐、最近播放、播放队列。
- 本地文件、文件夹、拖放导入和扫描进度。
- 去重、本地真实播放、播放暂停、上一首、下一首、Seek、音量。
- 随机、列表循环、单曲循环、自动下一首。
- 队列添加、下一首播放、上移、下移、移除、清空。
- 收藏、历史、右键/长按菜单。
- 音乐源新增、编辑、启停、测试、删除。
- REST、OAuth、API Key、Bearer、Basic、Custom Headers。
- 浅色、深色、系统、自定义主题色、降低玻璃、减少动态效果。
- 网络在线/离线、睡眠定时、输出设备状态。
- 独立全屏播放、独立 Apple 风格全屏歌词。
- 双语歌词、时间高亮、自动滚动、点击歌词 Seek。
- Windows 键盘快捷键。

## 4.4 需要映射到正式数据层的浏览器状态

```text
yymusic-theme
yymusic-accent
yymusic-device
yymusic-favorites
yymusic-playlists
yymusic-queue
yymusic-recent
yymusic-repeat
yymusic-searches
yymusic-shuffle
yymusic-sources
yymusic-volume
yymusic-toggle-*
```

## 4.5 App.tsx 最新视觉覆盖

### 账户与 Sidebar

- 顶部头像为 44×44 圆形 `YY` 头像。
- 头像使用双层细 Ring 和轻阴影。
- 顶部名称为 `YY Listener`。
- 副标题为 `本地账户`。
- Footer 中重复头像和账户文字被隐藏，只保留更多操作。
- 应用名称仍为 YYMusic。

### 导航

- 导航项圆角 14。
- Windows/Tablet Rail 的选中项具有：
  - Accent Soft 背景。
  - Accent 图标和文字。
  - 左侧 `3×18` Accent 指示条。
- Android Phone 底部导航不要机械使用左侧竖条；转换为底部适用的 Accent 胶囊/底色。

### 图标

- `App.tsx` 的 `NEW_ICON_SPRITE` 是最终图标源。
- 一共 44 个图标。
- 全局视觉 Stroke 为约 `1.72`。
- 播放、暂停、上一首、下一首和更多点使用清晰的 Filled 形状。
- 不使用 Material Icons 替代。

### 字体和标题

- OpenType 视觉目标：`cv01`、`cv02`、`ss01`、`calt`。
- Page Title：约 800 weight，letter spacing `-0.82`。
- Section Title：letter spacing `-0.45`。
- Hero Title：letter spacing `-2.1`。
- Hero Kicker：约 10.5、760、0.55、uppercase。
- Album Title：约 12.5、700、`-0.15`。
- Lyrics Primary：约 780，letter spacing 更紧。

### 形状

```text
Hero                    28
Floating Note           20
Floating Note Artwork   12
Album Artwork           20
Track Artwork            10
Queue Artwork            10
Now Playing Artwork     26
Sidebar                 24
Now Panel               24
Source Icon             13
Source Status           20
Dialog                  30
Now Dialog              30
Context Menu            20
Settings Nav Item       11
Playlist Card           20
Playlist Icon           14
Metric Card             18
Folder Row              16
Drop Zone               26
Lyrics Player Dock      26
```

### 阴影与控制

- Hero：两层轻阴影，而不是单层重阴影。
- Hero Disc：更深的 30/72 阴影。
- Primary Button：较轻 Accent 阴影，Hover 增强。
- Album Artwork：默认与 Hover 使用不同阴影。
- Now Artwork：Light/Dark 使用不同阴影强度。
- Slider Track：视觉高度约 3。
- Slider Thumb：视觉约 14，外圈与 Hover 放大。
- Primary Transport：具有独立悬浮阴影。
- Surface Card：两层极轻阴影。

### Liquid Glass

网页视觉覆盖为：

```css
backdrop-filter: blur(42px) saturate(1.3)
```

Flutter 不得机械把 CSS `42px` 当作绝对 Sigma。以 Golden/真机效果为准，建议视觉目标区间：

```text
Windows Expanded    sigma 38–42
Windows Standard    sigma 34–40
Android Tablet      sigma 32–38
Android Phone       sigma 26–32
```

若性能不合格：

1. 减少 Blur 面积。
2. 降低 Sigma。
3. 提高纯色 Fill 不透明度。
4. 保留 Stroke、高光和阴影。
5. 不使用渐变代替。

## 4.6 App.tsx 示例封面配色

这些仅作为无封面 Fixture/占位视觉，不是正式专辑封面：

```text
Orbit background  #0D0F12
Orbit red         #C42230
Orbit light       #ECE7DC

Tide background   #0468C4
Tide light        #EDF2F8
Tide amber        #FFA820

Noon background   #E9DDC8
Noon dark         #13171B
Noon red          #C83828

Mono background   #0C2030
Mono jade         #009970
Mono light        #E2E4D8

Signal background #F0A018
Signal dark       #14181C
Signal light      #FFF3DE

Quiet background  #F2EEE8
Quiet dark        #0F1113
Quiet red         #C82826

Local background  #1A1E24
Local line        #E4E7F0
Local bars        当前 Accent
```

规则：

- 用户曲目优先使用真实内嵌/在线 Artwork。
- 无封面时才使用 YYMusic 几何占位图。
- 占位图必须是平面几何纯色，不使用渐变。
- 示例曲目、艺人和封面只放入 Dev Fixture。

---

# 5. 最终产品形态

```text
YYMusic Flutter Repository
├── Common Domain
├── Common Data
├── Common Playback
├── Common Music Source Adapter
├── Common Design System
├── WindowsShell
├── AndroidPhoneShell
├── AndroidTabletShell
├── Windows Platform Gateways
└── Android Platform Gateways
```

发布产物：

```text
Windows: YYMusic.exe / 可选 MSIX
Android: YYMusic.apk（测试）/ YYMusic.aab（发布）
```

Android 同一安装包：

- 宽度 `< 600 logical px`：Phone UI。
- 宽度 `>= 600 logical px`：Tablet UI。
- 平板分屏宽度下降到 `< 600` 时自动切换 Phone UI。
- 不维护单独平板 APK。

---

# 6. 自适应布局分类

```dart
enum YYLayoutClass {
  androidPhone,
  androidTabletPortrait,
  androidTabletLandscape,
  windowsNarrow,
  windowsStandard,
  windowsExpanded,
}
```

```dart
YYLayoutClass resolveYYLayout({
  required TargetPlatform platform,
  required Size size,
}) {
  final width = size.width;
  final height = size.height;

  if (platform == TargetPlatform.windows) {
    if (width >= 1440) return YYLayoutClass.windowsExpanded;
    if (width >= 1024) return YYLayoutClass.windowsStandard;
    return YYLayoutClass.windowsNarrow;
  }

  if (width < 600) return YYLayoutClass.androidPhone;
  return width > height
      ? YYLayoutClass.androidTabletLandscape
      : YYLayoutClass.androidTabletPortrait;
}
```

必须使用 `LayoutBuilder` 的实时约束，不得只读取一次启动尺寸，不得检测设备名称。

---

# 7. 三套 UI Shell

## 7.1 WindowsShell

### Expanded：>= 1440

- 40–42 px 自定义标题栏。
- 240 px Liquid Glass Sidebar。
- 中间主内容区。
- 320 px Now Playing Inspector。
- 88 px 底部播放器。
- 外边距 16 px，面板间距约 14 px。
- 完整 Hover、Pressed、Focus、右键、滚轮、拖放。
- 标题栏按钮调用真实窗口能力。

### Standard：1024–1439

- 224–240 px Sidebar。
- 隐藏固定 Inspector。
- 队列和歌词使用独立页面或弹层。
- 保留 88 px 底部播放器。
- 主内容自动减少列数。
- 全屏播放保持横向双栏。

### Narrow：< 1024

- Sidebar 收为 72 px 图标导航轨。
- 隐藏低优先级品牌和来源详情。
- 隐藏固定 Inspector。
- 播放器可收为 76 px。
- 840×640 作为最低可用开发检查尺寸。
- 极窄窗口显示非阻塞提示，关键控件不得溢出。

快捷键：

| 快捷键 | 功能 |
|---|---|
| Space | 播放/暂停 |
| Ctrl+K | 搜索 |
| Ctrl+L | 音乐库 |
| Ctrl+, | 设置 |
| Ctrl+O | 导入本地音乐 |
| Alt+Left | 返回 |
| F | 切换全屏播放/歌词全屏 |
| L | 打开独立全屏歌词 |
| Esc | 按层级退出全屏、菜单或弹层 |

输入框聚焦时，Space、F、L 不触发全局操作。

## 7.2 AndroidPhoneShell

适用宽度 `< 600`：

- 主内容全屏，顶部紧凑标题栏。
- 底部 Liquid Glass 胶囊导航，左右 12–16，高 64，圆角 32。
- Mini Player 位于导航上方约 8 px。
- 正确处理 SafeArea 和主内容底部 Padding。
- 首页、搜索、音乐库、设置单列。
- 专辑 2 列。
- 歌曲列表隐藏低优先级时长，但保留更多操作。
- 右键转换成长按或更多菜单。
- Dialog 转为全屏页面或 Bottom Sheet。
- 播放页和歌词页是两个独立路由。
- Android 返回手势遵循路由栈。
- 触控目标至少 44×44。
- 横屏切换紧凑双栏，不能只旋转竖屏布局。

## 7.3 AndroidTabletShell

适用 Android 宽度 `>= 600`：

- 72 px 左侧 Liquid Glass Navigation Rail。
- 72–76 px 底部播放器。
- 竖屏：Rail + 主内容，专辑 3–4 列。
- 横屏：主从分栏，列表和详情同时展示。
- 宽屏可显示右侧播放/队列 Inspector。
- 播放页采用封面和控制双栏。
- 平板不是放大的手机版。
- 分屏小于 600 时切换 Phone Shell，并保留路由、播放、队列、滚动和选中状态。

---

# 8. 推荐工程结构

```text
lib/
├── main.dart
├── app/
│   ├── yy_music_app.dart
│   ├── app_bootstrap.dart
│   ├── adaptive_root.dart
│   ├── layout_class.dart
│   ├── app_router.dart
│   ├── app_routes.dart
│   └── dependency_graph.dart
├── design_system/
│   ├── foundations/
│   ├── theme/
│   ├── icons/
│   └── components/
├── domain/
│   ├── models/
│   ├── repositories/
│   └── use_cases/
├── data/
│   ├── database/
│   ├── repositories/
│   ├── secure_storage/
│   ├── preferences/
│   ├── search/
│   └── sources/
├── playback/
│   ├── audio_engine.dart
│   ├── playback_controller.dart
│   ├── playback_state.dart
│   ├── queue_controller.dart
│   ├── lyrics_controller.dart
│   ├── sleep_timer_controller.dart
│   ├── media_session_coordinator.dart
│   └── playback_error_mapper.dart
├── features/
│   ├── home/{common,phone,tablet,windows}/
│   ├── search/{common,phone,tablet,windows}/
│   ├── library/{common,phone,tablet,windows}/
│   ├── playlists/
│   ├── player/{common,phone,tablet,windows,fullscreen_player,fullscreen_lyrics,queue}/
│   ├── music_sources/
│   └── settings/
├── shells/
│   ├── windows_shell.dart
│   ├── android_phone_shell.dart
│   └── android_tablet_shell.dart
├── platform/
│   ├── contracts/
│   ├── windows/
│   └── android/
└── shared/
    ├── errors/
    ├── logging/
    ├── result/
    ├── utils/
    └── testing/
```

```text
test/
├── unit/
├── widget/
├── golden/
└── fixtures/

integration_test/
├── windows/
├── android_phone/
└── android_tablet/

docs/
├── architecture.md
├── architecture_decisions.md
├── dependency_decisions.md
├── html_to_flutter_mapping.md
├── music_source_adapter.md
├── security.md
├── accessibility.md
├── test_matrix.md
└── implementation_status.md
```

---

# 9. 依赖选择规则

Phase 0 必须建立 `docs/dependency_decisions.md`，记录候选库、Windows 支持、Android 支持、维护状态、License、原生配置、测试能力、选择理由和回退方案。

类别：状态管理、路由、数据库、HTTP、安全存储、音频、后台播放、文件选择、拖放、窗口、Metadata、图片缓存。

规则：

- 不固定版本号，使用当前兼容的稳定版本。
- 音频方案先做 Windows + Android 双平台 POC。
- 若只在 Android 工作，不得进入正式架构。
- 所有第三方库包裹在项目自有接口后面。
- UI 不直接依赖插件类型。

---

# 10. 核心数据模型

## Track

```dart
class Track {
  final String id;
  final String sourceId;
  final MusicSourceType sourceType;
  final String title;
  final List<String> artists;
  final String? albumId;
  final String? albumTitle;
  final Duration duration;
  final Uri? artworkUri;
  final String? localPath;
  final Uri? contentUri;
  final String? fileFingerprint;
  final TrackAvailability availability;
  final Map<String, Object?> metadata;
}
```

要求：ID 稳定；在线流 URL 可能过期，不作为永久 ID；本地歌曲保存指纹、修改时间和大小；不保存明文凭据。

## Album、Artist、Playlist、Lyrics、MusicSourceConfig、PlaybackState

至少包含：

- Album：id、sourceId、title、artists、year、artwork、trackCount。
- Artist：id、sourceId、name、artwork、albumCount、trackCount。
- Playlist：id、name、description、createdAt、updatedAt、isSystem、systemType。
- LyricsDocument：trackId、kind、lines、language、translationLanguage、offset。
- LyricsLine：start、end、text、translation。
- MusicSourceConfig：id、name、type、baseUrl、authType、credentialRef、publicHeaders、endpoints、responseMapping、enabled、status、lastLatency、lastTestedAt、lastErrorCode。
- PlaybackState：phase、currentTrack、position、buffered、duration、volume、shuffleEnabled、repeatMode、queue、outputDevice、failure。

播放阶段：`idle`、`loading`、`buffering`、`ready`、`playing`、`paused`、`completed`、`error`。

---

# 11. 核心接口

```dart
abstract interface class AudioEngine {
  Stream<AudioEngineState> get stateStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<Duration?> get durationStream;

  Future<void> load(PlayableSource source);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
  Future<void> setPlaybackRate(double value);
  Future<void> dispose();
}
```

```dart
abstract interface class MusicSourceAdapter {
  String get sourceId;
  Future<SourceHealthResult> testConnection();
  Future<SearchPage<Track>> searchTracks({
    required String query,
    required PageRequest page,
    CancellationToken? cancellationToken,
  });
  Future<Track> getTrack(String remoteTrackId);
  Future<PlayableSource> resolvePlayableSource(String remoteTrackId);
  Future<LyricsDocument?> getLyrics(String remoteTrackId);
  Future<SearchPage<Album>> getAlbums(PageRequest page);
  Future<SearchPage<Artist>> getArtists(PageRequest page);
}
```

```dart
abstract interface class LocalMusicGateway {
  Future<List<LocalPickerResult>> pickFiles();
  Future<LocalFolderGrant?> pickFolder();
  Stream<LocalScanProgress> scan(LocalScanRequest request);
  Future<bool> canRead(LocalMediaReference media);
  Future<void> releaseGrant(String grantId);
}
```

```dart
abstract interface class MediaSessionGateway {
  Future<void> initialize(MediaSessionCallbacks callbacks);
  Future<void> updateMetadata(Track track);
  Future<void> updatePlaybackState(PlaybackState state);
  Future<void> clear();
}
```

```dart
abstract interface class SecureCredentialGateway {
  Future<String> saveCredential(SensitiveCredential credential);
  Future<SensitiveCredential?> readCredential(String reference);
  Future<void> deleteCredential(String reference);
}
```

UI 不得直接调用音频插件、HTTP、数据库、文件系统或安全存储。

---

# 12. 状态管理边界

创建共用 Controller/Notifier：

- ThemeController
- LibraryController
- SearchController
- PlaybackController
- QueueController
- LyricsController
- PlaylistController
- FavoriteController
- HistoryController
- LocalScanController
- MusicSourceController
- SleepTimerController
- ConnectivityController
- AppSettingsController

规则：

- Shell 只决定布局，不持有业务真相。
- 当前曲目只有一个状态来源。
- 队列只有一份。
- 所有异步状态显式表示 idle/loading/data/empty/error。
- UI 离开页面后播放不停止。
- Shell 切换不重建播放器。
- Android 手机和平板切换不丢滚动、选中、队列和播放进度。

---

# 13. 路由

```text
/home
/search
/library/albums
/library/tracks
/library/artists
/library/playlists
/library/local
/album/:id
/artist/:id
/playlist/:id
/settings/appearance
/settings/sources
/settings/local
/settings/playback
/settings/about
/player
/lyrics
/queue
/sources
/sources/:id/edit
```

要求：

- `/player` 与 `/lyrics` 是独立路由。
- 不把完整歌词做成播放页内部 Tab。
- 从播放页打开歌词，关闭歌词返回播放页。
- 从 Mini Player 直接打开歌词，关闭后返回原页面。
- Android 返回和 Windows Esc 使用同一导航栈语义。
- 路由层不复制播放状态。

---

# 14. 设计 Token（以最终 Figma 合成视觉为准）

## 14.1 Light

```text
bg/base              #F5F5F2
bg/elevated          #FFFFFF
bg/subtle            #ECEDEA
bg/pressed           #E4E5E1
text/primary         #111214
text/secondary       #62666C
text/tertiary        #93989F
text/onAccent        动态计算
border/default       #D9DBD7
border/strong        #BEC1BC
icon/primary         #202226
icon/secondary       #777C83
glass/fill           rgba(255,255,255,0.68)
glass/stroke         rgba(255,255,255,0.66)
glass/highlight      rgba(255,255,255,0.82)
scrim                rgba(12,14,16,0.38)
```

## 14.2 Dark

```text
bg/base              #0B0C0E
bg/elevated          #16181B
bg/subtle            #202328
bg/pressed           #2A2E34
text/primary         #F5F6F7
text/secondary       #A7ACB3
text/tertiary        #737982
border/default       #2B2F35
border/strong        #3C424A
icon/primary         #F1F3F4
icon/secondary       #A7ACB3
glass/fill           rgba(24,26,30,0.70)
glass/stroke         rgba(255,255,255,0.12)
glass/highlight      rgba(255,255,255,0.16)
scrim                rgba(0,0,0,0.58)
```

## 14.3 Accent

```text
Coral      #FF3B5C  pressed #D92847
Cobalt     #0A84FF  pressed #0067CC
Jade       #00A67E  pressed #007F61
Amber      #F59E0B  pressed #C67A00
Graphite   #56606B  pressed #3F4852
```

默认 Coral，禁止紫色。

自定义主题色必须：

- 保存用户原始 Hex。
- 生成 Pressed 色。
- 生成约 12% 透明 Soft 色。
- 根据相对亮度生成黑/白 `onAccent`。
- 对比不足时生成可读 UI 色阶，但保留原始值供编辑。
- Amber 等浅色 Accent 默认使用深色 `onAccent`。

## 14.4 功能色

```text
success #20A464
warning #E89200
error   #E5484D
```

## 14.5 间距

建立语义 Token：

```text
space/0   0
space/1   4
space/2   8
space/3   12
space/4   16
space/5   20
space/6   24
space/8   32
space/10  40
space/12  48
space/16  64
space/20  80
```

不要求每个 HTML 像素都成为 Token；重复出现并有布局语义的值必须 Token 化。

## 14.6 圆角

基础 Token：

```text
radius/8       8
radius/10     10
radius/11     11
radius/12     12
radius/13     13
radius/14     14
radius/16     16
radius/18     18
radius/20     20
radius/24     24
radius/26     26
radius/28     28
radius/30     30
radius/32     32
radius/full  999
```

语义绑定以第 4.5 节最终组件形状表为准。

## 14.7 阴影 Token

至少建立：

```text
shadow/surface
shadow/card
shadow/hero
shadow/album
shadow/album-hover
shadow/floating
shadow/player-artwork-light
shadow/player-artwork-dark
shadow/primary-button
shadow/primary-control
shadow/focus
```

Figma 优化参考：

```text
Hero:
0 4 20 rgba(15,18,20,0.06)
0 1 3 rgba(15,18,20,0.05)

Surface:
0 1 4 rgba(15,18,20,0.04)
0 4 18 rgba(15,18,20,0.04)

Album:
0 10 26 rgba(15,18,20,0.13)

Album Hover:
0 16 34 rgba(15,18,20,0.19)

Now Artwork Light:
0 22 50 rgba(15,18,20,0.20)

Now Artwork Dark:
0 24 58 rgba(0,0,0,0.46)
```

Flutter 的 `BoxShadow` 可按渲染差异微调，但必须集中在 Token，不得页面硬编码。

## 14.8 Liquid Glass Token

建立：

```text
glass/fill/light
glass/fill/dark
glass/stroke/light
glass/stroke/dark
glass/highlight/light
glass/highlight/dark
glass/blur/phone
glass/blur/tablet
glass/blur/windows-standard
glass/blur/windows-expanded
glass/saturation
glass/shadow
```

视觉目标：

```text
CSS reference blur 42
CSS reference saturation 1.3
Phone Flutter sigma 26–32
Tablet Flutter sigma 32–38
Windows Flutter sigma 34–42
```

规则：

- `BackdropFilter` 只覆盖必要区域。
- 不做全屏持续 Blur。
- 滚动列表下方玻璃需要性能 Profile。
- “降低玻璃效果”关闭 Blur、提高 Fill、保留 Stroke/Shadow。
- 不用渐变模拟玻璃。

## 14.9 Slider Token

```text
trackHeight     3
thumbSize      14
thumbHoverScale 1.24（桌面）
focusRing       3
```

触控命中区域仍至少 44×44，不等于视觉 Thumb 大小。

## 14.10 动效

```text
standard          cubic-bezier(0.2,0.8,0.2,1)
emphasized enter  cubic-bezier(0.16,1,0.3,1)
press              100–130 ms
hover              130–160 ms
selected           180–220 ms
page transition    260–280 ms
overlay             220–320 ms
player expand       320–360 ms
```

Reduce Motion 开启时：

- 禁止大范围位移。
- 禁止封面播放/暂停缩放。
- 歌词自动滚动使用即时或极弱动画。
- 保留必要的状态反馈。

---

# 15. 字体、账户区与图标资产

## 15.1 字体

字体顺序：

```text
Inter
Noto Sans SC
Segoe UI Variable
Segoe UI
system sans-serif
```

要求：

- Windows 保证中文与 Segoe UI/中文字体组合稳定。
- Android 正确打包或加载中文字体，避免设备差异。
- 尝试启用支持的 OpenType Feature：`cv01`、`cv02`、`ss01`、`calt`。
- 若所选字体不支持这些 Feature，不得为了 Feature 换成明显不同的字体。
- Page Title、Hero、Album、Lyrics 的字重与字距按第 4.5 节实现。
- 时间使用等宽数字。
- 歌曲名、艺人名、来源正确截断。
- 用户字体缩放 130% 时关键按钮仍可操作。

## 15.2 账户区

Windows Sidebar 顶部实现 `YYProfileHeader`：

- 44×44 圆形头像。
- `YY` Fixture 字样。
- 双层 Ring。
- 名称 `YY Listener`。
- 类型 `本地账户`。
- 账户信息未来可替换为真实本地 Profile。
- 不把 `YY Listener` 当作 App 品牌名。

Android Phone/Tablet 可根据布局把 Profile 放入设置页或导航末端，不必机械复制 Windows 位置。

## 15.3 最终图标清单

必须从 `src/App.tsx` 的 `NEW_ICON_SPRITE` 拆出 44 个 SVG 资产：

```text
i-home
i-search
i-library
i-settings
i-moon
i-sun
i-play
i-pause
i-prev
i-next
i-shuffle
i-repeat
i-volume
i-queue
i-more
i-heart
i-folder
i-cloud
i-plus
i-chevron-right
i-chevron-down
i-x
i-minimize
i-maximize
i-music
i-palette
i-key
i-info
i-check
i-playlist
i-history
i-timer
i-device
i-trash
i-list-plus
i-up
i-down
i-refresh
i-speaker
i-drag
i-wave
i-fullscreen
i-fullscreen-exit
i-lyrics
```

资产建议：

```text
assets/icons/yymusic/
├── home.svg
├── search.svg
├── library.svg
├── settings.svg
├── play.svg
├── pause.svg
└── ...
```

规则：

- 保留 `viewBox="0 0 24 24"`。
- 默认 Stroke 视觉约 1.72。
- Filled 播放类图标保留 Filled 形状。
- 颜色使用 `currentColor` 语义或 Flutter 端统一着色。
- 不使用 Material Icons 替代。
- 不重新手绘近似图标。
- 不生成 Download 图标。
- 所有图标按钮具有 Semantics Label 和 Tooltip（桌面）。
- 建立 `docs/icon_manifest.md`，记录 HTML ID、Flutter 资产名和用途。

---

# 16. 通用组件

必须创建并测试：

- `YYButton`
- `YYIconButton`
- `YYGlassSurface`
- `YYProfileHeader`
- `YYArtworkPlaceholder`
- `YYNavigationItem`
- `YYMobileBottomNavigation`
- `YYTabletNavigationRail`
- `YYWindowsSidebar`
- `YYNavigationSelectionIndicator`
- `YYAlbumCard`
- `YYTrackTile`
- `YYMiniPlayer`
- `YYDesktopPlayerBar`
- `YYSearchField`
- `YYSegmentedControl`
- `YYSourceCard`
- `YYPlaylistCard`
- `YYThemeSwatch`
- `YYToggle`
- `YYSlider`
- `YYContextMenu`
- `YYDialog`
- `YYBottomSheet`
- `YYToast`
- `YYEmptyState`
- `YYErrorBanner`
- `YYSkeleton`
- `YYQueueTile`
- `YYLyricsLine`
- `YYLyricsPlayerDock`
- `YYWindowToolbar`

每个交互组件至少支持 Default、Hover、Pressed、Focus、Disabled、Selected、Loading（适用时）、Light、Dark、自定义 Accent。

不得在页面内复制大量 Container 代替组件。

---

# 16A. 视觉还原与 Golden 对照流程

开发 AI 必须建立确定性的视觉对照，而不是凭印象实现。

## 16A.1 生成最终网页参考

Phase 0 可创建一个仅用于开发对照的静态文件：

```text
design_reference/generated/YYMusic_Figma_Composed_Reference.html
```

生成方法必须与 `App.tsx` 一致：

1. 读取基础 HTML。
2. 替换隐藏 SVG Sprite。
3. 替换两项账户文案。
4. 注入 `POLISH_CSS`。
5. 写出静态 HTML。

这个文件：

- 只用于浏览器截图和视觉对照。
- 不进入 Flutter Release 运行路径。
- 不放入 WebView。
- 不作为产品业务逻辑来源。

## 16A.2 参考截图尺寸

```text
Windows       1440×900
Windows       1024×720
Android Phone 390×844
Android Phone 430×932
Tablet        1024×768
Tablet        1280×800
Tablet        800×1280
Player        上述关键尺寸
Lyrics        上述关键尺寸
```

## 16A.3 对照顺序

1. 结构：Shell、导航、播放器和 Overlay。
2. Token：颜色、圆角、间距、阴影。
3. 字体：字号、字重、字距、行高。
4. 图标：路径、尺寸、Stroke、Filled 状态。
5. 交互状态：Hover、Pressed、Focus、Selected、Disabled。
6. 响应式：断点、列数、隐藏/显示。
7. 动效：时长和运动方向。
8. Light/Dark/Accent。

## 16A.4 视觉差异报告

每个关键 Golden 失败时记录：

```text
Screen:
Reference size:
Flutter size:
Difference category:
Expected:
Actual:
Root cause:
Token/component fix:
Validation result:
```

优先修 Token 或组件，不允许在单个页面反复添加补丁值。

---

# 17. 页面要求

## 17.1 Home

保留 HTML 层级：

1. 问候或 YYMusic 标题。
2. 今日精选 Hero。
3. 继续聆听。
4. 最近添加。
5. 用户音乐源。
6. 最近播放。
7. Mini Player 或底部播放器。

要求：

- 数据来自 Repository。
- Loading 使用 Skeleton。
- 无数据使用 Empty State。
- 单个在线来源错误不阻塞本地内容。
- “今日精选”初期可基于最近播放、喜欢和本地数据生成。
- HTML 示例曲目只存在 Dev Fixture，不作为生产曲库。

## 17.2 Search

支持：歌曲、专辑、艺人、本地音乐、在线来源、来源名称、最近搜索、清除搜索、Enter 播放首条、输入防抖、请求取消、多来源并行、分页、去重、来源标签、独立 Loading/Error。

在线搜索失败不能隐藏本地结果。

## 17.3 Library

分类：专辑、歌曲、艺人、歌单、本地音乐。

支持排序、筛选、分页/虚拟列表、当前播放状态、右键/长按、多来源标签、不可用曲目标记、本地失效文件恢复。

## 17.4 Playlists

系统歌单：喜欢的音乐、最近播放、当前队列；不能删除。

自定义歌单：创建、重命名、删除、添加、移除、排序、播放全部、随机播放。

删除歌单不删除歌曲或来源内容。

## 17.5 Settings

分类：外观、音乐源、本地音乐、播放、关于。

手机端使用可横向滚动紧凑分类或独立二级页面。

---

# 18. 独立全屏播放页

路由：`/player`。播放页只负责播放，不内嵌完整歌词。

内容：

- 收起/返回、当前来源、更多。
- 专辑封面、歌曲名、艺人、收藏。
- 播放进度、当前时间、剩余/总时间。
- 随机、上一首、播放/暂停、下一首、循环。
- 全屏歌词、队列、播放设置。

Windows：

- 横向双栏，左封面、右信息和控制。
- 封面最大宽度受窗口高度和宽度共同限制。
- `F` 切换应用全屏。
- 全屏时隐藏普通 Shell。
- Esc 先退出全屏，再返回路由。

Android 手机：

- 竖屏单列。
- 封面宽度不超过可用宽度减 36–48。
- 底部操作避开手势区域。
- 可向下滑动收起，但必须与系统返回一致。
- 横屏切换紧凑双栏。

Android 平板：

- 横屏双栏。
- 竖屏单列或上封面下控制。
- 进入沉浸页面时隐藏 Rail。

动效：

- 播放时封面 scale 1.0，暂停 0.94。
- Reduce Motion 时不缩放。
- 切歌轻量淡入和小位移。
- 不使用模糊封面背景。
- 可提取单一低透明度纯色 Tint。
- 不使用渐变。

---

# 19. 独立全屏歌词页

路由：`/lyrics`，与播放页完全分离。

## 19.1 Apple 风格但形成 YYMusic 自有视觉

- 专辑主色生成单一纯色背景。
- 不使用渐变。
- 不使用模糊封面铺满。
- HTML 参考背景：

```text
Orbit  #3D4A52
Tide   #245064
Noon   #684A38
Mono   #282D33
Signal #315247
Quiet  #64584A
Local  #40515B
```

正式版本从封面提取代表色，再做明度限制、饱和度限制、白字对比检查和深色兜底。颜色提取只用于单一纯色。

## 19.2 歌词状态

- 当前行：纯白、高亮、轻微放大。
- 当前行左侧：小圆点。
- 已播放：约 50% 白色。
- 未播放：约 24% 白色。
- Hover：约 56% 白色。
- 翻译继承行颜色并降低透明度。
- 当前行自动滚动到视觉中心。
- 用户手动滚动时暂停自动跟随若干秒。
- 点击一行 Seek 到该时间并更新高亮。
- 支持时间偏移、无歌词、纯文本、LRC、双语。
- 可扩展逐字歌词，但 v1 不强制。

## 19.3 字号

```text
桌面/大平板：主歌词 34–68，翻译 14–20
手机：主歌词 29–43，翻译 12–16
```

## 19.4 顶部和底部 Dock

顶部：返回、小封面、歌曲名、艺人、全屏、更多。

底部 Dock：

- 小封面和信息。
- 上一首、播放/暂停、下一首。
- 进度和时间。
- 收藏、返回播放页。
- Liquid Glass。
- 手机自动重排为两层。
- 不遮挡当前歌词。

## 19.5 全屏

Windows：

- 使用窗口全屏能力。
- 保存进入前窗口状态。
- 退出后恢复边框、大小和位置。
- F 或顶部按钮切换。

Android：

- 使用平台沉浸式 System UI。
- 正确处理状态栏、导航栏和手势区。
- 离开歌词页恢复系统 UI。
- 生命周期中断不能永久卡在沉浸模式。

---

# 20. 播放队列

队列是共用状态，支持：

- 播放指定项。
- 下一首播放。
- 添加末尾。
- 上移、下移、拖拽排序。
- 移除、清空。
- 随机、列表循环、单曲循环、自动下一首。
- 空状态、当前项标记、跨启动恢复。
- 无法播放项跳过并记录错误。

桌面使用 Inspector/Dialog，支持鼠标拖拽和键盘排序；手机使用 Bottom Sheet/独立页；平板宽屏可固定右侧。

---

# 21. 本地音乐

## 21.1 Windows

- 选择多个音频文件。
- 选择文件夹。
- 拖放文件和文件夹。
- 保存文件夹记录。
- 增量扫描、手动重扫、可选文件变化监听。
- 后台 Isolate 或原生后台解析。
- 可取消，不阻塞 UI。
- 文件失效显示状态和重新定位入口。

## 21.2 Android

- 使用当前 target SDK 要求的媒体访问方式。
- 优先 MediaStore。
- 用户选择文件夹使用系统文档授权机制并保存可持久化授权。
- 处理授权撤销。
- 不扫描无权访问路径。
- AI 必须核对当前权限，不使用过时模板。

## 21.3 Metadata

至少读取：标题、艺人、专辑、专辑艺人、年份、轨道号、碟号、时长、流派、内嵌封面、格式、可用时的比特率、修改时间、大小。

优先级：Metadata → 文件名解析 → 未知艺人/未知专辑。

文件名解析支持：

```text
艺人 - 歌曲名.ext
轨道号 - 歌曲名.ext
```

## 21.4 去重和扫描报告

组合指纹：路径/Content URI、大小、修改时间、可选快速 Hash、Metadata 特征。

报告发现、新增、更新、忽略重复、失效、错误数量。

---

# 22. 搜索

建立统一搜索索引：

- 本地数据库搜索。
- 在线音乐源并行搜索。
- 结果合并和来源标记。
- 分页、请求取消、输入防抖。
- 最近搜索和清除历史。

过滤：

```text
all
tracks
albums
artists
local
online
```

在线结果不得直接写入正式本地音乐库，只保存收藏/歌单所需的轻量引用。

---

# 23. 喜欢、历史和歌单

## 喜欢

- 使用 Track 稳定引用。
- 在线来源失效时保留记录并标记不可用。
- 恢复来源后重新可用。
- UI 不仅依靠颜色表示收藏状态。

## 最近播放

- 默认保存最近 20 首。
- 同一歌曲重复播放时移动到顶部。
- 用户可清除。
- 未真正开始播放的失败曲目不记录。

## 歌单

- 支持本地和在线歌曲混合。
- 保存来源 ID 和远程 ID。
- 不复制在线音频文件。
- 来源被删除时保留灰色不可用引用，并提供清理选项。

---

# 24. 音乐源系统

## 24.1 类型

- Local
- REST API
- OAuth API
- API Key
- Bearer Token
- Basic Auth
- Custom Headers

## 24.2 配置字段

- Provider Name
- Base URL
- Auth Type
- Credential Reference
- Public Headers
- Search Endpoint
- Track Endpoint
- Stream Endpoint/Mapping
- Lyrics Endpoint/Mapping
- Artwork Mapping
- Album Mapping
- Artist Mapping
- Pagination Mapping
- Error Mapping
- Token Refresh
- Timeout
- Enabled

不得添加 Download Endpoint。

## 24.3 字段映射

允许：点路径、数组索引、简单 fallback、模板变量、字符串/数字/布尔转换。

禁止：`eval`、任意 JavaScript、动态 Dart、文件系统访问、Shell 命令、不受限代码执行。

## 24.4 测试连接

结果包含 DNS/连接、TLS、HTTP、认证、响应格式、映射验证、延迟、错误分类和时间。

Token 不得显示在 UI 或日志。

## 24.5 状态

```text
connected
testing
error
disabled
unauthorized
rateLimited
schemaMismatch
offline
```

## 24.6 删除来源

删除前显示对收藏、歌单、历史和队列引用的影响。默认保留引用并标记来源不可用，不自动删除用户整理的数据。

---

# 25. 播放功能

真实实现：

- 播放、暂停、停止、Seek。
- 上一首、下一首、音量。
- 队列、下一首播放、随机、列表循环、单曲循环。
- 自动继续、播放完成、缓冲、错误。
- 在线 URL 过期后重新解析。
- 本地文件失效。
- Sleep Timer。
- Media Session。
- 后台播放、音频焦点、外部打断恢复策略。

播放源解析：

```text
Track Reference
→ Source Repository
→ resolvePlayableSource()
→ 临时可播放 URI / 本地媒体引用
→ AudioEngine.load()
→ PlaybackController 更新状态
```

不得把 Stream URL 永久硬编码在 UI。

---

# 26. 睡眠定时和输出设备

Sleep Timer：关闭、15、30、60 分钟、本曲结束后；显示剩余时间；未过期定时可恢复，到期平滑暂停。

输出设备：

- HTML 中属于演示。
- 仅在平台和依赖真实支持时提供切换。
- 不支持时显示当前系统输出并提供系统设置入口。
- 不得伪造“切换成功”。

---

# 27. Windows 平台能力

实现：

- `WindowsWindowGateway`
- `WindowsLocalMusicGateway`
- `WindowsMediaSessionGateway`
- `WindowsSecureCredentialGateway`
- `WindowsFileDropGateway`
- `WindowsFullscreenGateway`

窗口要求：

- 自定义标题栏拖拽区。
- 交互控件不得被标记为拖拽区。
- 最小化、最大化、还原、关闭真实工作。
- 记忆窗口尺寸和位置。
- 多显示器恢复时保持可见。
- 播放/歌词无边框全屏。
- 退出恢复原窗口状态。

文件拖放：显示 Drop Zone，过滤格式，递归扫描可取消，大文件夹持续显示进度。

媒体会话：系统播放/暂停、上一首/下一首、Metadata、封面；退出时清理。

---

# 28. Android 平台能力

实现：

- `AndroidLocalMusicGateway`
- `AndroidMediaSessionGateway`
- `AndroidSecureCredentialGateway`
- `AndroidFullscreenGateway`
- `AndroidAudioFocusCoordinator`

要求：

- 后台播放服务。
- 通知栏播放器。
- 锁屏控制。
- MediaSession Metadata。
- 音频焦点。
- 耳机拔出策略。
- 蓝牙按钮。
- 系统返回、SafeArea、横竖屏、分屏、平板。
- 系统深浅色、Reduce Motion、字体缩放。

权限：根据当前 target SDK 配置；拒绝后解释；永久拒绝后提供系统设置入口；在线播放不申请不必要的文件权限。

---

# 29. 数据持久化

普通数据库建议表：

```text
tracks
albums
artists
track_artists
album_artists
playlists
playlist_entries
favorites
play_history
queue_entries
music_sources
local_folders
lyrics_cache
search_history
app_settings
schema_migrations
```

安全存储保存 API Key、Bearer、Basic 密码、OAuth Token 和敏感 Header；数据库只存引用。

设置保存：themeMode、accentPreset、customAccent、glassEnabled、reduceMotion、volume、shuffle、repeatMode、autoplay、gapless、normalization、outputPreference、lastRoute、windowBounds、windowMaximized。

迁移规则：

- 每次 Schema 修改提供 Migration 和测试。
- 不通过删除用户数据库解决升级。
- 旧明文敏感信息迁入安全存储后删除原值。

---

# 30. 错误分类

```text
PermissionDenied
PermissionPermanentlyDenied
LocalFileMissing
UnsupportedAudioFormat
MetadataReadFailed
PlaybackOpenFailed
PlaybackInterrupted
NetworkOffline
NetworkTimeout
TlsFailed
Unauthorized
Forbidden
NotFound
RateLimited
ServerError
SchemaMismatch
StreamUrlExpired
SourceDisabled
SourceRemoved
SecureStorageUnavailable
DatabaseCorrupted
Unknown
```

错误 UI：用户可理解、显示来源、可重试、可进设置、不显示敏感 Header、可复制脱敏诊断 ID。单个来源错误不得阻塞其他来源和本地音乐。

---

# 31. 无障碍

- 触控目标至少 44×44。
- 键盘 Focus 清晰。
- 不能只依靠颜色表达状态。
- 图标有语义标签。
- Slider 有当前值描述并支持键盘调整。
- 歌词当前行使用 Semantics 当前状态。
- 自动滚动不抢屏幕阅读器焦点。
- 文本缩放 130% 不截断核心操作。
- 支持 Reduce Motion。
- Toast 使用可访问公告。
- Dialog 正确管理焦点。
- Windows Tab 顺序符合视觉顺序。
- Android 返回不跳过未保存确认。

---

# 32. 性能

- 大音乐库使用 Builder、分页和虚拟列表。
- 扫描和 Metadata 解析不阻塞主 Isolate。
- 搜索防抖，请求可取消。
- 封面限制解码尺寸。
- 列表滚动期间不重复提取封面主色。
- 主题色和歌词背景色缓存。
- 全屏 Blur 范围受控。
- 播放位置流合理节流 UI 更新。
- 歌词只更新必要行。
- 数据库批量写入和事务。
- 不在 Widget `build` 中启动异步任务。
- 不因布局变化重建播放器。
- 使用 DevTools 对三套布局 Profile，并记录结果。

---

# 33. 隐私和日志

- 本地索引默认只在本机。
- 不上传文件路径。
- 不收集 API 凭据。
- Release 不记录完整 URL Query。
- 用户导出诊断日志时自动脱敏。
- About 页面声明：YYMusic 不提供曲库、在线来源由用户配置、不提供下载、数据主要保存在本机。

---

# 34. 测试要求

## 34.1 Unit

至少覆盖：

- `onAccent` 计算。
- 队列添加、移除、排序、下一首。
- 随机、列表循环、单曲循环。
- 历史去重、收藏、歌单。
- 搜索过滤。
- 本地扫描去重。
- 字段映射和 Token 脱敏。
- Source 状态机。
- Sleep Timer。
- 歌词当前行和偏移。
- 数据库 Migration。

## 34.2 Widget

- Windows Sidebar。
- 手机底部导航。
- 平板 Rail。
- Mini Player、Desktop Player。
- 全屏播放、全屏歌词、队列。
- Track Context Menu。
- 音乐源表单。
- Theme、自定义 Accent、Reduce Motion。
- Focus、Empty、Error、Loading。

## 34.3 Golden 尺寸

```text
Windows:
1440×900
1024×720
840×640

Android Phone:
360×800
390×844
430×932
844×390 landscape

Android Tablet:
800×1280
1280×800
1024×768
700×900 split window
```

关键页面：Home Light/Dark、Library、Fullscreen Player、Fullscreen Lyrics、Queue、Source Manager、Appearance、Error。

每个关键 Golden 还必须覆盖：

- App.tsx 最终图标。
- `YY Listener / 本地账户` 账户区。
- Windows/Tablet 导航 Accent 指示条。
- Figma 优化圆角和多层阴影。
- Light/Dark Glass。
- Coral、Cobalt、Jade、Amber、Graphite。
- 自定义 Accent 可读性。
- Reduced Glass。
- Reduce Motion 的稳定静态帧。
- 手机歌词 Dock 两层重排。
- 平板横竖屏歌词和播放页。

## 34.4 Integration

- 导入本地测试音频、扫描进度、播放、Seek。
- 后台/前台、队列下一首。
- 全屏播放和歌词退出。
- 歌词自动滚动、点击 Seek。
- 创建歌单和收藏。
- Fake API 搜索、认证失败、Rate Limit、Schema Mismatch。
- 在线/离线。
- Windows 拖放。
- Android 返回和手机/平板宽度切换。

## 34.5 静态约束

CI 检查 App 源码：

- 不出现 `LinearGradient`、`RadialGradient`、`SweepGradient`。
- 不出现产品 Download 操作。
- Adapter 不含下载接口。
- 不直接采用禁止的 Material 默认组件。
- 不记录 Authorization/Token。
- UI 文件不直接调用 HTTP、数据库、文件系统。

---

# 35. 构建和质量命令

每个阶段：

```bash
dart format .
flutter analyze
flutter test
```

涉及平台代码：

```bash
flutter build windows --debug
flutter build apk --debug
```

发布候选：

```bash
flutter build windows --release
flutter build appbundle --release
```

若环境不能构建某平台，必须明确写“未运行”，不能声称通过；在对应平台 CI 或开发机补齐。

---

# 36. 开发阶段

禁止一次性生成整个项目，严格按 Phase 0–11 执行。

## Phase 0：Figma 导出审计、视觉合成与架构决策

任务：

- 校验 ZIP、`App.tsx`、基础 HTML 和 `package.json` 指纹。
- 完整读取 `App.tsx`。
- 提取 44 个 `NEW_ICON_SPRITE` 图标。
- 提取两项品牌/账户文字替换。
- 提取全部 `POLISH_CSS` 规则。
- 完整读取基础 HTML 的 CSS、结构和 JavaScript。
- 生成最终合成参考 HTML，仅用于截图对照。
- 生成：
  - `docs/figma_export_manifest.md`
  - `docs/design_source_composition.md`
  - `docs/design_source_diff.md`
  - `docs/html_to_flutter_mapping.md`
  - `docs/icon_manifest.md`
  - `docs/design_tokens.md`
  - `docs/responsive_layout_map.md`
  - `docs/visual_parity_plan.md`
- 列出页面、弹层、交互、状态、断点、Token、持久化键。
- 明确 `YY Listener` 是账户而非产品名称。
- 检查现有 Flutter 仓库。
- 生成依赖候选表。
- 制定 Windows + Android 音频 POC。
- 锁定 v1 功能范围和风险。

出口条件：

- Figma 优化包和基础 HTML 均已审计。
- 最终视觉合成规则可复现。
- 44 个图标均有清单。
- `POLISH_CSS` 全部映射到 Token/组件计划。
- 三套 Shell 和共用模块边界明确。
- 依赖选择有证据。
- 尚未批量创建页面。

## Phase 1：工程骨架

任务：

- 创建/整理 Flutter 工程。
- 启用 Windows、Android。
- 创建目录、严格分析、路由、依赖注入。
- 创建空接口、Controller、三个空 Shell。
- 配置基础 CI。

出口条件：

- 工程可分析。
- Windows Debug 可构建。
- Android Debug 可构建。
- 三个 Shell 可按平台和宽度切换。
- 无重复业务逻辑。

## Phase 2：Figma 优化版设计系统

任务：

- 实现基础颜色、Light/Dark/System/Accent。
- 实现第 4.5 节的最终形状、字重、字距和阴影。
- 实现按平台适配的 Liquid Glass Token。
- 从 `NEW_ICON_SPRITE` 提取并接入 44 个 SVG。
- 实现 `YYProfileHeader`，区分产品名称和账户名称。
- 实现 Windows/Tablet Accent 左侧导航指示条。
- 手机底部导航转换为适配底部的选中样式。
- 实现 Slider 3 px Track、14 px Thumb 和桌面 Hover。
- 实现 YYArtworkPlaceholder 的纯色几何 Fixture。
- 实现核心 YY 组件和组件 Gallery。
- 生成 Light/Dark/Accent/Reduced Glass/Reduce Motion Gallery。
- 编写 Widget/Golden 测试。
- 与最终合成网页截图做视觉对照。

出口条件：

- 无渐变、无紫色、无 Material 3 默认视觉。
- 图标全部来自 App.tsx 最终 Sprite。
- 圆角、阴影、字重和导航状态符合 Figma 优化版。
- App 品牌仍为 YYMusic。
- 组件状态完整。
- 关键 Golden 通过。
- 视觉差异报告中不存在未解释的重大偏差。

## Phase 3：Domain、Database、Repository

任务：

- 模型、数据库、Migration、Repository、安全存储接口、Dev Fixture。
- 将 HTML 示例状态映射到真实数据接口。

出口条件：

- 模型和 Migration 测试通过。
- Repository 可替换 Fake。
- UI 不直接访问数据库。

## Phase 4：播放核心 POC 和正式实现

任务：

- Windows + Android 音频 POC。
- 本地 Fixture、网络测试流、Seek、状态流、队列、随机、循环、错误映射、媒体会话接口。

出口条件：

- 双平台 POC 通过。
- PlaybackController 是唯一播放真相。
- 无 Shell 专属播放逻辑。

## Phase 5：三套 UI Shell

### 5A Windows

标题栏、Sidebar、Main、Inspector、Desktop Player、Hover、Focus、右键、快捷键、窗口响应式。

### 5B Android Phone

Bottom Navigation、Mini Player、单列页面、长按、Bottom Sheet、SafeArea、系统返回。

### 5C Android Tablet

Navigation Rail、横竖屏、主从分栏、平板播放器、右侧详情和队列。

出口条件：

- 三套 Shell 视觉和交互独立。
- 业务逻辑共用。
- Golden 通过。
- Android 分屏切换不丢状态。

## Phase 6：主要功能页面

顺序：Home → Search → Library → Albums → Artists → Tracks → Playlists → Local Music → Settings。

出口条件：Loading/Empty/Error 完整；搜索真实工作；歌单持久化；大列表性能合格。

## Phase 7：全屏播放、全屏歌词、队列

任务：

- 独立 `/player`、`/lyrics`、`/queue`。
- Windows 全屏、Android 沉浸 UI。
- 同步歌词、自动滚动、点击 Seek、翻译、无歌词、返回关系。

出口条件：

- 播放页没有完整歌词。
- 歌词页不依赖播放页内部 Tab。
- 三个平台布局通过。
- Esc/返回手势正确。
- Reduce Motion 正确。

## Phase 8：本地音乐

任务：Windows 文件/文件夹/拖放；Android MediaStore/授权；Metadata、封面、增量扫描、去重、失效、重扫、进度。

出口条件：双平台真实扫描；可取消；大目录不冻结；权限状态完整。

## Phase 9：第三方音乐源

任务：Source Manager、安全凭据、REST Adapter、Auth、字段映射、搜索、Stream、Lyrics、Artwork、分页、测试、错误状态。

出口条件：Fake Server 测试通过；Token 不入日志；无下载接口；来源失败不影响本地音乐。

## Phase 10：平台媒体能力

任务：Android 后台服务、通知、锁屏、Audio Focus；Windows 媒体会话、窗口记忆、全屏恢复、输出设备状态。

出口条件：平台控制驱动共用 PlaybackController；生命周期测试通过。

## Phase 11：QA 和发布

任务：测试矩阵、性能 Profile、无障碍、禁用项扫描、安全审计、Windows Release、Android AAB、README、发布说明。

出口条件：

- `flutter analyze` 通过。
- 测试通过。
- Release 构建通过。
- 无严重无障碍问题。
- 无下载、无渐变、无紫色、无凭据泄露。

---

# 37. 多 Agent 分工

必须先由 Architecture Agent 完成 Phase 0–4，再允许 UI Agent 并行。

## Architecture Agent

负责：

```text
lib/app/
lib/domain/
lib/data/
lib/playback/
lib/platform/contracts/
docs/
```

## Windows Agent

只负责：

```text
lib/shells/windows_shell.dart
lib/features/**/windows/
lib/platform/windows/
windows/
```

不得修改 Phone/Tablet Shell，不复制 PlaybackController，不随意修改数据库 Schema。

## Phone Agent

只负责：

```text
lib/shells/android_phone_shell.dart
lib/features/**/phone/
```

不得把 Windows 页面缩小复用为手机页面。

## Tablet Agent

只负责：

```text
lib/shells/android_tablet_shell.dart
lib/features/**/tablet/
```

不得只把手机组件放大。

## Integration Agent

负责合并、冲突、状态一致、路由、Golden、集成测试和构建。

## QA Agent

负责禁用项、无障碍、性能、安全、测试矩阵和 Release 验证。

修改共用 API 前先更新 Architecture Decision Record。

---

# 38. AI 每次执行的固定格式

阶段开始前：

```text
Phase N 开始

本阶段目标：
- ...

已读取的来源：
- HTML
- 本指令
- 相关代码

准备修改的文件：
- ...

准备新增的文件：
- ...

风险：
- ...

出口条件：
- ...
```

阶段完成后：

```text
Phase N 完成报告

实际新增：
- ...

实际修改：
- ...

实现结果：
- ...

测试命令：
- ...

测试结果：
- 通过 / 失败 / 未运行
- 真实摘要

与 HTML 的对应关系：
- ...

已知限制：
- ...

下一阶段：
- ...
```

禁止：

- 未运行却声称通过。
- 只说“已完成”不列文件。
- 一次修改大量无关模块。
- 留下大量空页面/TODO 后进入下一阶段。
- 编译失败后继续堆功能。
- 删除测试或关闭 Lint 使 CI 变绿。

---

# 39. 代码规则

- Dart 严格类型。
- 公共 API 有文档注释。
- 文件 snake_case，类名清晰，职责单一。
- 禁止 God Controller。
- Widget 不直接 HTTP、SQL、文件扫描、安全存储、音频插件。
- 不在 `build()` 启动异步请求。
- 异步操作支持取消，资源正确 dispose，Stream 不泄漏。
- 临时本地媒体句柄正确释放。
- Repository 和 Gateway 都有 Fake。
- 错误统一 Result/Failure。
- 不用 `dynamic` 逃避模型。
- 不用全局可变单例保存播放状态。
- BuildContext 不进入 Domain/Data。
- 第三方插件类型不泄漏到 Feature UI。
- 生产路径不使用模拟 Toast 代替真实平台行为。

---

# 40. Figma Make / HTML 到 Flutter 映射

| 设计源内容 | Flutter 正式实现 |
|---|---|
| CSS Variables | `YYThemeExtension` / Token |
| Media Query | `LayoutBuilder` + `YYLayoutClass` |
| `localStorage` | Database + Preferences + Secure Storage |
| HTML `<audio>` | `AudioEngine` |
| Object URL | Platform Media Reference |
| `navigator.onLine` | `ConnectivityController` |
| Browser Fullscreen API | Windows/Android `FullscreenGateway` |
| DOM `active` class | Typed Controller State |
| Overlay | Route / Dialog / BottomSheet |
| HTML `data-*` | Typed Model ID / View Model |
| Static arrays | Dev Fixture |
| Simulated source test | Real HTTP Health Test |
| Browser file input | Windows Picker / Android MediaStore 或系统授权 |
| CSS Hover | `MouseRegion` + `FocusableActionDetector` |
| Right-click | Desktop Context Menu |
| Long Press | Android LongPress |
| `setInterval` progress | Audio Position Stream |
| Manual lyrics DOM | `LyricsController` + `ScrollController` |
| `NEW_ICON_SPRITE` | 44 个 SVG 资产 + `YYIcons` |
| `POLISH_CSS` | Token、TextStyle、Effect、组件状态与布局参数 |
| Brand 文字替换 | `YYProfileHeader` + 账户 Fixture/模型 |
| CSS `font-feature-settings` | 字体支持时的 OpenType Feature |
| CSS 42 px Blur | 平台适配的 Glass Sigma + Golden 校准 |
| React `App` | 不迁移，仅作为设计合成说明 |
| Blob URL | 不迁移 |
| iframe | 不迁移 |
| Tailwind/Vite | 不迁移 |

禁止：

- 运行时解析 HTML 生成 Flutter UI。
- 使用 WebView 或 iframe 作为主界面。
- 保留 DOM 风格全局状态。
- 将 React 组件包装成 Flutter 正式页面。
- 在 Release 中加载 Figma Make Web 工程。
- 只读取基础 HTML 而忽略 `App.tsx` 的最终视觉覆盖。

---

# 41. 验收标准

## Windows

- 1440×900 显示完整三栏布局。
- 1024×720 隐藏固定 Inspector，主内容无溢出。
- 窄窗口导航收缩为紧凑 Rail。
- 自定义标题栏、最小化、最大化、还原、关闭真实工作。
- Sidebar 顶部显示 `YY Listener / 本地账户`，窗口和产品品牌仍为 YYMusic。
- Expanded/Standard Windows 选中导航具有 `3×18` Accent 左侧指示条。
- Hover、Focus、Pressed、右键、拖放和快捷键真实工作。
- 底部播放器、Inspector、独立全屏播放和独立全屏歌词正常。
- Esc 退出层级正确。
- 系统媒体控制工作。
- 图标与 App.tsx 最终 Sprite 一致。

## Android 手机

- 360×800、390×844、430×932 和手机横屏正常。
- Bottom Navigation 与 Mini Player 不遮挡内容。
- 底部导航使用适合底部布局的 Accent 选中胶囊，不机械复制左侧竖条。
- SafeArea、系统返回、长按和触觉反馈正常。
- 播放页和歌词页为两个独立全屏路由。
- 歌词自动滚动、点击 Seek、双语和无歌词状态正常。
- 后台播放、通知栏和锁屏控制工作。
- 字体放大 130% 不破坏核心操作。
- Liquid Glass 在真机上无明显持续掉帧。

## Android 平板

- 800×1280、1280×800、1024×768 正常。
- Navigation Rail、横屏分栏、竖屏列数正常。
- Rail 选中项可使用 Accent 左侧指示条。
- 分屏宽度小于 600 时切换 Phone Shell。
- Shell 切换不丢失路由、滚动、当前曲目、队列和播放进度。
- 播放、歌词、队列充分利用横向空间。
- 玻璃模糊在目标平板性能可接受。

## 视觉一致性

- 最新视觉以“基础 HTML + `NEW_ICON_SPRITE` + 品牌替换 + `POLISH_CSS`”为准。
- App 名称始终为 YYMusic。
- 44 个图标均来自最终 Sprite。
- Hero、Artwork、Sidebar、Dialog、Context Menu、Lyrics Dock 圆角符合最终映射。
- Slider 视觉为约 3 px Track、14 px Thumb，触控命中区仍至少 44×44。
- Light、Dark、五个 Accent、自定义 Accent、Reduced Glass 和 Reduce Motion 均有 Golden。
- 关键 Golden 不存在未解释的重大偏差。
- Fixture 封面使用平面几何纯色，不使用渐变。

## 共用功能与安全

- 当前歌曲、队列、收藏、历史、歌单、主题、来源和本地曲库在三套 Shell 中一致。
- 单个在线来源失败不影响本地音乐和其他来源。
- 凭据不出现在数据库明文字段、日志、诊断导出和错误 UI。
- 无下载、无离线保存、无批量抓取。
- 无渐变、无紫色、无 Material 3 默认视觉、无凭据泄露。

---

# 42. Definition of Done

只有全部满足才可称为完成：

- 一个 Flutter 仓库。
- Windows、Phone、Tablet 三套 UI。
- Windows Release 可构建。
- Android APK/AAB 可构建。
- 一套播放核心、数据库、队列、音乐源 Adapter。
- 本地音乐真实扫描和播放。
- 在线来源真实测试和在线播放。
- 播放页和歌词页完全分离。
- 大字号同步歌词和全屏完成。
- Light、Dark、自定义主题完成。
- Windows 鼠标键盘和 Android 后台媒体完成。
- 测试矩阵、文档、无障碍完成。
- 无下载、无渐变、无紫色。
- 图标来自 App.tsx 最终 Sprite。
- Figma 优化版关键 Golden 无未解释重大偏差。
- 所有“通过”都有真实证据。

---

# 43. AI 的第一条执行任务

```text
1. 校验 design_reference/YYMusic_HTML.zip：
   SHA-256 = d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee
2. 解压并校验：
   src/App.tsx SHA-256 = 20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39
   基础 HTML SHA-256 = 81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229
3. 完整读取 App.tsx 的 NEW_ICON_SPRITE、品牌替换和 POLISH_CSS。
4. 完整读取基础 HTML 的 CSS、HTML 结构和 JavaScript。
5. 生成最终合成参考 HTML，仅用于截图和视觉对照。
6. 生成 docs/figma_export_manifest.md、design_source_composition.md、
   design_source_diff.md、html_to_flutter_mapping.md、icon_manifest.md、
   design_tokens.md、responsive_layout_map.md、visual_parity_plan.md。
7. 列出 4 个主页面、7 个 Overlay、44 个图标、Token、断点、持久化状态、
   播放状态、本地音乐流程、音乐源流程、全屏播放流程和独立全屏歌词流程。
8. 明确 YYMusic 是产品名，YY Listener 是账户 Fixture。
9. 检查现有 Flutter 工程并提交 Phase 0 计划。
10. Phase 0 出口条件全部满足后才进入工程骨架。
```

---

# 44. 最终总控提示词

```text
你正在开发 YYMusic。

最新设计源是 design_reference/YYMusic_HTML.zip。
将它解压到 design_reference/figma_export/，然后必须同时读取：
- figma_export/src/App.tsx
- figma_export/src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html
- YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md

先校验：
ZIP SHA-256: d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee
App.tsx SHA-256: 20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39
Base HTML SHA-256: 81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229

最终视觉不是旧 HTML 单独结果，而是：
基础 HTML + App.tsx 的 NEW_ICON_SPRITE + 两项账户文案替换 + POLISH_CSS。
App.tsx 视觉优先于旧 HTML 样式；基础 HTML 的结构与交互优先。
产品名称始终为 YYMusic，YY Listener 只是本地账户 Fixture。

必须创建一个 Flutter 仓库，通过共用 Domain、Data、Playback、Theme、
Repository 和 MusicSourceAdapter 支撑三套独立 UI：
WindowsShell、AndroidPhoneShell、AndroidTabletShell。

不得使用 WebView、iframe、Blob 或 React 作为正式客户端。
不得逐行机械翻译 HTML，不得复制三套业务逻辑。
不得使用渐变、AI 紫和 Material 3 默认视觉。
不得实现下载、离线保存或批量抓取。

必须从 App.tsx 提取 44 个最终 SVG 图标，不得用 Material Icons 替代。
必须实现 Figma 优化后的圆角、阴影、字重、字距、账户区、导航指示条、
Slider、Liquid Glass 和纯色几何占位封面。

全屏播放页和全屏歌词页必须是两个独立路由。
歌词采用 Apple Music 启发的大字号同步歌词：当前行高亮、过去和未来降低透明度、
自动滚动、点击 Seek、双语歌词、底部播放 Dock；背景只使用单一纯色专辑氛围色，
不使用渐变或模糊封面铺满。

Android 手机和平板使用同一个 APK/AAB，并根据当前窗口宽度动态切换。
Windows 使用独立桌面 Shell、真实标题栏、Sidebar、底部播放器、Inspector、
鼠标、键盘、右键、拖放、全屏和系统媒体会话。

严格按 Phase 0–11 执行。
Phase 0 必须先完成 Figma 导出审计、最终视觉合成、图标清单、Token 映射和视觉对照计划。
每个阶段开始前列出目标、文件、风险和出口条件。
每个阶段完成后运行格式化、分析、测试和适用平台构建。
不得在测试失败时继续下一阶段，不得声称未执行的测试通过。

现在从 Phase 0 开始。
```
