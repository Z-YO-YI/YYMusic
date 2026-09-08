# Phase 6H7 — 新建歌单并添加当前歌曲计划

2026-09-08，`codex/playlist-create-and-add`，从fetch/pull后的
`b2845a3b23852deb01f41538f4d79cc18a7a2076`开始，PR #51 OPEN Draft且两组标准三job成功。
五份指纹与ZIP24项再次验证，App.tsx最终SVG/POLISH_CSS及基础HTML新建歌单入口为离线设计依据。

1. 先记录ADR-063；新增createPlaylistWithEntry原子合同，共用既有新建父身份/名称保护，
   同一SQLite事务插入自定义歌单与position=0的完整TrackRef条目；失败整体回滚，ID碰撞不覆盖或重试。
2. 根PlaylistController生成一次父ID、entry ID和同一UTC时间，借用原有busy/安全错误/排空机制。
   选择会话通过createAndAdd调用单个根命令，复用添加的已接受写入登记和离页失败反馈，不串联两个独立命令。
3. 现有Phone底部面板和Tablet/Windows对话框增加原生“新歌单名称 / 新建并添加”。
   使用独立名称草稿，不把筛选词自动当成名称；复用YYTextField、YYButton、原始plus SVG及现有Token。
   名称可原生选择/编辑/IME；禁用非法、组合中、busy和过期按钮回调；草稿与状态跨旋转/零尺寸保持。
4. 已有歌单读取失败不假装成功，但不禁止独立的原子创建尝试；成功只确认真实提交结果。
   操作不复制媒体、不解析音频，不改变现有播放；关闭不会取消已接受事务，失败通过根级脱敏提示保留。
5. 真SQLite/Fake合同、碰撞/系统保护、事务故障回滚、watch不暴露半成品、并发、根关闭和三端界面回归。
   逐张检查受影响Golden；严格格式/分析/完整Flutter与Node、Drift/指纹/许可、Android预检，
   审查提交推送stacked Draft PR（base=codex/playlist-add-picker），核验精确GitHub Android/Windows构建。

本批不包含播放全部/随机、系统歌单、大歌单完整浏览、导入、在线来源、Schema/依赖或平台发布。
不自动合并或创建Release。技能在线get_design_context因离线ZIP无fileKey/nodeId不适用，
执行其原始资产和组件复用要求，不虚构Figma读取或绕过既有网页对照限制。
