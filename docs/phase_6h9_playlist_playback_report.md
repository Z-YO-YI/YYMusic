# Phase 6H9 — 歌单播放全部／随机播放报告

2026-09-08，`Z-YO-YI/YYMusic`，分支`codex/playlist-play-all`，
基于pull后干净的`33187c0491a6e6850f5a5bc6986df61f24e0c075`，未在main/master开发。
复核五份源指纹/ZIP24项及完整App.tsx/HTML审计产物，重读主指令相关要求后先写计划与ADR-065。

## 实现与影响范围

- 新增`PlaylistPlaybackPlan`和Repository只读接口：单个绑定SQL投影整份歌单的条目ID/位置/完整TrackRef/可用性。
  不分页拼接、不N+1、不展开艺人、不读取路径/URL/Metadata；重复引用保留，缺失/空/系统视图区分。
- 根`playCatalogSelection`冻结输入、生成不冲突的队列ID、预校验随机顺序，再在一个串行操作中提交队列和模式。
  顺序播放从首项开始，随机播放首项也随机；原歌单顺序不改。已有根队列保存仍为原子事务，没有第二套播放器/存储。
  保存失败保留旧队列和模式、不开始新音频，但旧音频可能已为安全切换停止，不承诺恢复旧音频。
- 自定义歌单Phone/Tablet/Windows增加原生YYButton及原始play/shuffle SVG，明确说明替换当前队列。
  跳过计划读取时已标记不可用或缺失的引用并提示数量；全部不可用不改队列，原歌单和曲库均保留。
  保留busy、当前快照、菜单/路由和代次校验；已接受工作由根排空，已开始持久化不做补偿回滚。
- 测试暴露并修复`WindowFrame`零尺寸卸载Navigator：保留上次有效布局，Offstage/ExcludeFocus/TickerMode
  隐藏页面、隔离焦点、暂停计时；恢复后还是同一会话，未开始的延迟播放被撤销，已开始音频不因离页停止。
- 按figma-design-to-code沿用现有组件和审计资产，未用WebView/默认Material控件/新图标/生产Fixture。
  离线包无在线Figma节点；Golden只证明Flutter回归，不虚构网页像素对照或实机听感验证。

## 验证

- 全量Flutter **812/812通过**（52秒），新增38项：2模型、6真实SQLite、8根播放、13会话、8原生UI、1真实SQLite页面。
  SQLite1003个重复条目只一次绑定SQL/1003行，不读无关损坏Metadata；完整来源身份、可用性、坏位置、系统拒绝均验证。
  真实UI从20条显示窗口播放并持久化205条队列，原205歌单条目和曲库记录不变。
  根关闭等待实际SQLite读取和引擎load；随机首项/遍历、保存失败、延迟持久化/加载撤销、双击、旧回调等覆盖。
- **98/98 Node通过**，新增两项完整计划/根命令门禁；严格分析零问题，335个Dart文件format零修改。
  build_runner与make-migrations后Schema、生成代码、迁移测试和pubspec.lock零差异。
- 84张Windows宿主Golden全部通过：逐张检查并更新8张歌单基线，其他76张不改、比较阈值不改。
  新按钮130%文字下在Phone/Tablet/Windows均可见且不溢出；原窗口Golden不变。
- 五份源指纹、44图标/52确定产物、ZIP24项逐字节、六包LICENSE/原生法律材料全部通过。
- Android本地Debug预检成功（Gradle32.3秒），231,911,226字节，SHA256
  `bbc04582daf9e068b256efd633afd8adcf7a6b1236f621a515a5f9c9b14107b6`；48份打包资产、NOTICES.Z、
  原生材料及v2单Debug签名通过。JDK native-access警告未隐藏，APK/日志只在忽略的build目录，不入Git。

开发中测试接线曾因扩展缺少导入、RepeatMode名称、夹具重复upsert、损坏行注入方式和窗口状态丢失失败；
分别修正测试夹具并实际修复窗口保留问题后全量重跑通过，未删用例/关闭Lint/放宽Schema或Golden门槛。

## GitHub与后续边界

前置H8精确提交的push34222808426/PR34222814936双组三项常规job均成功，PR #53仍Draft/OPEN，证据已回填。
本批推送后创建以`codex/playlist-window-navigation`为base的stacked Draft PR；精确head的云端构建/附件元数据由该PR回填。
不以前置成功冒充本批CI，不合并、不force、不新建Release；源码测试文档/审查过的基线之外不提交秘密、用户库或构建包。
提交前26份变更文本的常见秘密模式扫描零命中，git diff --check通过；预期仅34份源码/测试/文档/已审查基线。

Phase6仍有系统歌单、Local Music/Settings；之后Phase7完整播放器/歌词/队列、Phase8真实导入/权限、
Phase9在线来源、Phase10–11平台媒体/QA/发行。读取后才出现的来源/文件错误仍用现有安全错误态，完整运行时跳过另行实现。
尚无实机大库Profile/网页像素对照；默认新安装为空库，Windows Debug依赖调试运行库，不是普通安装程序或日常听歌成品。

## 精确云端结果回填（Phase6H10开始时核验）

实现`243299c755f9e0c11b6fd15a073eba1aae11faa6`，Draft [PR #54](https://github.com/Z-YO-YI/YYMusic/pull/54) OPEN，未合并。
[push 34228349118](https://github.com/Z-YO-YI/YYMusic/actions/runs/34228349118)和
[PR 34228368456](https://github.com/Z-YO-YI/YYMusic/actions/runs/34228368456)精确head相同，两组三项常规源码/Android/Windows均success，
两项专用音频job按条件skipped而非通过。Linux728通过/84Golden跳过，Windows84Golden与1真实窗口测试通过、默认Debug重建成功。
65文件Windows包/六包许可/完整原生材料，以及Android51坐标/3全文法律材料/48资产/v2单签名门禁通过。
push唯一附件ID`10057182055`，名称`YYMusic-windows-debug-243299c755f9e0c11b6fd15a073eba1aae11faa6`，67,338,002字节，
digest `sha256:2948d23d360003ef2de709a204f7a83d0689d90a864faf300e26e13022206b1e`，过期时间`2026-09-22T13:02:46Z`。
仅核验API元数据与日志，未下载/执行该附件；PR附件为0，创建APK Release步骤明确skipped。
