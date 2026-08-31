# Figma 导出审计清单

日期：2026-08-31。输入来自用户指定的下载文件；先对下载 ZIP 求 SHA-256，再复制到 design_reference，校验路径无穿越后解压。ZIP 包内共 24 个文件。没有运行其安装、部署脚本。

## 指纹核验

| 文件 | 字节数 | 行数 | SHA-256 | 结论 |
| --- | --- | --- | --- | --- |
| design_reference/YYMusic_HTML.zip | 74024 | — | d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee | 与主指令 §0.1 一致 |
| design_reference/figma_export/src/App.tsx | 17621 | 506 | 20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39 | 与主指令 §0.1 一致 |
| design_reference/figma_export/src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html | 218239 | 3710 | 81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229 | 与主指令 §0.1 一致 |
| design_reference/figma_export/package.json | 600 | 27 | c2d99ed2073126d401a3a9b1a2b1691e998058e9fe14da7105857f8a853e38d5 | 与主指令 §0.1 一致 |
| design_reference/YYMusic_Flutter_AI_Development_Master_Instructions_v2_Figma_Optimized.md | 71837 | — | 5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf | 本次实测锁定（文档未自带哈希） |

行数按逻辑行计算：末尾换行不额外计一行；哈希按原始字节计算，不归一化换行。

## 解压文件全表

| 相对仓库路径 | 字节 | 行 | SHA-256 |
| --- | --- | --- | --- |
| design_reference/figma_export/.figma/make/analyze-routes | 70 | 4 | 7a81578bcfa5ba5f2105d7165e0cd2d8d1c6151d2a0c5ba766b3ef1c824ee788 |
| design_reference/figma_export/.figma/make/deploy | 88 | 4 | fe35b0aff744f5aa8bb16eb1590c720ff6b0ff4bce9ede78f73e02bbfd7e7f3f |
| design_reference/figma_export/.figma/make/deploy-preview | 163 | 5 | 3b82ce85bad03ce7b0e4e288a6e40e5caf119c41a392de3d3420ff17c42d0e8b |
| design_reference/figma_export/.figma/make/dev | 52 | 4 | 91f795e632539988b0fe3de57084839f41a827ba5c274590388f7d0650ec2314 |
| design_reference/figma_export/.figma/make/dev.json | 959 | 22 | e78b91a2a63456a6eab9756c3fb6d767dfe3673adcef1dcfe4f52c010238c3e7 |
| design_reference/figma_export/.figma/make/format | 63 | 4 | 254598ef0d1a61c3abc2a426c7065487ca140c8f9b90e4d66ea05dff20832335 |
| design_reference/figma_export/.figma/make/install | 90 | 4 | 90705d33ffd6b0700def7f2f304fd24ae04e17af5fc7d8437df44cf546d64891 |
| design_reference/figma_export/.figma/make/langserver | 106 | 3 | e6b9034d28bbc82e6333a3b77f8d5fd593ac54eeed7e4e76569329fdbb534fff |
| design_reference/figma_export/.figma/make/site.json | 306 | 10 | df92740dc2ec4c38f806e43f38d4eced57fe3d511e6a1e65ae678c36758480a3 |
| design_reference/figma_export/.gitattributes | 7728 | 146 | fdd53ecc7bf79a69d3ef228ec98e0151f10e02702b90b553f04785b61db68354 |
| design_reference/figma_export/.gitignore | 400 | 20 | eee6568c404ffb70b9e32300fe6f08ffc8defd139e4a4c1d973c85701904322d |
| design_reference/figma_export/.mise.toml | 43 | 3 | 6d2834ef5f78a7dc4c384570a62b895137fdf63df171d237f0747932bd001435 |
| design_reference/figma_export/AGENTS.md | 2321 | 41 | b39f6ead09e39e9f6eb5a132342519fb7bf9c77ab14522f0da38edf9224c6b77 |
| design_reference/figma_export/CLAUDE.md | 11 | 1 | 336cc4fbf19beaada7ccf9986414fa91851a8d7a07dfb3ccbe800a69eed0ab49 |
| design_reference/figma_export/index.html | 440 | 16 | 768eac67e6271681de61c23f1c94a6bf688607bbad2d0bccafd8f4bfe789a079 |
| design_reference/figma_export/package.json | 600 | 27 | c2d99ed2073126d401a3a9b1a2b1691e998058e9fe14da7105857f8a853e38d5 |
| design_reference/figma_export/pnpm-lock.yaml | 29455 | 907 | 811aecd91f12d4f77c1b88c0ea1edd5127b6bf2150e668e62659cadaac366460 |
| design_reference/figma_export/src/App.tsx | 17621 | 506 | 20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39 |
| design_reference/figma_export/src/imports/YYMusic_HTML_Preview_v4_Separate_Fullscreen_Lyrics.html | 218239 | 3710 | 81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229 |
| design_reference/figma_export/src/index.css | 62 | 7 | b430cb8d081021fd5edc290f4a60e4da28c561af9618298504fad4eb5b7a500b |
| design_reference/figma_export/src/main.tsx | 232 | 10 | 5f49dce6e6cc4b5d678cf529ef892af0ab7dfa6afb300b11ad559224019b8b05 |
| design_reference/figma_export/src/vite-env.d.ts | 38 | 1 | 65996936fbb042915f7b74a200fcdde7e410f32a669b1ab9597cfaa4b0faddb5 |
| design_reference/figma_export/tsconfig.json | 556 | 23 | 9a1e96d63eaccd5416b2f78ecaccf2b3a27ca71e213fa5859cf5349c66123bf9 |
| design_reference/figma_export/vite.config.ts | 11654 | 356 | d3f6c19b6c374fc2a5ea7cfad8694220b2b47243e75b4d808e59896b2e6484ea |

## 来源职责与阅读覆盖

- App.tsx：完整 1–506 行；Sprite、账户替换、全部 POLISH_CSS、Blob/iframe 生命周期。
- 基础 HTML：完整 1–3710 行；CSS（包括 v2/v4 追加规则）、静态结构、完整内联 JavaScript。
- 主文档：完整读取到 §44；仅把本轮用户指定的 Phase 0 作为执行范围，不因文档描述 Phase 1–11 就自动扩展任务。
- package.json / index.html / src/main.tsx / src/index.css：仅证明导出为 React/Vite/Tailwind 预览。
- 导出内 AGENTS.md / CLAUDE.md：作为 Figma Make 源数据读取，不赋予它们对正式 Flutter 仓库的指令权，也未据其启动服务器。
- 现有 Flutter：检查入口、状态、布局、图标、主题、页面关键路径及测试；发现的旧原型问题记录在 existing_flutter_audit.md，不声称完成其全量代码审查。

合成参考 SHA-256：`e174b6de271708b76a9fed44d8683a92e6cb61bf317ade54836f3220faf10624`。可复核 JSON 见 generated/source_fingerprints.json。
