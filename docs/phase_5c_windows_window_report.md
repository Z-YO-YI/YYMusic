# Phase 5C 增量 — Windows 根窗口控制报告

2026-09-05，`codex/windows-window-gateway`，基于 fetch/pull 后的 `a39d306`，Draft PR #34。
前置详情面板的 push33961718376/PR33961733794 两组 checks/Android/Windows 均成功。
本批增量编号不等于主指令所有 Phase5 子阶段已验收；业务页面仍在分阶段开发。

## 实现

新增 WindowGateway、Windows 专属 MethodChannel 和 WindowPresenter。仅对当前 Runner HWND
移除 WS_CAPTION，保留原生调整尺寸边框；操作结果从 IsZoomed/IsIconic/实际窗口样式读取。
原生成功握手后才启用42dp原稿标题栏；缺失通道保持系统标题栏，错误使用固定可重试提示。
根窗口生命周期独立于业务 Graph：WM_CLOSE/Alt+F4 或关闭按钮先等待同一 Graph.close，
按既有顺序完成播放器/媒体/数据释放，再 completeClose；重复关闭不重复释放。

根标题栏在所有路由可达。正文先绘制、标题栏后绘制但仍位于顶部，避免 Navigator 的模态
语义屏障吞掉窗口按钮；独立 Semantics 和 Overlay 使辅助工具和悬停提示正常工作。
提示位于按钮下方并向内对齐，不越过右侧边界。拖动和双击只命中标题非按钮区。
Android 不构造 Windows Gateway；UI 无 Win32/IO，平台消息拒绝任何 HWND/任意参数。
不增加依赖、权限、UAC、系统设置、Schema、媒体下载或业务演示曲目。

## 验证

- 严格 analyze0；全量 Flutter327/327，包含43张Windows宿主Golden；Node61/61。
- 新增5项Presenter与4项通道合同、8项根Widget、2张130%窗口图（1440浅色首页、840深色许可页）。
  旧41张基线不变，全量非更新比较通过；两张新增图逐张检查。
- 根Widget覆盖跨路由按钮、原生状态投影、最小化/双击/拖动按钮排除、宽窄/零尺寸恢复、
  Android隔离、重复关闭/引擎释放、固定错误重试及提示框范围。
- 初轮通道延迟Mock返回值与真实区消息Future导致测试失败；Mock显式await，Widget宿主显式
  MissingPlugin模型（单元通道测试可覆盖、integration_test不加载），不在生产代码偷换Fake。
  首轮根布局还暴露模态语义屏障，已用实际辅助节点查找与根绘制顺序修复，未改为绕过语义点击。
- 194个Dart文件格式检查；build_runner83项内部缓存输出，跟踪的生成代码/Drift v1/lockfile零差异。
  ZIP24/24及六包LICENSE源码指纹保持一致。App.tsx NEW_ICON_SPRITE/POLISH_CSS与原HTML未修改。
- Android默认Debug成功20.0秒，231,561,256字节；48项设计资产、六包Dart许可、原生许可完整匹配，
  APK v2有效且一个Debug签名者。SHA256为
  `e32d3fff129665e59cedddda397a400d3bff0c7308ccef519c59b60b5e72984b`；
  Java原生访问警告保留，未改工具链压制。

Windows CI新增真实窗口集成入口：实际frame、最大化/还原、最小化/还原、状态事件、拒绝任意参数、
系统关闭拦截后窗口仍存活、detach恢复系统caption。测试不最终销毁进程，完整进程退出需设备验收。
先运行集成测试，再重建正式默认入口并验证/上传既有Debug包；不会把测试入口当作可用应用分发。
本机没有Windows C++/Debug运行环境；实现提交`db7998e2d067385b13950398192f1c0f50c8560e`
已由GitHub push33964141676、PR33964171290验证，两组checks/Android/Windows全部success。
两个Windows job真实窗口状态/事件/关闭拦截/detach/拒绝任意参数均通过，再重建默认Debug入口。
六份job日志已核对：源码六包许可、Windows65文件包/六包及原生许可、Android51坐标/三份法律原文/
48设计资产均通过。Draft PR #35保持未合并，两个音频POC按设计skipped，不计新音频设备证据。

剩余：真实鼠标/触摸系统移动、多显示器/DPI、位置记忆、无边框全屏及最终退出设备验收；
Phase2仍欠网页截图对照。没有新Release、正式签名、合并或商店上线；完整曲库/导入/REST、
收藏、完整播放/歌词/队列/Artwork与Phase6—11仍待开发。
