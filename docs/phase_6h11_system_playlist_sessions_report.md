# Phase 6H11 — 系统歌单共用会话报告

## 精确云端结果回填（H12开始前复验）

实现提交`428a49f0049d51039da012639a07801e9880d025`，Draft [PR #56](https://github.com/Z-YO-YI/YYMusic/pull/56)开放、未合并。
[push 34239083727](https://github.com/Z-YO-YI/YYMusic/actions/runs/34239083727)与[PR 34239089582](https://github.com/Z-YO-YI/YYMusic/actions/runs/34239089582)均成功：
每组源码/Android/Windows三项通过，另两项可选音频诊断跳过，不能算成原生音频新证据。
Linux784通过/84宿主Golden跳过，Windows84 Golden与1真实窗口测试通过；101 Node、350 Dart格式零修改、严格分析零问题。
push Windows开发Debug产物ID10061880320，67,361,700字节，SHA256 `a4500e496ece7a97c3a0fbc55b0dd41108401212e05d2191e7412161656f1eb2`，UTC2026-09-22T14:50:19Z到期；仅核实元数据与构建日志，未下载/手动运行。
Android51坐标/三份完整原生原文/六许可/48资产/v2单签名与Windows65文件包校验通过；无新增APK Release。

2026-09-08，Z-YO-YI/YYMusic，分支`codex/system-playlist-sessions`。
基于已fetch/pull的干净`2c22cadbcbfab1a6ef3420cd01758a0410ce1535`；前置PR #55两组常规源码/Android/Windows成功。
五原始指纹、ZIP24项、44最终图标/52产物复验，完整重读主指令；本批依据17.4/23/Phase6继续歌单，不跳到后续导入阶段。

## 实际新增与修改

- `lib/features/playlists/common/system_playlist_controller.dart`：固定SystemPlaylistType的共用只读会话。
  构造无I/O，显式start幂等，先订阅再读；明确idle/loading/data/empty/error，旧数据可保留显示但失效后禁用导航。
  单串行worker合并失效，revision与监听generation隔离旧成功/错误；类型/offset/limit不符拒绝发布。
  20→200完整窗口、前后整组和删空末组回退；不拼跨版本分页，不制造父歌单，不改收藏/历史/播放/持久队列。
- `system_playlist_sessions.dart`与`lib/app/dependency_graph.dart`：同根注册、借用既有Repository。
  失活阻挡旧导航，不停止根音频；会话关闭先拒绝工作，再等待已接受读取和异步取消，根最后释放SQLite。
  监听getter/通知者重入关闭或刷新、取消失败脱敏和其他资源继续清理均有覆盖。
- `test/support/system_playlist_probe.dart`、Fake只读Hook及四份system_playlist会话测试。
  `tools/system_playlists.test.mjs`新增合同门禁，既有foundation架构门禁增加新会话的明确关闭顺序。
- README、实施状态、测试矩阵、计划和ADR-067更新，回填前置H10精确CI证据。

## 本地验证

- 新增29项：12控制器/类型合同、8生命周期、6窗口、3真实SQLite会话；全部通过。
- 全量**868/868 Flutter通过**（51秒），原84张宿主Golden全部通过且字节未改；**101/101 Node通过**（15.2秒）。
  严格分析0问题（6秒），350 Dart文件format零修改；代码生成和make-migrations后Schema/生成/lock/平台/资产无差异。
- 1003个收藏与队列条目完整可达，每窗口最多200；真实双艺人SQLite五组分别400/400/400/400/6展开行，
  每组一次绑定查询、无读事务、无音频调用；重复队列真实ID和页外当前ID不丢失。
  末组缩短回到有效组；真正SQLite读取被暂停时根不关闭存储，完成读取后关闭一次，旧结果不发布。
- 初轮测试参数名误用和三处多行if Lint已修正；全量Node最初失败于既有关闭顺序未列新会话，
  已在原断言中加入systemPlaylists.close并全量重跑通过，没有删除测试、关闭Lint或放宽Golden阈值。
- 五指纹/ZIP/六锁定音频LICENSE/两个原生构建源及完整原生材料检查通过。
- Android本地Debug预检成功（19.1秒），231,928,154字节，SHA256
  `d59be36a6e2f155ae2a75518b10c2eb3367c0e1182c523060fc103a4ad03ebd5`；48项资产逐字节、六LICENSE/NOTICES.Z、完整原生材料、v2单签名通过。
  JDK native-access警告未隐藏。本地预检不代替GitHub精确提交的双平台构建，不上传APK或日志到源码仓库。
- 提交前18份变更文本常见秘密模式扫描零命中；不把模式扫描宣称为全部安全审计。
- 最终收紧生命周期测试清理：只允许明确预期的关闭故障，其余不得吞掉失败；再次868/868 Flutter通过（50秒）、101/101 Node通过、严格分析0问题（7.7秒）。

## 与设计源关系、限制与下一阶段

对应HTML收藏/最近/队列的真实异步状态和主指令17.4系统歌单，不迁移DOM/localStorage或伪父ID。
沿用已完整审计的App.tsx最终Sprite/POLISH_CSS，本批没有新增UI、视觉修改或在线Figma操作，84基线不变。
本批还没有系统歌单可点击页面，没有新增真正开始播放后的历史记录行为；不宣称安装后即可日常听歌。
下一批接三端原生系统歌单入口与根动作，再验收真实播放历史；随后Local Music/Settings及Phase7–11继续分批完成。
实机大库Profile、网页截图对照、真实导入/权限、完整播放器、后台媒体及正式Release验收仍有缺口。

本阶段审查后提交推送stacked Draft PR（base=codex/system-playlist-projections），不自动合并、不改历史、不发布Release。
精确提交的push/PR标准双平台CI完成后在PR回填；日志/构建包仅在忽略build目录，不提交凭据或用户数据。
