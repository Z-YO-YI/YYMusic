# Phase 2A 开始 — Android 设计基础

2026-08-31。用户明确要求“先开发安卓平台”。基线为已同步的 chore/local-toolchain-setup@261e628，开发分支 feat/android-design-foundation。

## 本阶段目标

- Android 优先推进；保留 Windows runner 和共享架构，但 Windows 安装/原生验收暂缓，不宣称双平台 Phase 1 已全部完成。
- 本批实现语义 Token、Light/Dark/System、五种预设/自定义 Accent、会话级外观状态、原始 44 SVG 和打包字体。
- 实现 YYButton、YYIconButton、YYSurface、YYGlassSurface、YYProfileHeader 和可操作的 Android 组件 Gallery；从现有 Android 骨架进入，不提前实现曲库、来源、真实播放或完整业务页面。

## 已读取来源

- Phase 0 已完整审计的 HTML；本轮复核基础 CSS 与完整 App.tsx 的 NEW_ICON_SPRITE / POLISH_CSS，5份指纹和24个ZIP entry不变。
- 主指令第2/3/14/15/16/31/34/36/38/39节；design_tokens、icon_manifest、visual_parity_plan、现有 app/shell/tests 和 ADR。
- flutter_svg 维护者资料、Google Fonts 原始字体及 OFL、Flutter 字体 API。Figma 技能的节点读取步骤不适用当前本地导出来源，不虚构节点，不自行重画 SVG。

## 修改与新增范围

- 新增 lib/design_system、lib/features/design_gallery 及对应单元、Widget、Golden/资产完整性测试。
- 修改 app 根外观注入、Android gallery入口、pubspec/lock、CI测试步骤、README/CHANGELOG/实施状态与依赖/资产文档。
- 在 assets/fonts 打包固定提交的 Inter / Noto Sans SC 和许可证；既有44个SVG字节不改动。

## 风险与边界

- Android 构建已通过，但没有连接设备/模拟器；本轮不安装系统组件，不重启 Windows 安装程序。
- 外观状态先由唯一根 Controller 持有；持久化属于后续数据阶段，不声称重启保存。
- 网页参考截图曾被安全策略阻止；不绕过限制。Flutter Golden只证明本批自身回归，不证明已与网页像素一致。
- 字体增加 APK 体积；仅打包应用字体，不安装系统字体、不在运行时请求字体服务。
- Windows 验收和 Phase2 后续组件（导航/Slider/Artwork/业务卡片等）保持待办。本次不把 Gallery 包装成完整音乐客户端。

## 本批出口

全部SVG可渲染，字体与许可证有固定来源/哈希；颜色对比、主题切换、Reduced Motion/Glass、触控/键盘/Disabled/Loading有测试；Android手机/平板尺寸与130%文字不溢出；format/analyze/tests/APK构建通过；提交并推送GitHub。视觉对照缺口和Windows待验收单独报告。
