# Phase 4N — Android 原生音频传递许可材料

2026-09-05。已 fetch/pull，基于 `6cd370b`；独立分支
`codex/native-audio-notices`，不直接修改 main/master。

## 目标与来源

延续 Phase4M 六个 Dart 包原文校验，补全实际 Android 应用解析的 Media3
传递依赖材料。已重读总指令、Phase4L/M 报告、依赖决策、生产入口和音频适配器；
ZIP/App.tsx/HTML/主指令 SHA-256 与既有审计一致。视觉仍以最终 Sprite、账户替换和
POLISH_CSS 合成为准。本批不改 UI。

只读 Gradle 解析发现音频闭包包含 51 个坐标，不能仅列 Media3/Guava 六个显眼依赖。
使用应用解析后的精确版本，保留 POM、归档内原文与上游许可来源，补充缺失原文，
生成应用可携带的第三方许可数据及包内核验；不把包名/许可缩写当作完整原文。

## 文件与风险

新增 `tools/audio_dependencies.init.gradle`、原生许可生成/校验工具与测试、
`assets/legal/android_audio/` 数据、对应机器清单与阶段报告。
修改 pubspec 资产声明、CI、资产校验接入口、ADR/README/测试矩阵。
不新增运行时依赖、媒体、下载、Header 代理、数据库迁移或系统权限。

风险：Gradle 平台/BOM 节点可能没有二进制；POM 许可可能继承父 POM；AAR 的
classes.jar 还可能有独立 NOTICE。必须保留并验证，不静默跳过；许可资料范围是当前
音频依赖闭包，不冒充整个应用或商店发行审核。生产接线是后续独立批次。

## 出口条件

精确依赖闭包与材料可复现；原文完整、指纹可复核；新增负向测试及既有测试通过；
Android/Windows 实际包均包含新增材料；格式、分析、双平台构建通过；提交、推送、
维护 PR 并如实报告精确提交 CI。失败时先修复，不进入下一阶段。
