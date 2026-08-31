# Phase 1 工具链前置条件

2026-08-31 实测：已安装 Flutter 3.47.2 stable / Dart 3.13.2，但未加入 PATH。本轮通过 SDK 绝对路径完成命令调用，不静默修改系统 PATH。Windows 11 主机可执行 Flutter 分析和 Widget 测试，不等于具备 Windows 本地编译器。

## 当前阻塞

| 目标 | 实测状态 | 下一步 |
| --- | --- | --- |
| Windows Debug | flutter build windows 明确失败：找不到合适的 Visual Studio toolchain | 用户批准后安装 Visual Studio 的 Desktop development with C++ 工作负载，再跑 doctor/build |
| Android Debug | doctor 检测到 SDK36.0.0，但缺 cmdline-tools，license 状态未知；未运行完整构建 | 用户自行审阅/接受适用许可，补足 SDK/命令行工具/NDK，再 doctor/build |
| GitHub PR/CI 可见性 | Git push 可用；GitHub 连接器查询仓库404 | 授予连接器本仓库权限，或由用户创建 PR /查看 CI |

手动读取本机 Git 凭据再构造 API 请求的提案被安全审查拒绝，未执行、未提取凭据，也未通过其他方式绕过。继续使用标准 git push，不把推送成功等同于 API/连接器权限。

当前不会自动安装多 GB 系统组件、修改系统 PATH、自动接受 Android 许可、配置发行签名或付费云服务。SDK 缓存/项目依赖正常解析已执行。

## 复核命令

SDK 未在 PATH 时，将下面 flutter/dart 换为实际 SDK bin 中对应命令的绝对路径。

```powershell
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos
flutter test --no-pub --coverage
flutter build windows --debug --no-pub
flutter build apk --debug --no-pub
```

Android 模板保留所选 Flutter SDK 的 compile/target SDK36、minSDK24、NDK28.2.13676358，AGP9.1.0 / Kotlin2.4.0 / Gradle9.3.1 / JVM17；来自本机 SDK 生成配置，不是跨版本通用建议。发行前重新审核兼容与签名，当前不构建 Release。

官方来源：[Windows 工具链](https://docs.flutter.dev/platform-integration/windows/setup)、[Android 设置](https://docs.flutter.dev/platform-integration/android/setup)。版本和组件后续升级应独立提交，不更改设计输入指纹。
