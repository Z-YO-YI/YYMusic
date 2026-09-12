# Phase 7E3 阶段报告 — 独立原生队列页面

2026-09-12；GitHub `Z-YO-YI/YYMusic`；分支 `codex/native-queue-route`；fetch/pull 后基线 `9a05089e9ef20bca2730bca5d5e5d81b7da3af91`，Stacked Draft PR base=`codex/queue-edit-feedback`。[计划](phase_7e3_native_queue_plan.md)与 ADR083 先于共享 API 和页面改动。

## 实际交付

- 新 `/queue` 路由接音乐库、播放器、歌词及 Shell 的既有队列入口；连续打开复用同一页面/读取会话，从播放器返回不丢根播放状态。旧 `/system-playlist?type=queue` 保留只读兼容；收藏/最近播放不改成队列编辑。
- 手机原生可滚动页面、平板横向右对齐有界区域、Windows 760 最大宽度原生面板；保留既有 Shell 和根播放器。复用 YYQueueTile、YYDialog/BottomSheet、YYButton、主题与准确 SVG，未增加 WebView、Web 运行层或新资产。
- QueuePageController 借用根系统歌单会话的 20→200 条有界读取、上一组/下一组；仅保存根快照与投影身份标签，不维护第二份可写队列。匹配 entry ID、完整 TrackRef、位置、addedAt、总数/current ID 后授权编辑，根变化刷新只读投影但不取消已接受的准确条目播放。
- 重复歌曲按独立条目播放、上下移动支持跨组锚点、缺失/未解析项仍可移除；当前项移除及清空明确确认停止，不删音乐文件/收藏/歌单、不自动播放邻项。忙态即时防双写；失败留根，跨页可见，重试只绑定原快照；旧确认/隐藏/覆盖/零面积/尺寸变化/卸载无效。
- Android 手机和平板操作常显；Windows 悬停/焦点显示，Enter/Space 原生按钮操作、Esc 先关闭确认再返回，恢复入口键盘焦点。元数据把不可用状态置于艺人之前，窄屏省略时仍能优先看到失效原因。

Figma 转代码技能促使复用已审计组件与原图标，而非重新画一套 UI。输入是本地完整 Figma Make 导出，无在线 node URL，没有虚构 get_design_context。源指纹与 ZIP24 条目重新核验，设计门禁覆盖 App.tsx 的完整 NEW_ICON_SPRITE/POLISH_CSS、44 SVG、52 确定输出；并非只参考旧 HTML。

## 验证

- 新增 7 单元、15 Widget、2 实际 SQLite 页面测试，目标 **24/24 通过**。真实事务覆盖重复条目准确播放后根投影重新绑定、排序/非当前项移除、SQL 触发器回滚、显式重试、清空及音乐记录保留；音频使用 Fake，不计为设备出声。
- 新增 **12 Golden**：360/390/430 手机、568×320 手机横屏、800×1280 平板竖屏、1280×800 平板横屏、1440×900/1024×720 Windows、空/读取错误及双平台确认，均 130% 字体。逐张查看；平板触控操作原先隐于 hover，已改为常显并重生成本批截图。短横屏内容需滚动，交互测试实际滚动到条目并点击移除。旧 **146 张**基线字节未变，未降低阈值。
- 最终 `flutter test --no-pub --reporter expanded` **1386/1386 通过**（约 69 秒）；Node **127/127 通过**（约 15.5 秒），新增独立队列根复用/身份/原生组件门禁。原系统歌单导航断言精准更新到 `/queue`，保留旧链接只读、播放器/歌词/全屏/键盘回归。
- **464 Dart 文件**格式零修改；严格分析零问题（5.8 秒）；build_runner 成功（14 秒），Drift 迁移成功。Schema、生成代码、锁文件和原始资产零差异。源 ZIP/六音频包 LICENSE/完整原生法律材料校验通过。
- 本地 Android Debug 仅作预检，构建 **41.9 秒成功**；48 原始资产、六包许可证与完整原生许可一致，APK v2 签名通过、单签名者。**232,157,345 bytes**，SHA256 `2cdb319f2bfa8c94d797b6adde508fb04304707200517ad4d2ad92a025ca967f`。仅忽略的 build 目录留包/日志。构建仍输出已知 SDK XML 版本警告，不掩盖为无警告。
- 开发时曾出现测试缺少 extension import、导入位置及懒加载列表只向下查找的测试问题；修正后重跑成功。不删除失败用例、不把首次失败计通过。横屏测试在排序后重新定位旧视窗外条目，验证真实触控可达性。

## GitHub 与剩余工作

2026-09-12 后续核验：本批精确 SHA `32edb5be72e2c7999a92009046063f7c6aacf3be` 的 [push34684110805](https://github.com/Z-YO-YI/YYMusic/actions/runs/34684110805) 与 [PR34684113148](https://github.com/Z-YO-YI/YYMusic/actions/runs/34684113148) 均 SUCCESS。[Draft PR #73](https://github.com/Z-YO-YI/YYMusic/pull/73) 未合并。源码检查、Android 和 Windows 常规任务成功；PR 日志确认 Windows 158 Golden、2 个真实 Runner 测试、正式入口 Debug 重建及 65 文件包校验通过；Android 48 资产/完整原生许可、单签名者通过。手动原生音频诊断与 Release 步骤未运行，未据此宣称真机出声或发行验收。

前置 E2 的 [push34302430226](https://github.com/Z-YO-YI/YYMusic/actions/runs/34302430226) / [PR34302434100](https://github.com/Z-YO-YI/YYMusic/actions/runs/34302434100) 均 SUCCESS，精确 SHA `9a05089` 已回填 [PR #72](https://github.com/Z-YO-YI/YYMusic/pull/72) 和 E2 报告。源码/Android/Windows 常规任务通过，Windows 146 Golden、2 Runner、65 文件正式入口 Debug 包；手动原生音频任务未运行。

本批审查后提交并 push，在对应 Stacked Draft PR 记录精确新 SHA、测试结果和云端运行链接；新 SHA 的 Android/Windows 必须独立构建，不借用前置 CI 或本地 APK 作为交付。未合并、改默认分支、发布 Release、触发手动原生媒体诊断或操作付费服务。不提交凭据、用户媒体、环境/签名文件或构建产物。

主要文件：`lib/features/queue/` 六文件、`app_router.dart`/根注入、`yy_queue_tile.dart`、系统读取刷新、四份测试与十二张 Golden、Node 门禁、README/ADR/计划/报告/状态/矩阵。

这是 Phase 7E3，不是完整 Phase 7 或应用上线。拖拽、更多添加/下一首入口、真实封面/收藏等剩余能力继续分批；Phase 8 导入/扫描/授权、Phase 9 来源、Phase 10 后台/系统媒体、Phase 11 签名/安装/发行仍待开发。新安装仍为空库。本批没有本机 Windows 编译、实际安装/出声、Android 真机系统栏或多显示器 DPI 验收；Windows 开发 Debug 依赖 Debug CRT，不能当成可分发发行版。
