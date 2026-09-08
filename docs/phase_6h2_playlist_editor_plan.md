# Phase 6H2 — 原生歌单编辑界面计划

2026-09-08，仓库 `Z-YO-YI/YYMusic`，分支 `codex/playlist-editor-surfaces`，
基于 fetch/pull 后的 `1dd92eff6db50aa3ee6fd6e14f95321114c77746`。
前置 push 33994757759 / PR 33994765770 的 checks、Android、Windows 全部 success；
Draft PR #46 保持 OPEN。五份指纹及 ZIP 24 项逐字节一致。

按主指令 Phase 6 的 Playlists 顺序，仅完成创建、重命名、删除确认的三端原生入口，
不同时生成歌单详情、条目排序/添加、播放全部、导入、设置或上线功能。

- 先记录 ADR-058，再将根 PlaylistController 接入 AppRouter 的 Shell 外层编辑宿主。
  草稿/焦点由位于 AdaptiveRoot 上方的宿主管理，尺寸改变不销毁草稿；不新增数据库或列表缓存。
- Library 的歌单分类提供创建按钮、自定义歌单改名/删除按钮，系统歌单不提供编辑入口。
  成功结果由已有 Library 仓库订阅刷新；错误保留草稿并显示固定安全文案。
- Phone 使用 YYBottomSheet，Tablet/Windows 使用 YYDialog；复用原有 modal tokens 和 SVG。
  原生通用文本输入采用基础 HTML 的 field 样式，共享既有剪切/复制/粘贴选择控件，
  不把搜索框伪装为名称输入，不引入 Material 或 WebView。
- 保存中禁止重复提交；关闭/离页不撤回根已接受写入。删除需用户点击明确确认，
  告知仅删除歌单及条目，不删除歌曲或来源内容。测试只删除隔离测试库中的歌单。
- 覆盖空白/超长/控制字符、IME、错误重试、系统保护、后台更新、Back/Esc、焦点、
  600 断点/横竖屏、130% 文字、SafeArea/键盘和已接受写入的关闭排空。
- 新增三端原生 Golden 并逐张检查；既有 70 张应保持不变。
  全量 format/analyze/Flutter/Node、指纹/许可、Android 预检；审查后提交推送 stacked Draft PR，
  在 GitHub 构建 Android 与 Windows。不合并、不发布、不将产物或敏感信息提交仓库。

App.tsx NEW_ICON_SPRITE/POLISH_CSS 与基础 HTML 都作为参考，网页对照仍受既有安全限制，
不能用原生 Golden 或 Debug 构建成功代替网页视觉对照、实机音乐体验或发行验收。
