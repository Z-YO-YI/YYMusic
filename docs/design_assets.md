# Android Phase 2A 资产接入

## 图标与设计来源

原始设计仍为 ZIP 中完整 App.tsx + 基础 HTML 的合成结果；五份指纹、24个 ZIP entry、52项确定性审计产物没有改动。`docs/icon_manifest.md` 是 Phase 0 自动生成的历史清单，不手改它的阶段叙述掩盖生成差异；当前接入状态记录于本文。

`YYGlyph` 与 `assets/icons/yymusic` 的44个文件一一对应。`YYIcon` 只使用 `SvgPicture.asset`，保留原始路径、24×24 viewBox、1.72 stroke、局部 fill/stroke=none；仅通过 ColorFilter 着色，未重绘或引入另一套图标。语义图标可带中文标签，按钮内装饰图标排除重复语义；Windows Tooltip 属于后续桌面控件阶段。

本批按 Figma 设计转代码技能要求优先复用原始资产，但用户给的是本地导出而非可读取的 Figma URL/node。未虚构节点、未调用 Figma 写入、未声称取得远端截图；视觉依据与无法进行网页截图的限制分开记录。

## 字体与许可

原导出声明 Inter / Noto Sans SC，本批直接打包 Google Fonts 仓库固定提交中的原文件，没有重新子集化/改名字体内部元数据或安装系统字体。

- 上游提交：`ade3d1533e06b2b1462ffcde8e08b129627ca360`。
- [Inter 源目录](https://github.com/google/fonts/tree/ade3d1533e06b2b1462ffcde8e08b129627ca360/ofl/inter)：`Inter[opsz,wght].ttf` → InterVariable.ttf，876,576字节；随附 OFL 原文，Copyright 2020 The Inter Project Authors。
- [Noto Sans SC 源目录](https://github.com/google/fonts/tree/ade3d1533e06b2b1462ffcde8e08b129627ca360/ofl/notosanssc)：`NotoSansSC[wght].ttf` → NotoSansSCVariable.ttf，17,772,300字节；随附 OFL 原文，Copyright 2014–2021 Adobe，保留 Reserved Font Name 声明。
- 两份 SIL Open Font License 1.1 均完整保留并声明为应用 asset；字体内部名称不改。源提交、路径、大小与 SHA-256 全量见 [manifest](../assets/fonts/manifest.json)，自动测试校验。

Latin 优先 Inter，中文回退 Noto Sans SC，最后保留 Segoe 回退；应用不依赖设备有这两款字体，不进行运行时字体网络请求。使用 Flutter [fontVariations](https://api.flutter.dev/flutter/painting/TextStyle/fontVariations.html) 保存720/740等非整百字重，保留POLISH中的 OpenType features。网页远程字体版本未被原ZIP锁定，因此不能声称所选字体二进制与当时Figma网页完全相同。

两款字体约18.65MB原始大小，本批不提前优化子集，避免丢中文字形；可在后续发行体积阶段评审子集与许可。Debug APK大小不是Release体积承诺。

Git属性将TTF、原始OFL和PNG Golden设为不转换换行；仅OFL原始文本免除行尾空格检查，不清理上游字节、不放宽源码空格规范。自动测试检查生效属性，避免跨平台checkout破坏哈希或PNG。

## 包边界

pubspec只允许44SVG目录、两字体及两份OFL进入包；参考HTML/ZIP、旧原型、manifest审计文件和本地安装记录不打包。本批 APK 中实查44 SVG、2字体、2 OFL，未发现reference/legacy档案。字体字节测试、原始源审计与真实SVG解码测试分别覆盖来源、稳定性和可用性。
