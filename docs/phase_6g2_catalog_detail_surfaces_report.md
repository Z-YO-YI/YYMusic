# Phase 6G2 — 专辑／艺人原生详情报告

2026-09-06，仓库`Z-YO-YI/YYMusic`，分支`codex/catalog-detail-surfaces`，基于已fetch/pull的
`5508cf4`。本批仅为主指令Phase6 Albums/Artists的页面增量，不代表整个Phase6或上线完成。
先记录计划/ADR-055后改公共导航与根接线，继续遵循完整App.tsx与基础HTML审计；不使用WebView。

## 已实现

- 音乐库专辑卡及“查看艺人”→专辑/艺人详情；专辑署名→艺人、艺人专辑→专辑。
  URI独立转义完整来源与实体ID，不以名字或内存extra猜关联，拒绝缺失/重复/非法来源参数。
- Phone纵向、Tablet横屏信息/曲目分栏、Windows独立桌面布局；共用原生设计组件和根播放器。
  使用App.tsx覆盖后的标题、图标、圆角/阴影与原占位系统，没有下载功能/渐变/默认Material界面。
- 摘要、艺人歌曲/专辑分区按真实数据Loading/Empty/Error/重试；分页20、200原始行上限、
  惰性构建、不读整库。公开来源名独立读取和安全回退，不等待在线连接，也不接触秘密。
- 本页可用曲目调用根playCatalogTrack，复用/追加完整引用而非清空队列；不可用引用仍可见。
  页面失活、被下一详情覆盖、刷新或销毁撤销未执行播放意图，已经开始的正常播放不因离页停止。
  关闭仍等在途读和动作排空后再释放根存储；不创建第二播放器/数据库。
- YYTrackTile新增默认true的showMore；详情显式false隐藏本批没有实现的更多操作。
  来源公开名在摘要显示，曲目短标签专门显示“本地/在线引用/文件失效”等，手机不会被长来源名挤掉原因。

## 审查修复与真实回归

1. 初版把详情State放在AdaptiveRoot内，Android跨600断点时重建会话。先复现失败，改为详情
   State位于Shell之上、由App传入frame包装内容；不把Shell选择逻辑搬到业务层。
2. 仅复用ScrollController仍会在更换ScrollPosition时把240偏移变成0。新增失败用例后，
   三布局共用路由内PageStorageKey；横竖屏、零尺寸/恢复保留偏移和已加载28张专辑。
3. GoRouter同一路径模板替换source参数会保留旧State，显示另一来源的数据。实际router.go
   先复现后，把强类型完整引用纳入Page Key；不同来源重建会话与Bucket，相同完整引用保留状态。
4. 最初返回断言寻找已被惰性列表移出的分段控件，分页点击在滚动尚未稳定时击中底栏；修正
   测试先滚到目标并等待布局，显式验证hitTestable，不禁用点击警告，也不改真实分页行为。
   Widget新增分页读取在FakeAsync中需pump推进，直接await造成挂起，已终止该轮并修正后重跑。
5. 视觉逐张检查发现重复的长来源名挤掉失效原因，改为摘要显示来源、短标签显示状态并补断言。
   静态分析发现的测试大括号/导入问题已修正；没有降低lint、Golden比较阈值或删除失败测试。

## 验证结果

- 506/506 Flutter，包含67张Windows宿主Golden；新增8项单位、13项Widget和6张Golden。
  6张新图及3张旧图差异逐张查看。旧音乐库phone_albums/windows_dark_albums启用卡片，
  tablet_portrait_artists新增真实按钮；其他58张旧图不变。
- Windows键盘Tab/Enter可打开详情和刷新，Esc返回原音乐库按钮焦点；Android Back返回连续栈。
  599/600/800/1024/1280宽与844×390、Windows599/840/1024/1440及130%文字无溢出。
- 77/77 Node；严格analyze零问题，265 Dart文件格式零修改。
- build_runner与drift make-migrations重跑，生成代码、Schema、迁移助手、lockfile零差异。
  Domain/Data/platform、Android/Windows权限配置、依赖及设计原件未修改。
- 五份SHA256与ZIP全部24文件逐字节一致；六包完整LICENSE与原生许可源校验通过。
- 本机Android Debug构建成功（Gradle16.3秒），48 SVG/字体/许可资产、完整音频NOTICES、
  原生全文许可及v2单Debug签名通过。Java原生访问警告保留，未伪称无警告。
  APK为231,771,571字节，SHA256：
  `3d90311b40b515ba0a51eec256e920b46611ba3f1f017d999e1a5b4058484055`。
  本地产物：`build/app/outputs/flutter-apk/app-debug.apk`；不提交APK或其他构建文件。

命令：`dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、`dart run build_runner build`、`dart run drift_dev make-migrations`、
源码/ZIP/包内许可脚本、`flutter build apk --debug --no-pub`与`apksigner verify --verbose`。

## GitHub及尚未完成

后续核验：实现`7fe2e21ca17f9b009846c1d8b23b7a3399012725`的
[push33989357683](https://github.com/Z-YO-YI/YYMusic/actions/runs/33989357683)与
[PR33989396295](https://github.com/Z-YO-YI/YYMusic/actions/runs/33989396295)均已完成success，
checks、Android Debug、Windows native build逐job成功，专用音频job明确skipped。
[Draft PR #43](https://github.com/Z-YO-YI/YYMusic/pull/43)未合并；不将标准构建误记为新音频验收。

前置`5508cf4`两组云端checks/Android/Windows成功已经独立核实，回填Phase6G1报告与PR #42；
不把其成功用于代替本提交。当前分支推送后建立base为`codex/catalog-detail-sessions`的stacked
Draft PR；本批精确提交checks/Android/Windows结果在PR记录，不自动合并、发布或覆盖远端历史。
本机Windows C++/Debug CRT限制未改变，Windows继续由GitHub构建；本批没有新音频实机验收。

详情收藏菜单/播放全部、真实封面、搜索实体入口尚未做；首页专辑外观卡实际上是曲目快捷播放，
本批未暗改其行为。下一步先核验此提交两端云端构建，再接搜索专辑/艺人入口及后续详情动作。
歌单管理、导入/失效恢复、实时REST、完整播放器/歌词、设置持久化和发行仍未完成。
默认新安装仍显示真实空库，没有植入测试样本。原浏览器file安全限制未绕过，
原生Golden不等同于HTML截图对照或完整应用可用/上线验收。
