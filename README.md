# YYMusic

当前阶段：**Android + Windows · Phase 3A Domain 模型与数据合同**。Phase2通用原语、三套Shell骨架、稳定Track/Collection/Lyrics/Source模型、Repository/Gateway合同及测试Fake已有。APK只由GitHub Actions构建；Phase3A本地门禁已完成，目标提交的云端双平台构建与新APK待推送后核验。不是完整音乐客户端；数据库、Migration、正式Repository/安全存储、播放、业务页和平台Gateway尚未接入。

Phase3A本地门禁已完成：108个Dart文件格式无变更、严格分析0问题、147项Flutter与32张Windows宿主Golden、29项Node、五份设计指纹及24份ZIP逐字节复核全部通过。云端状态仍必须按目标commit另行验证。

设计依据为 `design_reference/YYMusic_HTML.zip` 中完整的 `src/App.tsx` 和基础 HTML，不能只使用旧 HTML。App 的 `NEW_ICON_SPRITE`、两项账户文字替换、全部 `POLISH_CSS` 均已纳入合成。YYMusic 是产品名，YY Listener 是账户 Fixture。

## 开发入口

- [Phase 3A Domain 合同报告](docs/phase_3a_domain_contracts_report.md)、[本批范围](docs/phase_3a_domain_contracts_plan.md)、[本批 PR 草稿](docs/phase_3a_domain_contracts_pr_draft.md)
- [Phase 2J 队列与歌词原语报告](docs/phase_2j_queue_lyrics_primitives_report.md)、[本批范围](docs/phase_2j_queue_lyrics_primitives_plan.md)、[本批 PR 草稿](docs/phase_2j_queue_lyrics_primitives_pr_draft.md)
- [GitHub APK 构建与下载](docs/github_apk_build.md)、[CI 隐藏文件校验修复](docs/ci_reference_audit_fix.md)
- [Phase 2I 集合卡片报告](docs/phase_2i_collection_cards_report.md)、[本批范围](docs/phase_2i_collection_cards_plan.md)、[本批 PR 草稿](docs/phase_2i_collection_cards_pr_draft.md)
- [Phase 2H 状态原语报告](docs/phase_2h_state_surfaces_report.md)、[本批范围](docs/phase_2h_state_surfaces_plan.md)、[本批 PR 草稿](docs/phase_2h_state_surfaces_pr_draft.md)
- [Phase 2G 弹层原语报告](docs/phase_2g_overlay_primitives_report.md)、[本批范围](docs/phase_2g_overlay_primitives_plan.md)、[本批 PR 草稿](docs/phase_2g_overlay_primitives_pr_draft.md)
- [Phase 2F 播放器表面报告](docs/phase_2f_player_surfaces_report.md)、[本批范围](docs/phase_2f_player_surfaces_plan.md)、[本批 PR 草稿](docs/phase_2f_player_surfaces_pr_draft.md)
- [Phase 2E 跨平台报告](docs/phase_2e_cross_platform_report.md)、[本批范围](docs/phase_2e_cross_platform_plan.md)、[本批 PR 草稿](docs/phase_2e_cross_platform_pr_draft.md)
- [Phase 2D 报告](docs/phase_2d_android_report.md)、[本批范围](docs/phase_2d_android_plan.md)、[本批 PR 草稿](docs/phase_2d_android_pr_draft.md)
- [Phase 2C 报告](docs/phase_2c_android_report.md)、[本批范围](docs/phase_2c_android_plan.md)、[本批 PR 草稿](docs/phase_2c_android_pr_draft.md)
- [Android Phase 2B 报告](docs/phase_2b_android_report.md)、[本批范围](docs/phase_2b_android_plan.md)、[本批 PR 草稿](docs/phase_2b_android_pr_draft.md)
- [Phase 2A 历史报告](docs/phase_2_android_report.md)、[字体与图标接入记录](docs/design_assets.md)
- [Phase 1 报告与限制](docs/phase_1_report.md)、[阶段计划](docs/phase_1_plan.md)
- [当前架构](docs/architecture.md)、[验证矩阵](docs/test_matrix.md)、[工具链盘点、安装与恢复记录](docs/toolchain_setup.md)
- [PR 描述草稿](docs/phase_1_pr_draft.md)

Android 启动后，底部或左侧导航可切换首页、搜索、音乐库、设置；宽度跨越 600dp 时保留当前路由和根状态。在首页点“设计基础预览”进入 `/design-system`：切换浅色/深色/系统、五种预设/自定义 HEX、减少动态/透明，查看原生组件、滑块、七种占位封面与图标。滑块横向拖动预览、松开提交示例数值，系统取消不提交，支持键盘/无障碍增减，但不触发播放。

外观仅在本次运行保留，重启恢复默认。预览页的点击/收藏/进度只是标注清楚的本页示例状态；四个业务入口仍是工程骨架，音频、数据库和平台全屏尚未接入。

“输入与选择”可输入中文/英文、按软键盘搜索提交本页文字、清空或长按选择/复制/粘贴，切换示例筛选和加载状态。不会发送网络查询或保存搜索历史；“减少动态/透明”开关实际更新根外观状态。分段控件支持Tab定位、Enter/Space选择和窄宽横向滚动。

“内容组件 · Fixture”展示AlbumCard和TrackTile的默认、选中/播放、禁用与加载状态。点击专辑、曲目或更多按钮只修改预览页状态标签，不开始播放、不打开菜单，也不读取曲库；Phone隐藏时长，Tablet/桌面显示时长。

Windows按1440/1024断点显示240dp展开或72dp紧凑侧栏，导航驱动同一组四条路由；1440布局额外保留320dp Inspector结构位。首页同样可进入设计预览，Windows Chrome Fixture只验证按钮、Tooltip和侧栏状态，不调用系统窗口或伪造在线音乐源。正式窗口控制继续使用系统原生边框，待后续Gateway接入。

“播放器表面 · Fixture”在Android展示64dp Mini Player，在Windows展示88/76dp Desktop Player；播放、下一首、进度、音量、随机/循环、歌词、收藏和队列均为独立的受控回调，只更新预览页状态。它不调用AudioEngine、QueueController、系统媒体会话、数据库或持久化，正式Shell仍保留未接入槽位。

“弹层原语 · Fixture”展示最终Context Menu、Windows不透明Dialog或Android Phone Bottom Sheet，以及受控Toast；键盘/Esc/焦点与无障碍由原生Flutter组件处理。Fixture只更新本页文字，不创建正式Overlay/Route，不监听真实右键/长按，不启动Toast计时器，也不执行播放、队列、歌单或设备操作。

“状态与反馈 · Fixture”展示播放队列空态、错误Banner与静止纯色Skeleton；强调色预设使用30px视觉/44dp命中的ThemeSwatch。重试只更新本页文字，不访问网络；组件不启动加载、计时器、Repository或生成假结果。

“来源与歌单 · Fixture”展示调用方控制的来源状态、普通/选中/禁用/加载歌单与Create虚线卡片。点击只更新本页说明或选择；不测试连接、不读取凭据、不创建真实歌单，也不访问Repository、数据库、队列或持久化。

“队列与歌词 · Fixture”展示标准/沉浸队列行、future/past/active双语歌词和响应式Lyrics Dock。上移/下移/移除、歌词行、Transport、进度、收藏和返回只更新本页状态；不修改真实队列、不Seek、不解析LRC、不自动滚动或推进计时。

Phase3A数据合同不新增可见页面。TrackRef保留来源身份，QueueEntry使用独立ID以允许重复曲目；来源公开配置只保存credentialRef，秘密仅通过SecureCredentialGateway。当前Fake只用于测试，不会在正式Shell中伪造在线来源、歌曲、歌词或数据库成功。

## Phase 0 审计入口

- [Phase 0 完成报告](docs/phase_0_report.md)与[阶段计划及出口](docs/phase_0_plan.md)
- [指纹和完整导出清单](docs/figma_export_manifest.md)
- [合成规则及 CSS 层叠差异](docs/design_source_composition.md)
- [HTML → Flutter 功能映射](docs/html_to_flutter_mapping.md)
- [架构决策](docs/architecture_decisions.md)、[依赖候选证据](docs/dependency_decisions.md)、[双平台音频 POC 计划](docs/audio_poc_plan.md)
- [实施状态与下一阶段前置条件](docs/implementation_status.md)

## 运行与验证

开发基线：Flutter 3.47.2 / Dart 3.13.2（stable），CI 固定相同 Flutter 版本。先确认 flutter doctor；Windows 需要 Visual Studio Desktop development with C++，Android 需要 SDK 命令行工具及用户认可的 SDK 许可。本机缺失项见工具链文档，不能将分析/测试通过当作构建通过。

2026-08-31 环境补齐：复用已安装的 Flutter、Android Studio 和 JDK；新增 Android 命令行工具 22.0、API 36 与 NDK 28.2.13676358，配置用户级路径并保留恢复备份。Android Debug APK 已构建并通过签名校验；Windows C++ 安装仍等待管理员确认，双平台构建状态以工具链记录为准。安装包、机器配置及构建产物不提交仓库。

```powershell
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --coverage
# APK交付由GitHub Actions执行；不要用旧本机APK替代云端产物。
# Windows 工具链就绪后单独验收；本地尚未完成。
flutter build windows --debug --no-pub
```

工具链完整后使用 `flutter run -d windows` 或 `flutter run -d <android-device-id>`。不要重新运行 flutter create 覆盖现有工程。Android 发行签名未配置，禁止使用 Debug 签名冒充 Release。

需要APK时，在[GitHub Actions](https://github.com/Z-YO-YI/YYMusic/actions/workflows/foundation.yml)对目标分支手动运行工作流；成功后从该次运行生成的私有草稿Release下载。Phase2J实现提交a20e0fb已由[运行33476650469](https://github.com/Z-YO-YI/YYMusic/actions/runs/33476650469)生成并完成[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-94db6b8c22a40fb18b24)复核，APK SHA-256为`864a557af71841280ed938e80090a07e3bd7764a8e3680a17b6eef81e19af43f`。必须确认Android任务、Release标签、metadata完整commit和SHA256SUMS一致；普通push/PR只验证构建，不创建下载产物。APK不提交Git源码，证据见[Phase2J报告](docs/phase_2j_queue_lyrics_primitives_report.md)，详情和临时Debug签名限制见[构建说明](docs/github_apk_build.md)。

无已连接真机/模拟器或本机Windows原生运行验收证据，构建成功不等于已安装运行。32张组件/原生Shell Golden使用打包字体、Flutter 3.47.2 / Windows测试宿主，精确像素比较；Linux明确跳过这32张，运行其余115项测试，Windows CI执行Golden。只在审查视觉变更后对指定测试使用`--update-goldens`，日常测试不得更新基线。

## 设计与归档完整性

需要 Node.js 22 或更高版本及PATH中的PowerShell 7（`pwsh`），无额外包依赖；这些命令不执行参考 HTML 的脚本，不构建 Flutter。新增归档回归仅改动临时副本，覆盖隐藏文件与完整性失败情形：

```powershell
node --check tools/design_audit.mjs
node --check tools/design_audit.test.mjs
node tools/design_audit.mjs --check
node --test tools/design_audit.test.mjs tools/design_assets.test.mjs tools/legacy_archive.test.mjs tools/foundation_architecture.test.mjs tools/android_artifact.test.mjs tools/reference_archive.test.mjs
pwsh -NoProfile -File tools/verify_reference_archive.ps1
```

重新生成派生资产使用 `node tools/design_audit.mjs --write`。输入指纹不匹配时失败，不能直接更新预期哈希掩盖变动。

开发参考：[最终合成 HTML](design_reference/generated/YYMusic_Figma_Composed_Reference.html)。仅用于获准环境中的视觉对照，不是正式客户端或已通过的截图基线；不应将 `design_reference` 声明为 Flutter Release assets。

## Git 与历史原型

仓库：[Z-YO-YI/YYMusic](https://github.com/Z-YO-YI/YYMusic)。当前开发分支`feat/domain-model-contracts`基于已拉取并同步的`feat/cross-platform-queue-lyrics-primitives@3c09ed7`，未在main/master开发。此前阶段提交保留；合并前需审核完整分支差异。经用户明确授权曾恢复临时GitHub API访问，不持久化访问令牌；Git提交/推送和云端产物状态以每次交付时实际核验为准。

旧原型 13 个文件已原样迁入 [archive/sonic_gallery](archive/sonic_gallery/README.md)，并在 `f96197b` 单独提交；源码、两份测试、配置和图片可恢复，不再散落为根目录未跟踪文件。Phase 0 中“保留原地、未纳入提交”的说明是当时历史状态。

正式客户端只来自根 lib/，不依赖 archive 或 design_reference。归档目录有独立 pubspec，但不是当前工程的测试目标；禁止对整个仓库递归格式化，破坏原始指纹。
