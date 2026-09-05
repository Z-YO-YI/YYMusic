# Phase 6G1 — 专辑／艺人详情会话完成报告

## 实际交付

仓库 `Z-YO-YI/YYMusic`，独立分支 `codex/catalog-detail-sessions`，基于fetch/pull后的`b72413e`。
这是主指令Phase6 Albums/Artists的状态层增量，不代表详情页面、全部Phase6或上线已完成。

- 新增 `lib/features/catalog_detail/common/catalog_detail_state.dart`：闭合Album/Artist目标与摘要、
  不可变分区快照；完整来源身份不退化成显示名称，保留Repository真实聚合计数。
- 新增 `catalog_detail_controller.dart`：摘要先确认存在及身份，再并行获取艺人专辑/曲目；
  专辑只取自己的曲目。分区失败独立，保留旧页，重试原offset；不自动读取全库。
- 新增 `catalog_detail_sessions.dart`：根注册各个短期详情会话，构造不发请求，start幂等；
  关闭页立即取消结果，仍保留注册直到真实Future排空；根关闭等所有会话后才关闭共享存储。
- `lib/app/dependency_graph.dart` 创建唯一注册表并纳入同步停止/异步排空；借用同一CatalogBrowse。
  没有新增数据库、播放器、HTTP、文件访问或收藏/队列/历史写入。
- 页大小最多20，最多200原始行；完整TrackRef/AlbumRef去重但offset按原始行数递增。
  空页终止，超长响应按请求额度截断，失效引用仍显示在读模型中，来源未配置不自动隐藏数据。
- 刷新取消摘要与两个分区，旧成功/错误不回写或通知；取消只丢弃结果，不宣称中断SQLite。
  错误只暴露安全分类和固定诊断ID，不透传adapter异常文字、来源ID或原诊断字符串。
- 校验摘要完整身份、子项来源及专辑曲目归属；艺人关联交给既有SQL曲目credit合同。
  合辑参与艺人可以不在album artist中，不能用名字/专辑署名误过滤合法关联。

## 审查修复

短中间页导致固定20条末页越过200上限，在新详情和既有Search复现215，Library也请求20而非剩余5。
新增三个先失败的回归后，修正这三个控制器的末页请求和实际接收额度；5/2条余量、重复/超长响应
均不会越界。只涉及控制器查询边界，未改变现有页面、排序、数据合同或61张Golden。
对应两个旧Node分页门禁增强为剩余额度+响应截断，根关闭断言保留并纳入详情注册表。

## 测试与构建

- 479/479 Flutter；新增21项详情Controller、4项真实SQLite、2项Library/Search容量回归。
  三端原有61张Windows宿主Golden全部通过，PNG零修改；未改变测试阈值或删除失败用例。
- 75/75 Node，严格analyze零问题，253个Dart文件格式零修改。
- build_runner / drift make-migrations重跑，生成代码、Schema、迁移助手及lockfile零差异。
  Domain/Data、Android/Windows平台配置和设计参考均未修改。
- 真实内存SQLite确认单摘要+单分区各一条查询、源隔离、分页参数21/offset、零写事务，
  收藏/历史/队列/搜索历史未被详情读取修改；合辑署名不同仍可关联。
  使用真实SQLite拦截器延迟查询，证明根关闭前数据库未释放，取消排空后仅关闭一次。
- 五份设计指纹与ZIP24逐字节校验通过；六包LICENSE、两个原生构建源、原生全文许可通过。
- 修复后的本机Android Debug构建通过（Gradle16.4秒）；48设计/字体/许可资产、六包NOTICES.Z、
  原生全文许可及v2单签名通过。Java原生访问警告保留。
  APK为231,747,023字节，SHA256：
  `a0a597920110f0ee8fe68af4f50643ceef69b8f47d5988b0e0f4840a1ed2a2cf`。
- 最初测试编译发现测试探针扩展导入/历史方法名/销毁计数调用错误，均修正后重跑；没有忽略失败。
  首次476项成功不作为最终结果，短页修复后全量479项及Android重新构建。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
ZIP/源码/包内许可脚本、`flutter build apk --debug --no-pub`、`apksigner verify --verbose`。

## GitHub、设计与下一步

前置Phase6F的精确提交双组CI成功已回填其报告及PR #41；不把前置成功当作本提交通过。
本批推送后以`codex/library-surfaces`为base建立stacked Draft PR，精确提交Android/Windows构建
在PR补验，不自动合并或创建Release。APK/数据库/日志/秘密不提交GitHub。
Windows本机C++/Debug CRT限制未改变，构建继续由GitHub完成；本批没有新音频实机验收。

遵循完整App.tsx的NEW_ICON_SPRITE/POLISH_CSS及既有基础HTML审计，不使用WebView或生产Fixture。
本批不修改UI，不将单元测试或Golden称为HTML网页对照；既有浏览器安全限制未绕过。
下一步Phase6G2实现详情路由和Phone/Tablet/Windows独立布局、入口/返回关系与根曲目动作；
须在界面销毁时关闭会话并验证跨断点保留。真实封面、导入/恢复、实时来源、完整播放器和上线仍待后续。
