# Phase 7C2 开始 — 独立原生歌词页面

2026-09-09；Z-YO-YI/YYMusic；`codex/native-lyrics-route`；fetch/pull 后干净基线 `aad2d06`。
前置 C1 源码与 PR 双平台已成功，Push 双平台收尾继续核对；本批若发现前置失败先修复，不借用前置结果宣称新提交通过。

## 目标与来源

替换正式 `/lyrics` 占位页，Phone / Tablet / Windows 三套布局复用既有根 LyricsController、LyricsViewport 和受控 YYLyricsPlayerDock。
接入同步/纯文本/双语翻译显示、读取/无歌词/无曲目/错误重试、真实播放与进度、独立返回关系；不嵌入 Player Tab、不造歌词或第二时钟。
已读主指令19/Phase7、既有完整 App.tsx 审计及本批复验的 NEW_ICON_SPRITE/POLISH_CSS、HTML 原歌词结构与动作。使用 figma-design-to-code，仅有本地导出，不伪造在线 node；复用原始字体/SVG/控件。5指纹/44图标/52产物复验通过。

## 文件与架构决策

先写 ADR-078。新增 lyrics_screen 与 phone/tablet/windows 布局；在 AppRouter/YYMusicApp 注入唯一根歌词控制器和只读路由活动信号。
页面借用控制器、只拥有翻译显示/进度草稿/代次。活动激活在安全后帧合并，退出移除监听并停止歌词读取授权，不停止播放器。LyricsController.seekLine 新增可选页面意图检查，防止布局/路由改变后排队 Seek 仍执行。
底栏接真实歌词入口：已有桌面按钮在有曲目时启用；手机和桌面窄栏元数据长按直达，并提供原生长按语义；播放页显式歌词按钮、Windows L（文本输入除外）。
独立路由标记可恢复的页面名称并去重；歌词返回播放页优先复用已有播放路由，否则替换歌词路由，避免循环叠栈；普通关闭仍返回来源页面。
Dock 仅启用已实现控制，隐藏本批未接的收藏，布局控制不依赖新的平台插件。

## 验证与边界

覆盖三端130%字号/短横屏/窄窗、真实根快照/翻译/播放/拖动、返回来源/直接路由/重复点击、晚到读取/排队Seek/失活/最小化/卸载、键盘不误播与安全错误重试。
添加独立页面 Golden，精确更新受入口启用影响的旧基线并逐张核对；完整格式/分析/Flutter/Node/生成/迁移/原始指纹/许可/Android预检和新SHA GitHub 双平台。
本批背景是明确深色兜底，不声称真实封面提色；OS全屏/F、Android系统沉浸、收藏/独立队列管理和LRC导入解析留后续增量。
更新README/状态/矩阵/报告和前置云端证据，扫描敏感信息、提交/push、Draft PR base=`codex/lyrics-follow-viewport`；不合并、发布、改历史或提交安装包。
