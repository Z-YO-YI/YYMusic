# Phase 6H14 开始 — 系统歌单收藏与历史管理

2026-09-09（本机时区），Z-YO-YI/YYMusic，`codex/system-playlist-management`。
基于fetch/pull后的干净`891a9f1fdf0da3dd8d2ba8920658452fe9931593`，PR #58两组常规源码/Android/Windows全部成功。

## 本阶段目标

- 喜欢列表的更多/长按/右键菜单支持取消喜欢，包含失效或未解析的完整来源引用，不删曲库、歌曲文件、队列或自定义歌单。
- 最近页提供原生确认清除，明确只清除历史；走H13根历史串行通道，取消不写、确认后不停止音频。
- 受控弹层保留原生焦点/Tab/Esc/返回、Phone BottomSheet/Tablet与Windows Dialog；旧快照、覆盖路由、零尺寸和离页不得授权新动作。
- 根级SystemPlaylistWriter保存已接受写入与安全失败，页面关闭不丢失操作结果；返回系统页可查看，根关闭等写入结束。

## 已读取来源

主指令23/Phase6–11、基础HTML收藏/历史动作及完整App.tsx最终Sprite/POLISH_CSS；复验5指纹/44图标/52产物/ZIP24项。
H13计划/实施状态、系统会话/页面、已有歌单菜单、YYContextMenu/YYDialog/YYBottomSheet、真实Repository与测试夹具。
使用figma-design-to-code技能复用精确图标/Token/组件；没有在线节点，不虚构Figma API或网页像素对照。

## 文件与合同

新增根写入器、系统管理弹层与针对性测试；修改SystemPlaylistSessions/Controller/Actions/Sections/Screen、README/状态/矩阵/报告。
共享API先记ADR-070。保留现有只读SQL投影，不新增Schema、依赖、权限或第二播放器/历史数据库。

## 风险与出口

旧菜单误删、新确认覆盖、来源身份丢失、取消误写、重复提交、键盘事件穿透、写入/关闭重入、离页丢失失败与清除后旧记录复活。
出口：三端菜单/确认/键鼠、根生命周期、真实SQLite/数据保留、Golden逐张检查、全量格式/分析/Flutter/Node/指纹/生成/许可、Android预检及精确GitHub双平台。
不新增系统歌单重命名/删除、队列编辑或批量播放、导入/在线配置/Release；后续继续Phase6剩余页面及Phase7–11。
