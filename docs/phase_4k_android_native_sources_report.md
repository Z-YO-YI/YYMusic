# Phase 4K — Android 本地来源验证报告

2026-09-05；实现提交 `33a0b3cadb0a103546c116da18b821f7ee342b0f`，
分支 `codex/android-native-source-validation`，基于已拉取的 `ca7b69d`。
[Draft PR #27](https://github.com/Z-YO-YI/YYMusic/pull/27) 叠加在 PR #26 分支，未合并。

## 当前阶段与变更

完整重读 v2 总指令并复核身份，仍在 Phase 4；本批不提前实现 Phase 5 页面。
新增 Android Debug 集成入口，直接调用未改变的原始本地 WAV 用例，另测 content URI：
缺失文件应返回 `playbackOpenFailed` / `audio.just-audio.open`，不泄露定位符；
运行时生成缓存夹具后，必须在同一引擎恢复，并验证 load 不自动播放、3 秒 duration、
真实 position、seek、pause、volume/rate、completed、stop、状态流关闭和 dispose。
夹具独占创建、不覆盖旧文件，结束后仅清理本测试文件。

Provider、Android main/profile Manifest、生产入口、依赖和旧 WAV 用例没有改动。
CI 新增默认 `both` 的手动平台选择，Windows 原始用例与真实端点门禁保留。
原生模式不触发常规发布 job；Windows skipped 不算 Windows native 通过。

## 本地实际验证

| 命令/检查 | 结果 |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 157 文件，0 改动 |
| `flutter analyze --no-pub --fatal-infos` | 0 问题 |
| `flutter test --no-pub --reporter expanded` | 249/249，含 32 张 Windows 宿主 Golden |
| `node --test tools/*.test.mjs` | 44/44 |
| `tools/verify_reference_archive.ps1` | 原 ZIP 24/24 entry 逐字节一致 |
| `dart run build_runner build` / `dart run drift_dev make-migrations` | 成功；g.dart 和 drift_schemas Git 零差异 |
| `flutter build apk --debug --no-pub` | 成功；仅本地构建验证，不作为 APK 交付 |
| 同命令附 `--target=integration_test/just_audio_android_sources_poc_test.dart` | 测试入口成功编译；APK Manifest 确认 Provider 未导出、无 URI 授权；随后已重建正式入口，恢复下方原 APK 哈希 |
| `tools/verify_android_apk.ps1` | 48 项 SVG/字体/许可字节一致；无私密参考和被拒绝的 media_kit 原生库 |
| `apksigner verify --verbose` | v2 有效，1 signer |
| `git diff --check` / 新增变更常见凭据扫描 | 通过，无 Token/私钥/音频/产物提交 |

本地 APK 230,987,069 字节，SHA-256
`38fda801f85cbba7cbf4544bb92ae91b22de7796b4e147ad81c76852cf394c0f`。
本批生产与依赖无改动，和 Phase4J 同哈希是预期结果；不能当作新业务功能证据。
本机 Windows 无完整 C++/插件 symlink 构建环境，本批以 GitHub Windows Debug 验证。

## GitHub 实际结果

- [原生手动运行 33953874067](https://github.com/Z-YO-YI/YYMusic/actions/runs/33953874067)
  整体 success，目标为上述精确实现提交；checks 与 Android 原生 job 通过。Windows 原生、常规
  Windows 构建及 Android 发布 job 按显式 `android` 模式 skipped；不计为 Windows native 通过。
- push `33953859229` 被同分支原生运行的 concurrency 取消，不计作代码失败或构建通过。
- [PR 标准运行 33953908502](https://github.com/Z-YO-YI/YYMusic/actions/runs/33953908502)
  整体 success：checks、Windows Debug（含32张宿主 Golden）、Android Debug/签名/资产全部成功。
  两个原生 job 按标准模式 skipped，发布步骤 skipped。
- API 复核两个成功运行均为 `33a0b3c`、artifact 均 0；全部17项现有 Release 中，匹配该提交、
  分支或运行号的新 Release 为 0。没有上传 WAV、测试 APK、私有日志或凭据。

原生 job `101273993185` 日志在 2026-09-05 08:06:59 UTC 报告 `+2: All tests passed!`，
下表只保留合成夹具的白名单计时，未提交原始日志或完整定位符：

| Android API36 x86_64 用例 | load ms | 首进度 ms | seek ms | duration ms | 结果 |
| --- | --- | --- | --- | --- | --- |
| 原始本地 WAV | 536 | 75 | 11 | 3000 | completed、stop、teardown 通过 |
| Debug-only content URI | 29 | 170 | 7 | 3000 | 缺失文件拒绝、同引擎恢复、completed、stop、dispose/状态流关闭通过 |

两个用例的 `proxyForHeaders` 和 `requestHeaders` 均为 false。此结果关闭 Phase4K 本批出口，
不关闭整体 Phase4F，也不外推为真机、网络来源或正式应用可用。

## 主要修改文件

- `integration_test/just_audio_android_sources_poc_test.dart`：新增原生用例。
- `.github/workflows/foundation.yml`：显式平台选择及 Android 入口；格式检查包含集成测试。
- `test/unit/ci_configuration_test.dart`、`tools/foundation_architecture.test.mjs`：路由、隔离和安全门禁。
- README、实施状态、测试矩阵、Phase4K 计划/报告：同步使用方式和真实证据。

## HTML 映射、限制与下一批

本批没有 UI 改动，App.tsx 的 NEW_ICON_SPRITE、两项文字替换、POLISH_CSS、原 HTML
及全部派生映射不变；没有 WebView 或截图基线更新。参考网页截图对照仍是 Phase 2 验收缺口。

Android 模拟器验证不证明实体扬声器听感，私有 Provider 不证明 SAF/MediaStore/持久授权。
Android 与 Windows 无 Header HTTPS、最终候选决策/许可展示、生产接线仍未闭合，
Phase4F 不能关闭。正式应用仍为 `UnavailableAudioEngine`；Phase 5—11 和可用音乐应用尚未交付。
下一批继续剩余原生来源验收，再决定正式音频接线；不使用 TLS 绕过、代理、下载或缓存实现。
