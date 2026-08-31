# Changelog

## 2026-08-31 — Phase 1 工程骨架（构建出口待验证）

- 将旧 Sonic Gallery 的 13 个文件原样归档并单独提交，增加指纹测试。
- 使用 Flutter 3.47.2 创建 Android/Windows 原生 runner，品牌改为 YYMusic，不使用 WebView。
- 增加平台优先分类、三个空 Shell、根依赖注入、播放生命周期边界和独立 player/lyrics 路由。
- 增加分类、状态/滚动保留、路由返回、无障碍和 CI 配置测试，启用严格静态分析。
- CI 配置源码审计、分析/测试、Windows/Android Debug 构建；Action 固定 SHA、仅 contents:read。
- 本机 Windows 构建缺 Visual Studio；Android 工具/许可待确认，双平台出口未完成，不进入 Phase 2。

## 2026-08-31 — Phase 0 设计审计

- 校验 ZIP、App.tsx、基础 HTML、package.json 指纹，并锁定主指令文档本次 SHA-256。
- 归档完整导出包，复现 Sprite → 账户替换 → Polish 注入的最终参考合成。
- 提取 44 个 SVG、全部 81 个 CSS 规则块 / 203 个声明，生成可复核清单及映射。
- 记录四个页面、七个 Overlay、交互与模拟行为、状态、持久化、16 个媒体查询及层叠冲突。
- 建立 Token、三套 Shell 边界、视觉验收计划、依赖候选证据和双平台音频 POC 计划。
- 提供零外部依赖的生成/检查工具和测试；未进入 Flutter 骨架、页面实现或音频 POC。
- 保留原有 Sonic Gallery 源码与测试不变；未将它们自动纳入新 Git 基线。
