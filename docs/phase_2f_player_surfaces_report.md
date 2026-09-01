# Phase 2F — 跨平台播放器表面报告

2026-09-01。开始前已fetch并确认`feat/windows-navigation-foundation@99b664a`与远端0/0同步、工作树干净；从该提交创建`feat/cross-platform-player-surfaces`，未在main/master开发。阶段范围、来源与出口见[计划](phase_2f_player_surfaces_plan.md)。

## 当前实际进度

Phase0五份源指纹、完整App.tsx、基础HTML、`NEW_ICON_SPRITE`和`POLISH_CSS`仍是唯一设计依据。本批只交付原生受控播放器表面与跨平台Gallery Fixture；整个Phase2尚未完成，正式业务页面、数据库、来源Repository、菜单/弹层、真实AudioEngine、队列算法、系统媒体会话及窗口Gateway均未接入。

## 实现

1. `YYNowPlayingViewData`只保存UI所需的受控快照：曲目文字、位置/时长、封面种类、播放/收藏/随机/循环、音量；它不计时、不导入Domain或插件类型。
2. `YYMiniPlayer`保持64dp、48dp封面和12dp封面圆角；曲目信息、播放/暂停与下一首分别拥有独立命中、焦点和语义边界。
3. `YYDesktopPlayerBar`按布局使用88/76dp、54/50dp封面和14dp封面圆角。完整形态提供Transport、进度、全屏、歌词、收藏、队列、设备/音量；紧凑与低宽形态按基础HTML规则收缩，但不让动作越界。
4. 进度与音量复用`YYSlider`。进度拖动只预览，结束才提交，取消不提交；组件不自行Seek或推进时间。Repeat的off/all/one仅是视觉枚举，不执行队列逻辑。
5. Android/Windows Gallery持有明确标注的本页Fixture并展示正常、紧凑、Loading/Disabled；操作只更新页面文字或局部数据，不调用音频、队列、系统、网络、文件、数据库或持久化。
6. 正式Android/Windows Shell没有接入这些Fixture，仍保留未接入播放器结构位，等待Phase4/5从唯一播放真相经Feature/Presenter映射。

## 设计与视觉依据

本批重新读取主指令Phase2组件清单、基础HTML播放器全部CSS/响应式规则和完整Footer标记，并审计App.tsx最终`NEW_ICON_SPRITE`。最终`POLISH_CSS`没有播放器条选择器，因此保留基础HTML的播放器几何，而图标仍全部取自最终Sprite。没有只读旧HTML，没有WebView、React运行时、Material默认视觉或渐变。

新增三张1280×560、DPR1、130%文字的组件板：浅珊瑚、深翡翠、浅色自定义白/ReduceGlass；每张覆盖Desktop88、Narrow76、Mini64和Loading/Disabled。三张已逐张查看，封面、文字、进度、Transport、工具区、音量及白色强调色均无裁切、溢出或不可辨识；旧17张基线不更新。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式与严格分析 | 69个Dart文件格式无变更；`flutter analyze --no-pub --fatal-infos --fatal-warnings`为0问题 |
| Flutter完整回归 | 95项通过：Phase2E 88 + 播放器Widget4 + 播放器Golden3 |
| 播放器交互 | 4项定向Widget通过：数据不自行计时；Mini几何/动作/状态；Desktop独立动作与Seek边界；紧凑/低宽/Loading无溢出 |
| Golden | 新3张逐张查看；旧17张不更新；20张串行非更新精确比较通过 |
| Node/源码门禁 | 28项Node、五份源指纹、44 SVG、派生产物及13个归档文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | 无新Flutter依赖、平台权限、机器环境、媒体或用户数据变更 |

## 云端与限制

实现提交`a1eacd986eaad83de3d8115e827dbffddfe3f236`的push[运行33462315349](https://github.com/Z-YO-YI/YYMusic/actions/runs/33462315349)与PR[运行33462439635](https://github.com/Z-YO-YI/YYMusic/actions/runs/33462439635)均成功；两组各自的Source checks、Windows Debug（含20张Golden）和Android Debug三个job均逐项确认success。

手动[运行33462929516](https://github.com/Z-YO-YI/YYMusic/actions/runs/33462929516)同样三个job全部成功，并创建私有[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-9d76706cca2e06858535)。Release为draft/prerelease，目标为完整实现commit；仅有`YYMusic-debug.apk`、`SHA256SUMS`、`build-metadata.json`三个白名单资产。三者已独立下载，metadata的repository、commit、run URL、attempt、Flutter3.47.2、Debug临时签名身份与APK字段均一致。

APK为175792949字节，本地SHA-256、SHA256SUMS、metadata及GitHub API digest四方均为`df0b96062e96332206630ded3cc35117f244d31c079f2ec76c3f3b3d06a3254a`。本机Build Tools36.0.0再次验证v2为true，v1/v3/v3.1/v4为false；临时下载目录经路径校验后已清理。

本机Windows C++工具链仍受远程UAC限制，因此本批不声称本机`flutter build windows`或安装运行成功。GitHub Windows Runner成功也不能替代用户电脑安装、Windows系统辅助技术/GPU Blur性能、Android真机/TalkBack/IME或真实播放验收。APK为临时Debug签名，不是正式发布包或稳定升级密钥。

## 主要文件

- `lib/design_system/yy_player_data.dart`
- `lib/design_system/yy_player_surface.dart`
- `lib/features/design_gallery/gallery_player_surfaces.dart`
- `lib/design_system/yy_artwork_placeholder.dart`
- `lib/design_system/yy_tokens.dart`
- `test/widget/player_surfaces_test.dart`
- `test/golden/player_surfaces_golden_test.dart`及三张新基线
- ADR、架构、视觉、矩阵、状态、README与CHANGELOG状态文档

下一批仍需从Phase2独立小范围继续；不得用播放器视觉组件冒充Phase3/4/5的Repository、真实音频、队列或平台集成。
