# Phase 4M — 音频候选许可基础与打包校验

2026-09-05。开始前已 fetch/pull，基于与远端同步的 `17b10db3c21ce9345becaf42c28f23333b7b6bc3`，
新分支 `codex/audio-license-foundation`，不修改 main/master。

## 本阶段目标

- 把 Phase4E 的六项音频 Dart 包许可快照升级为可执行的源码/Android APK/Windows bundle 校验。
- 复用 Flutter 3.47.2 已生成的 `NOTICES.Z`；核对包名与完整原文 SHA-256，不只查找 MIT/Apache 字样，
  不再复制一套许可证文本，避免版本更新后原文漂移。
- 记录当前原生候选能力与下一批正式接线条件；区分技术选型、包内许可材料和完整发行审核。

## 已读取的来源

总指令 Phase0/4/11、执行格式和代码规则；完整 HTML/App.tsx 合成审计、原 ZIP24/24；
Phase4E/F/J/K/L 计划与报告、依赖决策、当前 just_audio 适配器、Bootstrap/Graph、CI/打包检查。
本机精确 Pub 包 LICENSE、Android Gradle/POM、Flutter ServicesBinding/LicenseCollector 源码，
Phase4L Windows 包中四个许可组实际覆盖六个包且原文哈希一致。
官方 pub.dev 精确版本页与 AndroidX Media 1.4.1 源码作为来源核验，不执行网页示例代码。

## 准备新增的文件

- `docs/legal/just_audio/manifest.json`：精确版本、长度、完整原文指纹、原生来源和验收边界。
- `tools/audio_license_audit.ps1`：有界 GZip/UTF-8 与完整许可组核验。
- `tools/verify_audio_licenses.ps1`：源码、Android APK、Windows bundle 的只读入口。
- `tools/audio_license_audit.test.mjs`：实际 PowerShell 正向/负向、缺失/重复/篡改/坏压缩/体积门禁。
- 本批完成报告。

## 准备修改的文件

Android/Windows 打包验证脚本与 CI 的源码检查步骤；相应结构测试；README、依赖/架构决策、
实施状态和测试矩阵。原有48项设计资产、禁用候选排除、测试与构建门禁全部保留。

## 风险与出口

只核验 Flutter 音频包的原文不能冒充所有 Maven/系统组件的完整发行法律审查。
Windows WinRT 由系统提供；Android Media3 根许可、AAR/POM 与传递 NOTICE 需明确说明覆盖范围。
任何缺失或指纹漂移真实失败，不删条目或放宽比较让 CI 通过。

本批不改生产音频入口、业务页面、权限、Schema、依赖版本、Header/代理/TLS 或下载能力。
出口：新增负向测试、完整本地回归、源文件/生成代码核对、Android Debug 真实包与当前 Windows
Profile 包许可复核，以及新实现提交的 GitHub 双平台 Debug。提交并推送，报告最新 CI 的实际状态。
