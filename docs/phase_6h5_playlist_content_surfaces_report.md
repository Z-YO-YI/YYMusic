# Phase 6H5 — 原生歌单内容管理报告

2026-09-08，`Z-YO-YI/YYMusic`，分支 `codex/playlist-content-surfaces`，
基于fetch/pull后的 `97465063ba8b48195ed3e117169c84c0af6ab48a`，先计划及ADR-061再实现。
本批交付歌单内容入口、原生布局与单条动作，不等于整个Phase6或上线完成。

## 交付与安全边界

- 音乐库自定义歌单增加“查看歌曲”，通过查询参数编码完整不透明ID，保留斜杠、百分号、点段和中文；
  歧义/外部/无效链接失败关闭，页面不回显原始URI。系统歌单不假装接入自定义条目存储。
- Phone单列、Tablet横屏主从/竖屏组合、Windows独立宽布局；读取状态和滚动高于自适应Shell。
  使用原有YY按钮、列表、反馈和菜单，复用已审计App.tsx最终SVG、20px菜单/表面与14px歌单图标规则。
  `figma-design-to-code`技能按离线导出适用部分执行组件/资产复用；没有fileKey/nodeId，不伪造在线Figma读取。
  完整App.tsx的NEW_ICON_SPRITE/POLISH_CSS及基础HTML仍为依据；没有WebView/新图标系统/新依赖。
- 复用H4一致快照：加载、空歌单、歌单不存在、安全读取错误、重试和真实计数明确。
  从20条扩展到200条，显示总数及上限；不声称超过200条已完整可浏览。
  重复曲目使用独立entry ID；缺失Track保留来源引用，用“未解析”标签，不捏造可播放曲目。
- 单首播放借用唯一根PlaybackController并复用/追加根队列，不替换队列；
  移除/上移/下移借用唯一根PlaylistController，稳定条目/锚点命令，不用陈旧索引覆盖整表。
  下移依赖未知后继锚点时禁用（未读完前缀末两项），防止把窗口边界误当整份歌单结尾。
- 更多按钮、长按、Windows右键打开同一受控菜单。每次打开使用新请求身份并绑定不可变快照；
  旧回调不能关闭或操作新菜单，失效快照立即关闭菜单，过期行禁止播放和管理。
  菜单覆盖整个Shell，阻隔背景焦点/语义；Tab闭环，Back/Esc先关菜单，返回恢复入口焦点。
- 离页/刷新/失效通知/关闭撤销加载中尚未执行的播放。复查新增两个先失败回归，证明监听出错或提前结束
  原本可能迟到播放；现失败统一递增播放意图代次，完整回归通过。不停止已播放音乐。
- 已接受写入先登记再通知，离页仍排空；根writer支持监听器中同步关闭，延迟super.dispose到通知退出。
  离页后的失败保留固定脱敏反馈，返回音乐库可见且可清除；不自动重试不确定写入。
  UI不直接写库、不另建播放器或存储；生产默认空库不注入Fixture。

## 验证

- **680/680 Flutter**：新增11动作/路由单位、14界面（含1真实SQLite全根接线）、5 Golden，共30项。
  覆盖上述身份/分页/生命周期、未知边界、覆盖路由、130%文字、旋转/零尺寸、busy防重入、
  根关闭排空及失败反馈；真实SQLite改序/移除仅改变目标条目，保留Track和重复引用。
- **78张Golden**：5张新增覆盖Phone列表/菜单、Tablet横竖屏和Windows深色，已逐张查看；
  旧3张歌单编辑图仅背景“查看歌曲”入口/说明及换行更新，旧70张字节不变。无比较阈值放宽。
  首轮4项旧预期失败来自3张上述背景图及Library说明断言，逐项核对更新后通过。
- **90/90 Node**：新增原生路由/会话及共享动作结构门禁。严格analyze0；309个Dart文件格式零修改。
  重跑build_runner和make-migrations，生成代码/Schema/迁移/lockfile无差异；
  五份指纹、ZIP24项逐字节、六个音频包许可及原生材料来源检查通过。
- Android Debug本地预检成功（Gradle21.3秒），48份SVG/字体/许可资产逐字节一致，
  六包及原生声明验证通过，v2单Debug签名有效。APK231,861,533字节，
  SHA256 `07b5481a7045715c480ca23d98b25e27a80d4c249b4142c876e4ed2c627da3ce`。
  `build/app/outputs/flutter-apk/app-debug.apk`仅本地预检、不入Git，不替代用户要求的GitHub构建。
  JDK原生访问警告保留，未修改全局工具链或关闭校验。

验证命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、两项Drift生成命令、指纹/ZIP/许可检查、
`flutter build apk --debug --no-pub`、`verify_android_apk.ps1`、`apksigner verify --verbose`。

## GitHub与剩余工作

前置H4精确提交 `97465063ba8b48195ed3e117169c84c0af6ab48a` 的
[push34203551280](https://github.com/Z-YO-YI/YYMusic/actions/runs/34203551280) 与
[PR34203648385](https://github.com/Z-YO-YI/YYMusic/actions/runs/34203648385)
两组checks/Android Debug/Windows native成功，Draft PR #49保持OPEN；本批回填H4报告。
本批审查后提交并推送stacked Draft PR，base=`codex/playlist-content-sessions`；
精确提交及本次CI结果记录于对应PR，不把本地或前置成功冒充本批云端通过。
普通push只上传14天Windows开发Debug审查包，需要Debug CRT；普通Android job构建但不上传APK。
没有合并、Release、手动发布或历史改写，不提交凭据、用户数据、日志、构建产物。

### 后续回填：H5精确提交云端证据

提交 `4847f29b66d1b3d82f32e71aa43309cc3f6dfac4` 的
[push34208980405](https://github.com/Z-YO-YI/YYMusic/actions/runs/34208980405) 与
[PR34208990757](https://github.com/Z-YO-YI/YYMusic/actions/runs/34208990757)
均完成源码checks、Android Debug和Windows native三类标准job，整体success；
[Draft PR #50](https://github.com/Z-YO-YI/YYMusic/pull/50)保持OPEN，未合并。
Windows标准job含真实窗口首帧/关闭集成、Windows宿主Golden、默认入口重建及完整文件包校验；
两类专用音频job与Release按设计skipped，不计为本批新音频或发行证据。

push的Windows Debug artifact `10049500733`，67,305,456字节，
GitHub API digest `sha256:646f31d4f6150588c632d1ed49389bb708d4be0acb6a933a7ba73e0403d16a82`，
到期时间 `2026-09-22T09:25:57Z`；本批未下载，不将API摘要冒充本地复算。
此包依赖Debug CRT，不是通用Windows安装程序；Android标准job没有上传APK。

H5结束时下一增量仍需添加歌曲选择器、播放全部/随机、系统歌单、超过200条浏览策略；
导入/恢复、实时REST、完整播放器/歌词、平台集成及发行仍待后续主指令阶段。
本机Windows缺C++/Debug CRT的限制未解决；本批无新设备音频验收或HTML网页截图对照。
既有网页安全限制不绕过，Golden和常规Windows窗口CI不能代替这些证据。
