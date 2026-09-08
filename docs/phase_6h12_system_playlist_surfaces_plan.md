# Phase 6H12 — 系统歌单原生入口与单项播放计划

2026-09-08，Z-YO-YI/YYMusic，codex/system-playlist-surfaces；fetch/pull后从干净428a49f0049d51039da012639a07801e9880d025开始。
前置Draft PR #56两组源码/Android/Windows成功。五份指纹、ZIP24项、44图标/52产物复验；完整复读App.tsx全部Sprite/POLISH_CSS/账户替换，
复查基础HTML的libraryPlaylists、renderPlaylists/systemPlaylistTracks/openPlaylistCollection及主指令17.4/23/Phase6。
使用figma-design-to-code技能的原生组件/Token/导出图标复用原则；输入只有本地Figma Make包、没有在线节点，按已审计导出源继续，不虚构节点或get_design_context结果。

目标：音乐库歌单分类中的三个真实原生入口、固定枚举路由、三套独立布局、加载/空/错误/分组、精确单项根播放。
先记录ADR-068，再改AppNavigation/Router/YYMusicApp/DependencyGraph和系统会话动作；新增路由解析、系统页面/Sections/三布局/测试/Golden。
音乐库复用YYPlaylistCard与最终heart/history/queue资产，不伪造未读取的计数，不创建可删除系统父歌单。

- 路由仅接受闭合SystemPlaylistType，拒绝重复/额外参数和无效身份；与自定义歌单ID独立，返回恢复前页。
- Phone单列、Tablet横屏主从/竖屏列表、Windows独立桌面内容；复用YYToken、Surface、TrackTile，不复制业务或音频。
- 复用H11窗口会话与scroll状态，旋转/分屏/零尺寸/覆盖路由不重建根播放器；旧回调和未完成播放在离页时撤销。
- 收藏/最近通过根playCatalogTrack保留现有队列；队列通过真实entry ID播放，验证完整TrackRef，不将重复曲目归并到第一项。
  已开始音频不因正常离页停止；队列当前ID自身写入触发刷新不得撤销其自身合法播放，外部过期身份不得误播。
- 明确不可用/缺失引用保留、系统歌单不可删除；本批不新增收藏取消/清历史/队列排序写菜单、整体系统歌单播放或真实播放历史记录。
  这些已有/后续根动作独立验收，不以静态提示冒充已经实现。
- 测试路由、精确重复队列项、取消/错误/关闭排空、三端操作/键鼠/返回、分页/刷新/跨断点、真实SQLite全根路径。
  新Golden和必要受影响旧Golden逐张检查，未受影响基线保持字节不变；网页截图对照仍单独记录缺口。

风险：队列自刷新误取消、旧条目/路由回调误播、缺失引用消失、屏幕切换丢会话、菜单键盘泄漏、布局与130%字缩溢出。
出口：完整格式/分析/Flutter/Node/指纹/生成与许可/Android预检、精确GitHub双平台成功；清晰提交推送stacked Draft PR，不合并/Release。
之后继续真正开始播放的历史记录与系统动作，再收尾Local Music/Settings，按Phase7–11推进，不宣称本批已经日常可用或上线。
