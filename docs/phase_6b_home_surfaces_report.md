# Phase 6B — 原生首页接线报告

2026-09-05，分支`codex/home-surfaces`，fetch/pull后基于`b2e561d`（Draft PR #36），不在main开发。
本批是主指令Phase6的Home增量，不代表Phase6所有页面、主指令全部Phase5出口或整款应用完成。

## 输入与实现

- ZIP SHA256：`d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee`。
  主指令：`5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf`。
  原归档24文件逐字节一致。读取基础HTML首页及完整App.tsx合成规则；没有改原始参考或绕过安全拒绝。
- Phone单列、Tablet竖屏栅格/横屏主从、Windows宽Hero/内容双栏独立组合原生Flutter组件。
  使用新版SVG与POLISH_CSS的Hero28圆角/双阴影/标题字距；不使用WebView、默认Material页面或渐变。
- 根HomeController读取正式Repository：最近7天最多20条、历史前20条按完整TrackRef去重解析、
  来源卡最多20项。精选最多6首，优先可用历史，否则过滤普通曲库首20项中的本地曲目。
  后者只是有界首批候选，不保证覆盖全库所有本地歌曲，不宣称推荐算法已完成。
- 每区独立Loading/Empty/Error与重试。目录显式刷新，历史/来源流更新；来源错误不遮挡本地内容。
  来源只显示公开名称/类型/保存的状态，不显示端点、路径、凭据引用或Header，不执行连接测试。
- 首页/底栏/Inspector共用根播放器。完整TrackRef复用已有队列条目，否则追加后播放；不覆盖用户队列，
  不可用曲目禁用。清除历史有取消/确认两步，只清历史Repository，不删除音乐或队列。
- 控制器跨路由和断点复用，保存首页滚动；查询/事件版本拦截晚到结果，操作错误为固定脱敏文字。
  关闭先禁用通知与新操作，再等待取消订阅和在途读取/命令，底层存储最后释放（ADR-049）。

## 本地验证

- 211文件格式零改动，严格analyze无问题；最终完整Flutter **359/359**，其中49张Windows宿主Golden。
- 新增8项Controller、1项真实内存SQLite/正式DatabaseAppDataServices、5项Widget和6张Golden。
  覆盖七天范围/20条限额、完整来源身份、乱序/错误后晚到事件、分区恢复、根关闭等待、
  队列保留/重复点击/不可用曲目、清历史确认/取消、实际数据库历史清空且歌曲/队列保留、
  三套布局/130%字号/断点切换、Loading和刷新后真实空态。
- 使用FakeAudioEngine的用例明确断言play与根状态；测试路径为隔离合成绝对路径。
  首轮相对Fixture路径被解析器拒绝，已修复夹具并加强实际play断言，没有放宽生产来源校验。
- 新6张Golden和受首页替换影响的旧9张均逐张查看，其余旧34张不变；非更新全量比较通过。
  初轮Ahem默认测试字体造成账户标题溢出，加载实际打包字体后恢复；未隐藏溢出或缩小生产字号。
  旧ShellPlayer测试限定自身子树，避免新增首页同名标题/重试按钮误匹配，动作和状态断言保留。
- Node **65/65**，包含新增的独立布局、唯一根所有权、关闭顺序和安全字段边界断言。
  build_runner/Drift再生成成功，数据库生成物、v1/v2快照、测试助手及lockfile零差异。
- 原ZIP24/24、六包LICENSE/两构建来源、完整原生音频材料源码校验通过。

Android默认入口Debug构建成功（Gradle38.6秒），**231,625,180字节**，SHA256：
`80f6e0bbc2554587e4e0b41df99ac8583d3e84a2147a2881eb9b2f10046feba6`。
48项设计资产、六包NOTICES.Z、原生全文许可匹配；参考/秘密文件与已拒media_kit原生内容均未打包。
APK签名验证通过、v2有效、一个签名者；仍为开发Debug包，未配置正式发行签名。
Java原生访问与SDK XML版本警告原样保留；没有改系统工具链压制警告。

## GitHub与交付边界

本批提交后推送并创建以`codex/home-recent-catalog`为base的堆叠Draft PR；精确提交的云端
checks/Android/Windows状态在PR中补验。提交前没有把待运行CI称为通过。本地APK仅作诊断，
用户要求的APK交付仍必须来自GitHub构建；源码不提交APK、运行日志、秘密或不必要产物。

Windows本机C++/Debug CRT/插件symlink限制未解除；Golden是Windows宿主Widget渲染，
不是Windows安装/真实窗口原生运行或新一轮扬声器播放。后者单独以云端/原生证据报告。
前置Phase6A两次双端CI及真实窗口确认已补入其报告，不能冒充本次提交的新证据。

没有合并、Release或上线。封面为占位，圆盘为原生简化适配；Phase2网页截图/像素对照仍缺。
搜索、音乐库和设置主体仍是骨架（许可页可用），来源管理入口只进入设置并明确开发中；
导入/REST未完成，默认新安装保持真实空库，没有虚构可播放曲目。下一步按Phase6顺序做搜索，
再逐批完成音乐库/专辑/艺术家/曲目/歌单/本地音乐/设置，以及后续播放器、导入、平台集成和发布验收。

## 精确提交云端确认（2026-09-05续验）

`62b8a7cbc75032a6e17baaa2b28fd4e0f45197b0`的push33976793559、PR33976796108均success，
各自checks、Android Debug、Windows Debug成功，手动音频POC明确skipped。完成日志独立确认：
ZIP24/24、六包许可、51个原生坐标/三份全文、Android48资产、Windows65文件、两端包内许可全部通过。
两次真实窗口测试customFrame/maximized/restored/minimized/stateEvents/closeIntercepted/detached/
arbitraryHwndRejected八项均true。Draft PR #37未合并；无新Release或原生音频验收声明。
