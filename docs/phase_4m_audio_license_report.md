# Phase 4M — 音频许可基础报告

2026-09-05。初始实现 `2143ecf3f8bb9e9cd737c3d70e0af0470a845899`，参数修正
`c0e370604e16978a15be42e4380af0289347be29`，分支
`codex/audio-license-foundation`，基于已 fetch/pull 且同步的 `17b10db`。
上一批文档的标准 push 33955863157 / PR 33955865390 均已成功，PR #28 保持 Draft、未合并。

## 实际新增与修改

- `docs/legal/just_audio/manifest.json`：六个精确包版本/完整LICENSE长度与指纹、两个原生构建文件指纹，
  AndroidX Media源提交/根许可和明确的未覆盖项。
- `tools/audio_license_audit.ps1`、`tools/verify_audio_licenses.ps1`：源码缓存、APK与Windows目录的只读校验。
  验证4 MiB压缩/16 MiB展开/10000组限额、严格UTF-8、目标包唯一和全文字节指纹。
- `tools/audio_license_audit.test.mjs`：5项测试，包含全文去重/分组、遗漏/重复/错标签/篡改、空清单、
  非法压缩/编码、两级体积，以及实际APK入口的缺失/重复/超限拒绝。
- `verify_android_apk.ps1`、`verify_windows_bundle.ps1`新增许可校验；原有48项资产、
  必需Windows文件、隐私文件与被拒绝候选排除均不移除。
- CI在严格lockfile解析后增加源码指纹检查；原有测试/构建/发布条件、权限和保留期不变。
- ADR-041、依赖决策、计划与README同步更新。

自审发现PowerShell的ValidateSet默认不区分大小写，而入口最初使用大小写敏感分支判断，
`-Mode android`可能错误进入Windows路径。修正提交将分支判断与参数合同统一，并增加小写/混合大小写
实际APK入口回归；源码模式的小写实测也通过。同时避免使用PowerShell自动变量`Matches`作为局部包数组。
全套51项工具测试复跑通过，三个小写模式对实际源码/APK/Windows包校验也均通过。

没有新增依赖、音频原文副本、音频文件、应用资产、运行时API、权限或数据库变更。

## 与实际构建包的关系

Flutter 3.47.2的本地SDK源码已核对：LicenseCollector按原文去重并保留包名，原生资产为`NOTICES.Z`，
ServicesBinding注册到LicenseRegistry并按需解压。原文原本已打包，本批新增的是防止缺失/漂移的检查。
不会把包名或“MIT/Apache”字样存在当成完整许可证文本已经包含。

六包对应四个实际许可组：just_audio、just_audio_windows、rxdart各一组；
audio_session/just_audio_platform_interface/just_audio_web共享完全相同原文，仍逐包验证唯一身份。
本地Android正式入口APK与Phase4L Windows Profile运行目录均通过全文原件指纹检查。
后者来自 `8c4aa6e` 的已校验归档，运行时基线64项加测试结果共65文件；
这是旧包的新增只读许可复核，不伪称已对 `2143ecf` 做新的Windows原生播放。

## 本地验证

| 检查 | 结果 |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | 161文件0改动 |
| `flutter analyze --no-pub --fatal-infos` | 0问题 |
| `flutter test --no-pub --reporter expanded` | 255/255，含32张Windows Golden |
| `node --test tools/*.test.mjs` | 最终51/51，既有46项全部保留 |
| 原ZIP与总指令身份 | ZIP24/24；Downloads/仓库指令SHA一致 |
| build_runner / Drift make-migrations /生成文件Git差异 | 成功，0输出/0差异 |
| `verify_audio_licenses.ps1 -Mode Source` | 六LICENSE与两个原生构建源文件全文匹配 |
| 新构建Android Debug与包检查 | 构建成功；六项包许可、48设计资产、排除规则通过 |
| Android apksigner | v2有效，1个Debug签名者 |
| Windows Profile现有真实包 | 六项包许可全文匹配，原排除门禁通过 |
| Git diff /常见凭据扫描 | 通过 |

本地APK仍为230,987,069字节，SHA-256
`38fda801f85cbba7cbf4544bb92ae91b22de7796b4e147ad81c76852cf394c0f`。
本批未改应用资产或运行代码，因此同哈希符合预期，不代表新增业务功能。
Java原生访问警告仍由既有Gradle/apksigner输出，不改变JDK、全局参数或系统设置压制它。

## GitHub

实现提交已推送，分支追踪远端且无ahead/behind；[Draft PR #29](https://github.com/Z-YO-YI/YYMusic/pull/29)
基于 `codex/native-https-validation`，未合并。初始实现的
[push 33956519388](https://github.com/Z-YO-YI/YYMusic/actions/runs/33956519388)与
[PR 33956538735](https://github.com/Z-YO-YI/YYMusic/actions/runs/33956538735)均整体成功，
checks、Windows Debug、Android Debug均通过。两条checks日志均已提取到六LICENSE/两个构建源指纹通过；
push的Windows job 101281191340与Android job 101281191413均明确记录NOTICES.Z全文匹配，
同时Windows64项文件/禁用候选排除与Android48项资产校验通过。
参数修正 `c0e3706` 的
[push 33957029385](https://github.com/Z-YO-YI/YYMusic/actions/runs/33957029385) /
[PR 33957031070](https://github.com/Z-YO-YI/YYMusic/actions/runs/33957031070)也已整体成功，
两条各自的checks、Windows Debug、Android Debug全部通过，API head SHA分别核对。
修正版PR Windows job 101282608352确认六包原文和64文件；Android PR/push job
101282608462 / 101282611077分别确认六包原文和48资产；checks原件指纹也通过。
因此不需要借用初始实现的结果作为修正版证据。

四条运行的artifact数量依次1/0/1/0，仅普通push既有14天Windows Debug包；没有手动原生/诊断运行。
Release列表总数17，两个实现SHA、分支、四个run ID匹配新增数均0，没有新的APK下载资产。
最终报告的后续文档提交只更新说明，CI须按该提交独立查看，不把这里的实现运行冒充后续提交已通过。

## HTML对照、覆盖边界与下一步

本批不改HTML/App.tsx最终Sprite、POLISH_CSS、字体、UI或Golden；网页截图对照仍欠Phase2验收。
本批许可证检查范围严格为六个音频Dart包和两个构建源指纹，不是完整发行法律审查。
已核对Media3 1.4.1根许可及精确提交，尚未逐一覆盖其全部Maven传递NOTICE；
Settings中的用户可见许可证页面、最终候选批准与生产接线仍未完成。
manifest明确保留三个false状态，生产仍为UnavailableAudioEngine，不把通过的工具校验当成播放界面可用。

为了给下一批界定范围，额外只读运行了Gradle离线依赖报告。单独`:just_audio:dependencies`失败于
`'other' has different root`；没有修改系统/构建配置去掩盖，改用已成功构建的应用级
`:app:dependencies --configuration debugRuntimeClasspath --offline --console=plain --quiet`成功。
实际结果包含Media3 1.4.1、Guava 33.0.0-android、failureaccess 1.0.2、
listenablefuture 9999.0-empty-to-avoid-conflict-with-guava、jsr305 3.0.2、checker-qual 3.41.0，
error_prone_annotations在应用依赖冲突解析后为2.41.0。
这是待审清单的来源事实，不把插件请求版本当成最终包内版本，也不声称这些材料已经完整打包。
六个JAR按LICENSE/NOTICE/COPYING文件名只读检查，checker-qual含1126字节`META-INF/LICENSE.txt`，
其余五个未自带同名材料；这不表示它们没有许可证，下一批还须从对应版本的上游/父POM补全来源。

本批计划范围已完成：六包许可原件/实际打包校验、负向测试与最终修正的双平台构建均通过。
下一批先补原生传递许可覆盖/展示方案，再将已通过双平台POC的候选接入共用播放生命周期；
不以同一套Phase4L计时数字冒充新版本原生运行，不跳过Phase4进入Phase5。
