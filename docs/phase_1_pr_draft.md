# PR 草稿：Phase 1 原生 Flutter 工程骨架

Base：docs/phase-0-design-audit。Head：feat/phase-1-flutter-foundation。建议保持Draft，双平台构建证据齐全后再Review；这不是已创建PR的声明。

## 变更

- 原样归档13个旧原型文件并保留指纹，建立新的YYMusic根工程。
- Android/Windows runner；平台优先分类、三个空Shell、根依赖生命周期和独立player/lyrics路由。
- 严格分析、单元/Widget/完整性测试及固定SHA、最小权限CI。

## 测试

详见[Phase 1报告](phase_1_report.md)。源审计与新骨架自动化测试执行结果分别记录；Windows本机构建因缺Visual Studio失败，Android构建未运行，远程CI尚未核验。不能在此情况下标记“全部通过”。

## 影响范围和注意事项

替换正式根工程入口和组织方式，原型移至archive可恢复；输入设计指纹不变。无WebView、真实音频、线上源请求、数据库或发行签名。默认音频不可用，所有Fake仅在test。界面是阶段骨架，不接受Figma像素验收；所有后续阶段保持未开始。
