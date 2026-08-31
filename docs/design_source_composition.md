# 最终设计参考如何合成

本轮范围是 Phase 0。附件描述后续阶段不等于用户授权本轮批量生成应用；导出工程内 AGENTS/CLAUDE 仅是被审计资料，不是 Flutter 项目指令。

## 输入与输出

| 输入 | SHA-256 |
| --- | --- |
| 基础 HTML（3710 行，218239 字节） | `81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229` |
| App.tsx（506 行，17621 字节） | `20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39` |

执行 `node tools/design_audit.mjs --write`，然后 `node tools/design_audit.mjs --check`。无需安装 React/Vite，也不执行源文件中的 JavaScript。输入不匹配时立即失败，不修改锁定指纹掩盖差异。

严格复现 App.tsx 476–490 行的顺序：

1. 找到基础 HTML 中唯一的 `<svg aria-hidden="true" height="0"`，到紧随其后的 `</svg>` 为止，整体换为 `NEW_ICON_SPRITE`。
2. 只替换一次 `<div class="brand-name">YYMusic</div>` 为 `<div class="brand-name">YY Listener</div>`。
3. 只替换一次 `<div class="brand-subtitle">YOUR MUSIC, YOUR WAY</div>` 为 `<div class="brand-subtitle">本地账户</div>`。
4. 在唯一的 `</head>` 前插入 `<style>${POLISH_CSS}</style>` 和换行。
5. 写出 `design_reference/generated/YYMusic_Figma_Composed_Reference.html`，不增加 React、iframe 或 Blob 包装。

原 App 使用 useEffect → Blob URL → iframe，卸载时 revoke URL；这里只复现字符串合成，不迁移该客户端架构。基础 HTML 内的浏览器功能脚本被原样保留在开发参考中，因此打开它仍有演示交互；该脚本没有被移植到 Flutter，也没有接入 Release 资产声明。

## 44 个最终图标 ID

```text
i-home i-search i-library i-settings i-moon i-sun
i-play i-pause i-prev i-next i-shuffle i-repeat i-volume
i-queue i-more i-heart i-folder i-cloud i-plus
i-chevron-right i-chevron-down i-x i-minimize i-maximize
i-music i-palette i-key i-info i-check i-playlist i-history
i-timer i-device i-trash i-list-plus i-up i-down i-refresh
i-speaker i-drag i-wave i-fullscreen i-fullscreen-exit i-lyrics
```

每个路径从 App.tsx 逐字提取，资产名和源行号见 [icon_manifest.md](icon_manifest.md)。默认继承 `fill="none" stroke="currentColor" stroke-width="1.72"`、round cap/join；播放、暂停、前后曲、更多，以及混合型图标内部 Filled 属性保留。不能从基础 HTML 的旧 sprite 提取，不能用 Material Icons 替换。

## POLISH_CSS 全部规则

完整原文：[polish.css](../design_reference/generated/polish.css)。完整逐规则/逐属性映射：[polish_rule_mapping.md](generated/polish_rule_mapping.md)。共 **81 个规则块、203 个声明**，没有省略伪元素、Hover、Dark、浏览器滑条差异或 7 组封面几何。

映射覆盖：OpenType、44px 账户头像双 Ring、账户字重/字距、隐藏重复账户区、导航 14 圆角与 3×18 指示条、1.72 stroke、全部标题、Hero/唱片与环纹、floating note、按钮/图标按钮、专辑/歌曲/队列/播放器封面、两类浏览器 slider、主播放控制、surface、glass、Sidebar/Inspector、来源/弹层/菜单/设置/歌单、Badge/Metric/Folder/DropZone/Search、歌词/Dock、Orbit/Tide/Noon/Mono/Signal/Quiet/Local 纯色封面。

## 不能把“最后注入”误解为“所有规则强制覆盖”

以下是源码层叠推导，**不是浏览器 computed-style 测量**。Browser 对 file: URL 的安全策略阻止了本轮预览，未绕过。

| 场景 | 合成网页实际规则 | Flutter 决策 / 验证点 |
| --- | --- | --- |
| 账户头像阴影 | App 的 `!important` box-shadow 是 2px/3.5px 双 Ring，覆盖旧单层投影 | 双 Ring 为精确来源；主文档描述的轻阴影单独列为待 Golden 校准，不伪称 CSS 已叠加 |
| 手机 Sidebar / nav | 同 specificity 的后置 `.sidebar` 24、`.nav-item` 14 覆盖旧手机 32/22，竖指示条也无移动端取消规则 | 保留参考事实；正式 Phone 按主指令使用 32 胶囊和适合底部的选中背景，不复制左竖条 |
| 手机 Hero | 后置 `.hero` 28 和 `.hero h2` -2.1 覆盖手机 22 / -1.2 | 以合成样式为基础，字体缩放/窄宽时校准 |
| 普通 dialog | 后置 30 覆盖基础手机 0 | 正式全屏路由不能机械继承圆角；普通弹层使用 30 |
| immersive player | `#nowOverlay.player-immersive ...` 的 ID 优先于后置类；dialog 仍 0，封面仍 clamp(22,2.6vw,36)、专用阴影 | 建立 fullscreen 语义 variant；不宣称所有封面都是 26 |
| immersive slider | 高 specificity：track 5、thumb 15；后置 .range 3/14 不覆盖这些尺寸 | 主文档目标 3/14 与参考存在差异，Phase 2 按硬性目标做显式差异记录 |
| lyrics slider | `#lyricsOverlay .range...` 仍 track 4、thumb 12、白色、专用阴影 | 同上，独立记录而不改写原参考 |
| Firefox progress | 普通 `::-moz-range-progress` 仍 4，POLISH 只覆盖 track/thumb | Flutter 不复制跨浏览器不一致 |
| 玻璃 | `.glass` 为 blur42/saturate1.3；ContextMenu、lyrics Dock/button 没有 .glass，保留 30/1.18、30/1.12、24/1.12 | 按作用域校准；禁止把全页当作42模糊 |
| 主 transport 同时 Hover/Pressed | POLISH hover scale1.04 `!important` 可压过基础 active scale.96 | 原生状态优先级 Pressed > Hover，列入交互 Golden |
| 歌词 Dock | 后置26覆盖手机21、低高横屏19，但不改变两层重排 | radius与布局分开映射 |

## Fixture 与正式数据的隔离

产品名始终 **YYMusic**，窗口、安装包和 About 不改名。`YY Listener`、头像 `YY`、`本地账户` 是账户 Fixture。

示例歌曲/专辑/艺人、7 种几何封面、6 组歌词及生成的兜底歌词、预设队列和歌单、128首/18专辑、D:\Music、固定日期问候、示例域名、模拟连接延迟、蓝牙耳机、默认播放74秒都不是用户真实数据。`example-token` 是明确占位文本，不是真实凭据；表单保存根本没有读取凭据、Headers、Endpoint 和映射字段。

生产版初始曲库为空；数据进入 Repository 后才展示。Fixture 只允许测试/开发注入；真实封面优先，没有封面才用纯色几何占位。禁止把 `.example` 示例源连通状态、假播放计时器、假输出切换当成功反馈。下载/离线保存/批量抓取不在实现范围。
