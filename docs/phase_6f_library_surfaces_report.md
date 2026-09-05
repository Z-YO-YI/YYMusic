# Phase 6F — 原生音乐库入口与受控曲目动作

## 实际交付

仓库 `Z-YO-YI/YYMusic`，独立分支 `codex/library-surfaces`，基于 fetch/pull 后的 `0c38340`。
已复核该前置提交两组GitHub Android/Windows/Golden/原生窗口成功日志，并回填Phase6E报告与PR #40。
本批按主指令17.3/Phase6接入Library入口，不代表整个Phase6已完成。

- 新增 `lib/features/library/common/{library_controller,library_screen,library_sections}.dart`
  及 phone/tablet/windows 三个独立布局；根图、路由及App接线到同一个数据库和播放器。
- 五分类：专辑、歌曲、艺人、歌单、本地。目录每页20、最多200原始行，SliverGrid/SliverList惰性构建；
  按完整TrackRef/AlbumRef/ArtistRef去重，重试沿用原始offset，不把重复项当作额外可读取容量。
  各分类页和排序保留；筛选改变取消全部旧目录token并回到页首，迟到结果不能覆盖新筛选。
- 曲目/专辑/艺人12种排序及方向；来源类型与可用性组合，本地分类强制local但不丢其他分类来源偏好。
  排序沿用Phase6E的ASCII/首位艺人语义，非拼音排序；专辑/艺人计数仍为完整目录聚合值。
  本批UI未提供单个来源ID选择，领域数据合同已支持该能力。
- 来源名称只读取公开名称；失败回退“来源未配置”，不露URL、路径或凭据。新安装为真实空库，
  已保存REST引用不等于实时在线请求。错误/空态/加载/重试均由数据状态驱动。
- 曲目主动作调用唯一根playCatalogTrack，复用或追加条目而不替换队列；当前行按完整引用显示播放状态。
  切分类/筛选/离页/关闭取消待执行播放意图；已完成的队列追加不会自动回滚。
- 右键、长按和更多按钮使用页面内原生Flutter菜单，真实播放或切换收藏；收藏由Repository流提供真值，
  写入失败固定文案，播放失败仍由根播放器反馈。不可用曲目不能播放，但仍能收藏/取消收藏。
- `YYTrackTile.allowMoreWhenDisabled` 为兼容性新增的默认false选项，只有Library启用；
  失效曲目主动作保持禁用，更多按钮正常可用；旧调用方的视觉/交互默认行为保留。
- 菜单关闭恢复焦点，Esc/Android Back不误离开Library；页面失活撤销菜单和播放意图。
  菜单是内容区域内浮层，不覆盖Shell导航/播放栏，不声称是Win32系统菜单。
- 根关闭同步停命令、取消读取与订阅，排空在途查询和已接受的收藏写入，再释放共享存储。

## 设计对应与限制

四项指纹及ZIP24保持Phase0一致；继续使用完整App.tsx的NEW_ICON_SPRITE/POLISH_CSS，
包括标题800/-.82、专辑封面20圆角/阴影、曲目14圆角及最终图标，不只读旧HTML。
基础HTML2253起的五分类/专辑网格/曲目/艺人/歌单结构用于分层，示例目录不进入生产路径。

新增六张Windows宿主Golden：Phone专辑/本地空态、Tablet竖屏艺人/横屏曲目、Windows深色专辑/
窄屏菜单，全部130%文字逐张检查。原55张PNG未修改；本批艺术图仍是明确占位，专辑卡只读并呈禁用态。
截图只能验证原生回归；Phase2网页对照仍受既有浏览器安全限制，未绕过，也不声称像素一致。

专辑/艺人详情、歌单创建/编辑/系统歌单、来源配置、真实封面、导入/授权/失效恢复和完整播放器
仍按后续阶段实现。歌单仅展示既有元数据流前200项，没有伪装成数据库分页，不能据此声称大歌单管理完成。
收藏/来源/歌单采用既有元数据流，不把其全量元数据行为写成完整曲库的分页读；目录曲目/专辑/艺人走分页合同。
现有Shell的部分开发提示和完整播放路由仍为前置阶段边界，本批不把它们视为已完成业务能力。

## 验证结果

- 452/452 Flutter测试：新增15项Controller/真实SQLite、6项Widget与6张Golden，合计61张Golden。
  覆盖分页/去重/空页/超长适配器上限、全部排序方向合同、来源/状态/本地约束、取消/保留旧页/关闭等待，
  真实SQLite查询与收藏、根队列复用、失效歌曲收藏/写失败脱敏、三端断点、右键/长按/更多/焦点/返回。
- 两个旧路由测试不再点击已被Library替换的Foundation临时按钮，改调真实Library持有的AppNavigation；
  返回目标、Shell、播放器实例和状态断言保留。这不是完整播放器按钮已实现的证据。
- 73/73 Node门禁；新增两项Library分层/分页/根关闭约束，原根关闭顺序断言纳入Library排空。
- 严格analyze零问题，247文件格式零修改；build_runner / make-migrations 重生成后，
  Schema/生成代码/迁移助手/lockfile零差异。无新依赖/平台权限/Schema/引擎、WebView或下载。
- ZIP24逐字节一致；六包LICENSE、两个原生构建来源及完整原生许可源码校验通过。
- 本地Android默认Debug构建成功（Gradle16.9秒），231,732,126字节，SHA256：
  `bae207e1d3e1d477791c0df1f4aa6584344235071728d14ee5d587bfe7023578`。
  APK48设计资产、六包NOTICES.Z及原生全文许可通过；v2签名有效，一个签名者。
  Java原生访问警告保留。本机包仅作诊断，用户APK继续通过GitHub构建。

运行命令：`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart format --output=none --set-exit-if-changed lib test integration_test`、
`dart run build_runner build`、`dart run drift_dev make-migrations`、源码/包内许可和资产脚本、
`flutter build apk --debug --no-pub`、`apksigner verify --verbose`。全部成功，不跳过失败用例或降低比较阈值。

## GitHub与下一步

本批提交推送后，以 `codex/catalog-browse-data` 为base创建stacked Draft PR；精确提交的云端
checks/Android/Windows结果在PR补验，不把前置成功当作本批通过。没有自动合并或创建正式Release。
APK/日志/临时数据库/秘密不提交GitHub。本轮Fake播放与截图不算新音频实机验收；
Windows本机C++/Debug CRT限制仍在，原生构建由GitHub核验。
下一增量按Phase6继续专辑与艺人详情，沿用完整来源身份和根播放器；当前仍不是完整可用或上线版本。
