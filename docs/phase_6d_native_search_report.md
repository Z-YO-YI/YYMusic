# Phase 6D — 原生搜索界面与根作用域接线

## 交付范围

`codex/native-search-surfaces` 基于已拉取的 Phase 6C `b5d960f`；
仓库 `Z-YO-YI/YYMusic`。保持独立分支和 stacked Draft PR，不直接修改或合并 main。
本批完成 Search 的已保存目录路径，不代表完成整个 Phase 6 或上线。

- DatabaseAppDataServices 提供同一 Library 实例的 CatalogSearchRepository 视图，
  并拥有 DriftSearchHistoryRepository；无 schema、依赖、平台权限变化。
- DependencyGraph 唯一拥有 CatalogSearchController，路由切换/断点变化不重建业务状态。
  UI 只持有编辑器/焦点/滚动控制器；搜索关闭取消定时器、监听和旧意图，排空在途操作后
  才关闭数据作用域。单独注入的搜索/历史合同借用，不由控制器 dispose。
- 原生手机/平板/Windows 独立组合、六种筛选、最近搜索/确认清除、来源名称、
  曲目播放与只读专辑/艺术家结果；列表 SliverList.builder 惰性构建。
- 六个独立区域 = 三类实体 × 本地/已入库 REST 引用。每页 20 条、完整身份去重、
  按原始页行数推进 offset，每区最多读取 200 条并提示缩小范围；失败重试保留旧页。
  本地结果不受在线区域失败影响；这是持久目录查询，不是实时联网搜索。
- 输入法合成期间不查询/提交，完成后 300ms 防抖；任何新输入/筛选使旧 token 失效。
  不在每次按键时写历史，仅显式搜索按钮、Enter 或历史选择记录；历史写入/读取/清除串行，
  防止待完成的 record 在 clear 后复活历史。错误使用固定文字，不输出原始异常或私密配置。
- Enter 按当前可见顺序优先选择首个可用本地曲目，无需等待慢在线区域或专辑/艺术家。
  搜索按钮仅查询；专辑/艺术家筛选不播放隐藏曲目。Windows Ctrl+K 返回输入位置并聚焦，
  输入框 Space 不切换播放。离开 retained branch 也会撤销待执行播放意图。
- PlaybackController 新增原子 playCatalogTrack 命令：复用完整 TrackRef 对应条目或追加，
  不替换队列。执行前及异步读取/解析/加载边界检查意图，已撤销的加载停止而不开始播放。
  已经完成的队列追加不会因撤销输入而回滚，不擅自删除用户队列内容。

## 设计依据与截图

继续使用完整 App.tsx 的 NEW_ICON_SPRITE 和 POLISH_CSS，而非只读基础 HTML。
YYSearchField 延续最终 15px / 460 字重、手机 52px / 其他 58px 高度及 18/20 圆角；
YYSearchChip 复用原生控制交互与至少 44dp 命中区域，保留 pill、13px 横向内边距、11px / 620。
空搜索面板保留 320px 最小高度与 24px 圆角，当前使用普通边线而非网页虚线；不声称像素一致。
专辑/艺术家详情未接入，因此结果为只读实体行，不制造假的详情按钮。封面仍用明确占位。

新增六张 Windows 宿主 Golden，均按 130% 文字和项目字体逐张查看：手机初始/结果、
平板竖屏深色/横屏专辑、Windows 宽屏深色/窄屏在线错误。未改既有 49 张基线。
截图只代表原生回归；Phase 2 的 HTML 网页对照仍受原有浏览器安全限制，未绕过。

## 验证

- 407/407 Flutter 测试通过，包括 55 张 Golden；新增 16 项控制器/根播放器/真实 SQLite
  接线测试、6 项 Widget 交互测试、6 张 Golden。首次新测试的缺失路径不符合 Track 合同，
  已修正测试数据；未放宽领域校验。
- 69/69 Node 门禁通过，新增两项搜索架构门禁；既有 Home 关闭顺序断言纳入 Search 排空。
- 严格 analyze 0 问题，230 文件格式检查零修改；生成代码、Drift schema/helper 与 lockfile
  稳定性门禁无差异。无生产 fixture、WebView、下载、网络请求、新引擎或未经批准的权限。
- ZIP 24 项逐字节一致；六包音频 LICENSE / 两个原生构建来源和原生完整许可源码校验通过。

2026-09-06 最终本地 Android Debug 构建成功（Gradle 16.4 秒），231,678,735 字节，
SHA-256 `a831de7beb0828fee834e93416455507c625016befd1d517b6c8658e1036cea9`。
48 项设计资产、六包 NOTICES.Z 和原生完整许可匹配；v2 签名有效、一个签名者。
Java 原生访问警告保留，没有影响检查退出状态。本机包仅为诊断，用户 APK 仍在 GitHub 构建。
本次精确提交的 GitHub Android/Windows 结果在对应 Draft PR 的验证记录补记；
不把 Phase 6C 的成功算作 Phase 6D 成功。APK/日志/临时数据库/密钥不提交仓库。

## 剩余边界

默认新安装仍是实际空库，没有音乐导入和来源配置 UI；在线筛选只能查已入库引用。
实时 REST、多来源适配、封面、专辑/艺术家详情、音乐库与后续业务页、完整播放器和发布
仍按主指令后续阶段实施。SQLite 子串搜索不是 FTS/拼音检索；合成测试不替代大曲库实机性能。
本轮 Fake 音频调用与截图不算新一次 Android/Windows 真机音频验收，Windows 本机
C++ / Debug CRT 限制仍存在，构建由 GitHub 单独核验。下一增量从 Phase 6 音乐库入口继续。
