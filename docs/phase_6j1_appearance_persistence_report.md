# Phase 6J1 — 外观设置持久化完成报告

2026-09-09，Z-YO-YI/YYMusic，`codex/appearance-settings-persistence`。
基于fetch/pull后的干净`b1adbce399ba1a798b2d0b65c2ecb2f11c9ccbd6`，stacked Draft PR base=`codex/local-music-surfaces`，不修改main或自动合并。

## 实际新增与修改

- `lib/domain/models/appearance_settings.dart`与`appearance_settings_repository.dart`：不可变纯Domain快照和合同，三模式、五预设及合法六位自定义色、玻璃与减少动态；保留活动自定义色原始输入、调试字符串脱敏，无任意键/JSON/凭据接口。
- `lib/data/repositories/drift_appearance_settings_repository.dart`：借用同一数据库，只读themeMode/accentPreset/customAccent/glassEnabled/reduceMotion五键；缺失键使用默认但不回写，未知或损坏值返回安全Failure。
  五键同事务更新、时间一致、保留所有无关设置；依赖调用前登记待完成操作，dispose拒绝新操作并排空，不自行关共享数据库。
- `lib/features/settings/common/appearance_settings_controller.dart`：监听唯一根外观状态，启动恢复不触发保存；启动前/期间已出现用户修改不被晚返回覆盖。
  保存单worker串行合并，失败保留当前外观且不停止音频；显式重试读取或最新快照，新修改可重试保存。停止接受变更后排空最后已接受值，未保存成功时关闭报告安全错误。
- `AppDataServices`/`DatabaseAppDataServices`/`DependencyGraph`：生产同范围注入外观仓储，初始化先恢复外观后进入业务UI，关闭先排空桥接器再关存储；隔离无仓储测试保持session-only，不伪称持久化。
- `YYAppearanceController.restore`：原子恢复一次通知，复用既有颜色/对比度/系统减少动态计算；通知期间根关闭延后Notifier最终释放，关闭后旧变更不再生效。
- 新增隔离Fake、Controller/SQLite测试，扩展应用启动Widget；两项Node白名单/根生命周期门禁，既有关闭顺序检查加入新控制器，未移除检查。
- ADR-073先于共享API变更；同步计划、README、状态、矩阵、本报告，并回填I2精确云端证据及PR #61。

## 来源与实现边界

主指令设置持久化/安全/Phase6顺序、HTML完整设置区及theme/accent/toggle脚本，完整506行App.tsx的44 NEW_ICON_SPRITE、品牌替换和POLISH_CSS已读取并复验。
figma-design-to-code技能要求复用既有视觉，本批不增加新UI或近似图标，不改色值/圆角/阴影/字体；本地Figma Make导出没有在线node，不捏造get_design_context。
浏览器localStorage被类型化数据库白名单替代，不执行网页脚本，不持久化凭据，不把HTML示例gapless/normalize等开关当成真实引擎能力。
自定义色仅活动时保存；选择预设后不额外保留上一次未活动的自定义色。保存读取失败时默认不抹掉旧记录，不提供自动重置或清库操作。

## 测试命令与实际结果

- `dart format --output=none --set-exit-if-changed lib test integration_test`：404文件零修改。
- `flutter analyze --no-pub --fatal-infos`：最终零问题，13.6秒。
- `flutter test --no-pub --reporter expanded`：最终1056/1056通过，60秒；新增27项=15 Controller、9真实SQLite、1模型、2启动Widget。
- `node --test tools/*.test.mjs`：115/115通过，约18秒。104张旧Golden通过且字节未改，未新增或改动基线。
- `dart run build_runner build`、`dart run drift_dev make-migrations`：通过；生成文件、Schema、lockfile、平台、原始资产与Golden无差异。
- `node tools/design_audit.mjs --check`：5指纹/44图标/52确定产物通过；`tools/verify_reference_archive.ps1`：24原ZIP条目逐字节一致。
- `tools/verify_audio_licenses.ps1 -Mode Source`和`tools/verify_native_audio_notices.ps1 -Mode Source`分别通过。
- `flutter build apk --debug --no-pub`：成功；`tools/verify_android_apk.ps1`：48原始资产、六音频包许可、完整原生许可及私密/参考文件排除通过。
- `apksigner verify --verbose`：v2单签名者；本地APK232,022,802 bytes，SHA-256 `92f6ffd17fec2d8bf3c52eba2f9f896a8ab94e2aa6cbd0de5a418c215ad4d6c4`。

真实数据库测试包括：只查询白名单所以无关坏JSON不影响恢复；中途失败回滚全部五键；延迟实际SELECT/INSERT时关闭等待；重建磁盘数据库和整个根后恢复自定义色/系统模式/玻璃与动态设置。
未运行的项目不算通过：本机Windows构建、本批Android实机安装/出声未运行，Windows和Android精确提交验收由push/PR的GitHub Actions完成。
初轮导入位置、测试扩展方法和Fake推断类型、格式/控制流问题已修正重跑，未关闭Lint、删除测试或跳过失败。仅测试专用临时数据库在确认位于系统临时目录后清理，不读取或修改用户个人音乐数据。

## 同步、限制与下一步

前置I2精确提交`b1adbce`的push 34266399867/PR 34266442192已success：两组Linux925/104跳过、113 Node，Windows各104 Golden+1真实窗口，双平台Debug完整包通过；证据已回填I2报告和PR #61，不替代本批云端验收。
本报告记录提交前本地证据，提交/推送和Draft PR后核对精确CI；未发布Release、手动诊断、付费操作或自动合并。
21个变更文本文件提交前敏感模式扫描零命中，`git diff --check`通过；未纳入.env、凭据、APK、日志或其他不必要产物，104旧Golden与生成/平台/原始资产零差异。
新增持久化已连接现有根控件，包括开发预览，但正式原生设置页面尚未实现；读取/保存失败和重试状态目前由根合同提供，下一批Phase6J2接入可见提示与原生入口。
本批不宣称设置模块、Phase6–11或日常安装使用完成。默认新安装仍为空库，没有真实导入扫描；Windows Debug不是通用发行安装包。下一步按指令实现原生Settings，再推进完整播放/歌词/队列、扫描/授权、来源、平台媒体和QA发行。

## 精确 GitHub 验收回填（Phase 6J2 核对）

`993aab2c9b802f116aea55ea93f63b3496bba86a` 的 Push [34270115448](https://github.com/Z-YO-YI/YYMusic/actions/runs/34270115448) 与 PR [34270151512](https://github.com/Z-YO-YI/YYMusic/actions/runs/34270151512) 均已 SUCCESS，#62 仍 Draft/OPEN 未合并。
两组 Linux 各 952 Flutter 通过/104 宿主 Golden 跳过，Windows 各 104 Golden 与 1 项真实窗口生命周期通过。
Android Debug 两组均完成 51 个原生音频坐标/3 份完整法律文本、48 项包内原始资产和签名验证；Windows 均验证 65 文件及六音频包/原生完整许可。
Push 的 Windows 开发包 artifact `10073921806`（67,443,931 bytes）未过期，SHA-256 `27e795aa3f78b50d5e883ab1d573531ab3d85a30b480e53d6dd1c0ef9f0c0798`，到期 UTC 2026-09-22 19:50:54；仅开发 Debug，不是通用发行版。
Android 在云端构建验证成功但该普通运行没有上传 APK artifact，不能提供虚构 APK 下载链接。未发布 Release、未手动触发音频诊断，也未进行本批实机安装/出声验收。
