# Phase 1 工具链状态

更新：2026-08-31。用户先要求检查已有环境，再明确批准仅补齐缺失组件并配置现有路径。保留原 Flutter、Android Studio、JDK、ADB 和已安装的 Android API 37，没有重装整个环境。

## 本机盘点与本轮操作

| 组件 | 检查时 | 本轮结果 |
| --- | --- | --- |
| Flutter / Dart | 3.47.2 stable / 3.13.2 已安装，未加入 PATH | 复用原 SDK；补充用户 PATH，doctor 已识别 |
| Android Studio / JDK | 2026.1 / 内置 JDK 25.0.2 已安装 | 复用原安装，Flutter 显式关联 Studio、JDK 和 SDK |
| Android Build Tools / Platform Tools | 36.0.0 / 37.0.1 已安装 | 保持不变 |
| Android API 37 | 已安装 | 保留；不擅自升级项目 compileSdk |
| Android API 36 | 未安装 | 官方 SDK Manager 安装 Platform 36 revision 2 |
| Android NDK | 未安装 | 安装项目要求的 28.2.13676358 / r28c |
| Android Command-line Tools | 未安装 | 官方 ZIP 校验后安装 22.0 到 cmdline-tools/latest |
| 两套 ADB | 用户 PATH 指向独立副本，SDK 另有一套 | PATH 改用 SDK 自带版本；原副本不删除，冲突警告消除 |
| Windows C++ | 无 Visual Studio C++ / Windows SDK / CMake | 微软签名引导程序已请求提权，等待用户批准 UAC；尚未安装完成 |

doctor 显示的“Android SDK version 36.0.0”不能证明 Platform 36 已安装。安装前实际只有 Platform 37；本轮以各包 source.properties 和 SDK Manager 记录分别核验。

## 安装包身份与范围

- Android：Google 官方 commandlinetools-win-15859902_latest.zip，SHA-256 `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`，与官方下载页一致。解压前校验全部路径，拒绝越界及覆盖既有目录。
- Windows：微软官方 https://aka.ms/vs/17/release/vs_buildtools.exe，本次下载 SHA-256 `2aeac090a9cfb2c56474aa9a6c5817ad8cfb879539e0ed1aecec33de9fc2dc4f`；执行前 Authenticode 为 Valid、发布者 Microsoft Corporation。滚动链接未来的哈希可能变化，不能跳过签名验证。
- Windows 仅请求 Microsoft.VisualStudio.Workload.VCTools，以及 Microsoft.VisualStudio.Component.VC.Tools.x86.x64、Microsoft.VisualStudio.Component.VC.CMake.Project、Microsoft.VisualStudio.Component.Windows11SDK.26100。目标 D:\BuildTools\2022，共享组件可能位于 C 盘。不安装完整 IDE、可选工作负载，不自动重启。
- Android 只安装 `platforms;android-36` 和 `ndk;28.2.13676358`。未批量升级 SDK、另装 JDK、下载模拟器镜像或创建虚拟设备。

## 环境变量与恢复

只修改当前用户 PATH、JAVA_HOME、ANDROID_HOME，并设置 Flutter 的 android-sdk、android-studio-dir、jdk-dir。保留其余 PATH 条目，不修改系统级环境变量。已有编辑器/终端需重新打开；本轮验证命令显式刷新其进程环境。

安装包、执行脚本、原用户环境变量及 Flutter 设置备份只存 docs/local_validation/toolchain_install/（Git 已忽略）。其中包含机器本地路径，不提交 GitHub。恢复时依据最早的 environment-before 备份恢复相应用户变量及 Flutter 设置，不覆盖之后无关的新配置；原有 ADB 文件仍保留。

没有自动接受全部 Android 许可证。所需 Platform 36/NDK 使用已有许可记录安装成功，但 doctor 仍报告部分 SDK 许可未接受；不能声称所有环境检查全绿，也不以安装成功冒充构建成功。

## 验证状态

| 检查 | 本轮结果 |
| --- | --- |
| Flutter PATH / JDK / ADB | 已识别正确路径，重复 ADB 警告消除 |
| Android API 36 / NDK | 安装命令退出码 0；版本文件核验一致 |
| Dart format | 26 个文件，0 项格式变动 |
| Flutter analyze | 通过，No issues found |
| Flutter 单元 / Widget 测试 | 24/24 通过 |
| 设计 / 归档 / 架构 Node 测试 | 15/15 通过；5 份输入指纹及 52 项派生产物一致 |
| ZIP entry | 24/24 字节一致 |
| Android Debug | 通过：flutter build apk --debug --no-pub，313.4 秒，退出码 0 |
| Windows Debug | 未重新构建；工具链安装等待系统管理员确认 |
| 远程 PR / CI | 连接器查询仓库仍返回 404，未创建 PR，未核验 CI |

Phase 1 双平台构建出口仍未满足，不进入 Phase 2。该文件随实际构建结果更新，不把分析/测试通过等同于原生构建通过。

APK 位于 build/app/outputs/flutter-apk/app-debug.apk，162016280 字节，本次 SHA-256 `4a80123c061ab020b8fbe92845b78c3fd40a0a5cd96de8194eeb9aca60298565`。apksigner verify 通过（v2，1 个 signer），aapt2 确认包名 io.github.z_y_o_y_i.yymusic、版本 0.1.0、compile/target SDK36、三种 ABI。这是 Debug 产物，不是 Release；没有安装到设备或发布，也不提交 GitHub。

首次构建下载项目锁定的 Gradle9.3.1 与 Maven 依赖；出现 JDK25 native-access 和 SDK XML v3/v4 兼容警告，但本次构建成功。没有为消除警告而升级/降级项目依赖或关闭安全检查。doctor 的部分 Android 许可提示仍保留，Windows 工具链仍未就绪；两者需单独处理。

Git push 与 GitHub API 权限独立：继续使用标准 Git 同步，不读取本机 Git 密码/Token 绕过连接器 404。提交与远程一致性在本轮交付时通过 Git 核验。

## 复核命令

重新打开终端后执行以下命令；若旧编辑器尚未继承 PATH，可使用已安装 SDK 的绝对路径。

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

项目仍使用 compile/target SDK36、minSDK24、NDK28.2.13676358、AGP9.1.0 / Kotlin2.4.0 / Gradle9.3.1 / JVM17 字节码目标。JDK25 在 Gradle9.3.1 支持的运行版本范围内，JVM17 编译目标不意味着必须额外安装 JDK17。最终兼容性以实际构建为准，当前不构建 Release、不配置发行签名。

官方来源：[Android 下载与校验值](https://developer.android.com/studio#command-line-tools-only)、[SDK Manager](https://developer.android.com/tools/sdkmanager)、[Flutter Windows 设置](https://docs.flutter.dev/platform-integration/windows/setup)、[微软安装参数](https://learn.microsoft.com/zh-cn/visualstudio/install/use-command-line-parameters-to-install-visual-studio)、[C++ Build Tools 组件](https://learn.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools)、[Gradle Java 兼容性](https://docs.gradle.org/current/userguide/compatibility.html)。
