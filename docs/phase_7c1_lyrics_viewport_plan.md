# Phase 7C1 开始 — 原生歌词正文与跟随视口

2026-09-09；Z-YO-YI/YYMusic；`codex/lyrics-follow-viewport`，基线 `af1b07b`。开始前 fetch/pull，干净工作区；7B1 两组源码与 Android 成功，Push Windows 已成功，PR Windows 最终结果继续核对。

## 目标与来源

先把独立歌词页的正文滚动做成可验证组件，再由后续批次接路由、顶部和播放 Dock；本批不宣称正式 `/lyrics` 已替换占位页。
消费已有不可变 LyricsDocument、根同步行号/播放位置与快照令牌，不创建播放器、仓储或媒体时钟。复用 YYLyricsLine，支持双语受控显示、实际时序状态和 Seek 回调。
已核对主指令 19/Phase7、最终 App.tsx 的歌词字体/圆点/POLISH_CSS、基础 HTML 的滚动/点击行为；原始指纹5、SVG44、产物52通过。使用 figma-design-to-code，本地导出回退、现有组件复用，无在线节点，不伪造设计工具调用。

## 设计与文件

先记录 ADR-077。新增 `features/lyrics/common/lyrics_viewport.dart`，扩展已有歌词行的显式手机/桌面排版与减少动态行为。
双向惰性 Sliver 以当前行为锚点，可以直接定位一万行中的任意行，不预创建所有歌词，也不靠估算平均行高扫描。仅当前可见及缓存范围行进入 Widget 树。
手动滚动暂停自动跟随，滚动停止五秒后恢复；明确“回到当前歌词”可立即恢复。自动定位不请求键盘或辅助功能焦点，不把滚动计时器当媒体时钟。
快照/文档改变、隐藏、零面积和卸载撤销定时/后帧动作与旧 Seek；布局/字体/翻译变化重新测量定位。纯文本不 Seek、不自动跟随。

## 验证与边界

补齐短/长/双语/偏移/区间间隙、10,000 行按需渲染、首尾与远跳居中、原生触摸/滚轮、五秒恢复、旧回调/隐藏/旋转、键盘与减少动态 Widget 回归及新 Golden。
格式/严格分析/全 Flutter/Node/源码指纹/许可/生成与迁移、Android 预检，精确 GitHub 双平台独立核对；逐张检查受影响 Golden，不笼统重录。
更新报告、README、状态、矩阵；扫描敏感信息、提交/push，Draft PR base=`codex/native-player-route`。不合并、不发布、不改依赖/Schema/平台，不填充生产歌词样本。
