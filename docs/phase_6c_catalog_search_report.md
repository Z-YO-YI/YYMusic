# Phase 6C — 本地搜索数据层报告

2026-09-05，`codex/catalog-search-data`，fetch/pull后基于`62b8a7c`，独立分支，未改main。
本批实现主指令17.2/22的搜索数据基础，不代表三端Search页面或Phase6全部出口完成。

## 输入与前置确认

重新校验ZIP、主指令、完整App.tsx与基础HTML，SHA256分别为：

- ZIP：`d75093d142b88044a32a95d6064373138b3431b767c8f4df48bff4f7896629ee`
- 主指令：`5f024c778be878afc6fcdcc2d3051b1aec5d3357b2fd01d2ea23b1a71066cfcf`
- App.tsx：`20bcba3377abecfce3a07f733c8035f87d8108cfecbe4b97552228f60fb9ef39`
- 基础HTML：`81217cd676d25ab38a91a7d81bcbc2a7cfeaee40334aca163dd02cc7d1b95229`

原归档24文件逐字节一致；不修改参考、不运行旧HTML内存catalog作为正式搜索，保留NEW_ICON_SPRITE/
POLISH_CSS的完整合成。Phase6B精确提交的push33976793559与PR33976796108两组三job均成功，
两端包内资产/许可和真实窗口八项指标已独立核验，补入首页报告及Draft PR #37。

## 实现

1. CatalogSearchRepository提供歌曲/专辑/艺人独立PageResult，正式DriftLibraryRepository实现。
   来源类型与来源ID可组合筛选，曲目使用完整TrackRef；专辑/艺人保持既有来源ID+实体ID身份。
   专辑/艺人类型筛选按关联曲目存在判断，保留数据库聚合计数，不创建新的实体/Schema。
2. 匹配标题、曲目专辑名、关联艺人名和公开来源名称；不查询端点/路径/凭据/元数据私有字段。
   值和分页参数全部绑定；引号、百分号、下划线按字面文本处理，空白查询无SQL。
   大小写规则为SQLite内建ASCII折叠，中文按字面子串；不宣称拼音、Unicode大小写折叠或FTS已实现。
3. 一个只读SELECT：CTE先稳定排序/筛选并取limit+1个实体，再展开关联艺人，最后按完整身份归组。
   多艺人不会截断分页；结果与艺人来自同一语句快照，不创建Drift写事务、不改变全局SQLite设置。
   搜索可能在数据库内扫描匹配字段，返回量有界不等于任意大库性能合格，详见ADR-050。
4. SearchCancellation派发前与异步查询后检查；取消返回独立SearchCancelled，不报告为数据库损坏。
   这是合作式取消/丢弃晚到结果，不是强制中断正在执行的SQLite语句。原有Library生命周期合同保持。
5. SearchHistoryRepository复用v2已有表：最近20项、时间倒序/ID稳定排序、ASCII归一查询与可空来源
   的确定身份。显式record原子替换等价旧ID、写入与裁剪；clear只清历史，不影响曲库和音乐文件。
   查询不自动保存历史、联网或写入搜索结果。读写错误固定脱敏；模型诊断不包含搜索文字。
6. 历史Repository默认共享数据库、不关闭它；拥有数据库时先禁止新操作、等候在途操作，再幂等关闭。
   本批未将新合同接入AppDataServices/DependencyGraph或SearchController，留给下一批页面接线。

## 验证与纠错

- 最终本地Flutter **379/379**，含49张完全未改动的Windows宿主Golden；Node **67/67**，严格analyze0。
  218文件格式零差异；build_runner、Drift再生成成功，生成源码/历史快照/测试助手/lockfile零差异。
- 新增11项搜索测试：输入/脱敏、空与预取消无SQL、中文/ASCII/特殊字符、公开源名/来源移除，
  完整曲目身份与筛选、专辑/艺人去重/关联计数、450首有界分页、先实体后多艺人分页、晚到取消、
  损坏/生命周期、两条真实SQLite文件连接的并发更新。450首取200项只返回201实体且一次SELECT，
  写事务次数为0；多艺人边界另验证一页一实体完整保留两条艺人信息。
- 新增9项历史测试：归一与来源区分、20条排序/裁剪、30次并发同查询、旧ID替换、触发器故障回滚，
  清除保留正式曲库、非法/损坏/时钟错误脱敏、共享关闭等待在途写入、真实文件关闭后重开保持数据。
- 首轮双连接用例发现Drift原生transaction使用BEGIN IMMEDIATE，并发写入被拒绝。已将两次查询
  改为单语句只读展开；原并发用例通过，新增零写事务和单SELECT断言，没有放宽一致性要求。
  严格分析发现import排序/跨行if缺括号，均已修正。测试中独立NativeDatabase连接产生的Drift
  多实例警告保留；它们使用独立Executor和隔离临时路径，没有共享生产连接或用户数据。
- ZIP24/24、六包LICENSE/两构建来源、完整原生许可源码校验通过。

Android默认入口Debug构建成功（Gradle17.2秒），**231,634,996字节**；SHA256：
`ee450f52ba71a02c98b0f7a17a449d6a5c074a590f71c5a9d45917b7a732a132`。
48项设计资产、六包NOTICES.Z、原生全文许可匹配；参考/秘密文件及已拒media_kit均未打包。
v2签名有效、一个签名者；Java原生访问警告未掩盖。此APK仅供本机诊断，用户APK交付仍来自GitHub。

## GitHub与剩余边界

后续复核：实现 `b5d960f0246968525ecae1a04953e1871e5bb49a` 已在
push [33978030423](https://github.com/Z-YO-YI/YYMusic/actions/runs/33978030423)
与 PR [33978045428](https://github.com/Z-YO-YI/YYMusic/actions/runs/33978045428)
两组全部通过 checks、Android Debug、Windows Debug、Windows Golden 和真实窗口测试。
两份白名单日志均验证 ZIP 24 项、六包许可、51 个原生坐标/3 份全文法律材料、APK 48 资产、
Windows 65 文件、无 media_kit；八项窗口结果均为 true。音频专用测试本轮 skipped，
不能记为新音频验收。Draft PR [#38](https://github.com/Z-YO-YI/YYMusic/pull/38)
以 `codex/home-surfaces` 为 base，仍未合并；下面的“本批”描述保留 Phase 6C 历史边界。

本批提交后推送，创建以`codex/home-surfaces`为base的堆叠Draft PR；精确提交的云端checks/
Android/Windows结果在PR单独补验。不得把前置成功当本批通过，不提交APK/日志/临时数据库/秘密。

无新UI、依赖、Schema、平台权限或发布；无WebView、音乐下载、Release签名或自动合并。
49张Golden只能证明现有界面未回归，不是新Search页面、HTML网页对照或原生音频新验收。
Windows本机工具链限制未解除，云端Windows构建单独核验。
下一步按Phase6继续三端Search页面与根控制器：防抖、过期请求丢弃、独立结果状态、最近搜索/清除、
Enter首条播放和来源标签。持久REST引用的查询不等于实时在线搜索；并行REST/来源配置、导入、
完整播放器、平台媒体与Phase11上线仍待后续增量，当前应用不应宣称已可用或上线。
