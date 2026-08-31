# PR 草稿：记录本机工具链补齐与 Android 构建验证

Base：feat/phase-1-flutter-foundation。Head：chore/local-toolchain-setup。

## 变更与影响范围

- 复用现有 Flutter3.47.2 / Dart3.13.2、Android Studio 和 JDK25.0.2；仅补 Android Command-line Tools22.0、API36、NDK28.2.13676358。
- 配置用户级路径并保留本地恢复备份，统一 ADB 来源但不删除旧文件。
- 更新 README、CHANGELOG、工具链记录和 Phase1 状态；无业务代码、依赖、设计输入或发行签名变更。
- 安装包、环境备份、机器路径和 APK 留在 Git 忽略目录，不纳入提交。

## 测试与构建

- Dart format：26 文件、0 变动；flutter analyze：No issues found。
- Flutter 单元/Widget：24/24；Node 审计/归档/架构：15/15；ZIP entry：24/24。
- Android Debug 构建通过，APK 签名校验通过；详细大小与 SHA-256 见 toolchain_setup.md。
- Windows C++ 安装等待用户 UAC 确认，未重跑 Windows 构建，Phase1 出口仍未全部满足。

## 注意事项

仍有部分 Android SDK 许可未接受提示；首次构建有 JDK native-access / SDK XML 兼容警告，未掩盖警告。没有设备运行/视觉/真实音频验证。GitHub 连接器访问仓库返回404，不能核验远程CI；本文件只是草稿，不代表 PR 已创建。
