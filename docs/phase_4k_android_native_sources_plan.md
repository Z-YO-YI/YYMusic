# Phase 4K — 当前候选的 Android 本地来源原生验证

2026-09-05。完整重读用户的 v2 Figma Optimized 总指令；Downloads 与仓库副本
SHA-256 均为 `5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf`。
ZIP 的 24 个 entry 再次逐字节通过，App.tsx、NEW_ICON_SPRITE、两项文字替换与
POLISH_CSS 合成审计未漂移。已 fetch/pull `codex/windows-native-audio-validation`，
从同步的 `ca7b69d6b039e431a1e389c513909b5d06d24efc` 创建
`codex/android-native-source-validation`，不在 main 开发。

## 目标与依据

当前位于 Phase 4，而非可用应用阶段。Phase 0—3 已有实现和审计产物；Phase 2
仍欠参考网页截图对照。Phase 4J 已补 Windows 真实本地 WAV 运行，最后文档提交的
PR 33951668314 / push 33951666657 也已全部成功。

本批补 Phase 4F 的当前 Android 本地 WAV 复跑及 `content://` 验收。
已读总指令全文、Phase 4F/4J 报告、候选引擎/后端、原始 WAV 集成测试、只读 Debug
Provider、CI 和相应门禁。旧 media_kit 的 Phase 4D 结果不能替代当前候选证据。

## 实施与文件范围

- 新增 `integration_test/just_audio_android_sources_poc_test.dart`，调用原始本地 WAV
  测试入口；另测缺失 content 文件的脱敏失败、同一引擎恢复、非自动播放、duration、
  position、seek、pause、volume/rate、completed、stop 和 dispose。
- 复用已有 Debug-only、未导出、只读 Provider；仅在 app cache 临时生成确定性 WAV，
  不覆盖旧文件，测试结束清理。禁止读用户曲库、请求存储权限、提交/上传媒体。
- 修改 `.github/workflows/foundation.yml`：默认 `both` 的显式
  `just_audio_poc_platform` 选择仅限制手动原生测试任务；Android 运行新入口，Windows
  保留原入口和真实端点失败门禁。原生模式仍跳过常规构建/发布且无 artifact/Release。
- 补 `test/unit/ci_configuration_test.dart` 和 `tools/foundation_architecture.test.mjs`
  的平台路由、默认值、隔离和敏感内容门禁；CI 格式检查覆盖 integration_test。
- 更新 README、实施状态、测试矩阵与本批报告。不修改生产、依赖、公共 API、Schema、
  设计组件或截图基线；无共享接口变更，不新增 ADR。

## 风险、验证与出口

模拟器没有实体扬声器；通过仅证明 Android 原生解码器/时间线，不证明主观听感。
content URI 只证明本 app Provider，不证明 SAF/MediaStore 或持久授权。
插件可能有异步错误/恢复差异，必须以真实断言结果为准；不放宽测试、假时钟或 TLS。

运行 format、严格 analyze、完整 Flutter/Node、24 项 ZIP、生成代码/Drift 零差异、
本机 Android Debug/48 项包内资产/签名；GitHub 标准 PR 双平台 Debug，以及显式
Android-only 原生运行。按精确提交记录测试计时、job、artifact/Release 数量，提交推送/PR。
任何未运行或失败项明确保留，不把 Windows skipped 计为通过。

本批不关闭 Phase 4F：仍欠无 Header HTTPS、最终候选评估/选型及生产接线；不进入 Phase 5。

## 运行方式

Android Debug 设备上运行：

```powershell
flutter test --no-pub integration_test/just_audio_android_sources_poc_test.dart -d <android-device-id> --reporter expanded
```

GitHub Actions 手动运行当前分支，设 `run_just_audio_poc=true`、
`just_audio_poc_platform=android`、`build_windows_audio_probe=false`。
`both` 仍会检查 Windows 真实端点，在缺端点的托管机上会失败；不会自动降级。
