# Phase 1 开始：原生工程骨架

日期：2026-08-31。用户明确要求继续开发，本轮推进 Phase 1，不进入 Phase 2 设计系统或 Phase 3–4 业务/音频实现。

## 目标与来源

继承已推送的 Phase 0 指纹、源审计和 ADR；再次读取主指令 Phase 1、布局分类、Shell 与推荐目录。核验当前 SDK 和维护者依赖资料。目标为一个 Windows + Android Flutter 工程、严格分析、路由、根依赖图、空业务合同/Controller、三个空 Shell 和基础 CI。

远程已 fetch/pull --ff-only，基线 94247bd；独立分支 feat/phase-1-flutter-foundation。

## 文件与安全迁移

- 先将 13 个原型文件原样归档到 archive/sonic_gallery，保存移动前指纹并单独提交，保留可恢复历史；不删除或格式化旧代码。
- 新增正式 lib/app、lib/shells、lib/platform/contracts、lib/playback、lib/domain/repositories、lib/shared、test/unit、test/widget；不批量创建未来业务页面。
- 使用已安装 Flutter 稳定 SDK 生成 android/windows runner（不引入 Web）。更新根 pubspec、严格 analysis_options、.gitignore、README、架构/依赖/状态/测试文档。
- 新增 GitHub Actions 的审计、分析/测试、Windows Debug、Android Debug 检查。正式客户端不读取归档或设计参考。

## 风险

- Flutter 3.47.2 / Dart 3.13.2 已找到，但不在 PATH；本轮使用绝对路径，不静默修改用户环境。
- flutter doctor 确认 Windows 缺 Visual Studio，Android 缺 cmdline-tools 且 license 状态未知。本机安装需用户授权；不得自动接受许可。优先用现有 SDK 完成分析/测试，并由 CI 验证可构建性。
- 本轮 Shell 是结构验证界面，明确标示“Phase 1 工程骨架”，不是 Figma 视觉验收；不得假装已经完成播放器、曲库或歌词业务。
- 根依赖图独立于 Shell 生命周期；窗口缩放、路由切换不创建重复 Controller。测试验证实例身份、路由及 ViewState 保留。
- 包名/应用 ID 暂用 io.github.z_y_o_y_i.yymusic，为开发标识，发行前另行确认；不使用 com.example 或付费服务。

## 出口条件

工程 format/analyze/test 通过；Windows Debug 与 Android Debug 有真实构建证据（本机或 CI）；Windows 1440/1024 和 Android 600/横竖屏边界正确；三个 Shell 没有重复业务逻辑；根 DI 和独立 /player、/lyrics 返回语义有测试；CI 与文档同步。

若构建因工具链/网络/权限未通过，保留并推送已验证成果，报告 Phase 1 出口未满足，不进入 Phase 2。
