# Phase 6H8 — 大歌单分组浏览报告

2026-09-08，`Z-YO-YI/YYMusic`，分支 `codex/playlist-window-navigation`，
基于fetch/pull后干净的 `c142daf186efd6c1a4bb717ce02c986066e5ffd9`；未在main/master开发。
先复核五份源指纹/ZIP24项、读取主指令与相关原生实现并记录计划/ADR-064。

## 交付与文件

- `playlist_content_controller.dart`：增加有界offset与绑定快照的前后组命令。
  首组仍20→200，下一组/上一组各最多200；查询替换整体快照，未累积整歌单或混合不同时刻排序。
  活动路由/当前快照/busy/关闭校验先于查询；失败保留不可操作的旧行，重试保持目标组。
  失效通知刷新当前组；删除使组越界时先回退最后有效组再发布，区分真空歌单与父记录消失。
- `playlist_content_sections.dart`：在列表上下提供明确范围及YYButton前后组导航，继续SliverList.builder。
  没有WebView、Material默认控件、新绘图标或新主题值。通过figma-design-to-code复用原始资产与YY设计系统；
  离线包无在线Figma节点，不虚构get_design_context或网页截图对照。
- `playlist_content_screen.dart`：保持根会话/播放器、菜单与覆盖路由保护，只在实际偏移变化后复位滚动。
  复查发现零尺寸期间完成查询需要延期处理滚动，现保留待复位偏移到页面恢复；同组刷新/旋转不复位。
- 新增两份Unit、一份Widget、一份Golden测试及三张新基线、Node门禁；
  更新原200条边界Widget断言，保留未知邻居移动禁用与原有所有回归。
  README、状态/测试矩阵、ADR同步更新；回填H7精确云端证据。

## 验证

- 全量Flutter **774/774通过**（39秒）：新增20项，即8分页会话、2真实SQLite、7三端Widget、3Golden。
  真实SQLite 1003条重复TrackRef、双艺人窗口全部可达；后五组只执行5个绑定SQL，返回最多400艺人展开行，
  单窗口仍最多200条，无写事务/N+1查曲。真实排序及移除后刷新/回退保留曲库记录。
  根关闭确实等待非零offset的SQLite读取Future再关闭共享数据库，不仅检查Fake计数。
- Node **96/96通过**；3张新Golden逐张查看，旧81张字节不变、阈值未变。
  Phone390×1000、Tablet1024×768深色、Windows1440×1000，130%文字下范围和前后组可操作。
- 测试开发中出现过测试专用Drift扩展导入/名称冲突与自动Focus节点定位问题；修正测试接线后重跑全量通过，
  未删除失败用例、关闭Lint或弱化产品行为。界面加载失败的安全提示/禁用旧数据/显式重试都保留。
- 最终严格分析零问题、327个Dart文件format零修改；build_runner/make-migrations后生成代码、Schema、迁移测试和lock零差异。
  五份指纹、ZIP24项、44图标/52确定产物、六包LICENSE与完整原生材料均通过。
- Android本地Debug预检成功（Gradle18.0秒），APK 231,897,615字节，
  SHA256 `d55808a13077b9b6036083f3a7cdca28e2cf029830eced229c3faa968bfaaa81`；
  48份包内资产逐字节、六包NOTICES.Z/原生材料及v2单签名验证通过。JDK native-access警告未隐藏。
  APK/日志仅保存在忽略的build目录，不入Git，不用本地预检代替用户要求的GitHub构建。
  16份变更文本的常见秘密模式扫描零命中；仅提交19份源码/测试/文档/新基线。

## GitHub与边界

前置H7 `c142daf` 的push34220162205/PR34220259946两组源码、Android Debug、Windows native均成功；
PR #52保持Draft/OPEN，Windows开发包与精确元数据已回填对应报告/PR，无PR附件、无新APK Release。
本批提交推送后建立stacked Draft PR（base=`codex/playlist-create-and-add`），由PR记录精确提交的双组云端结果。
不以前置成功冒充本批CI，不合并、不force、不上传用户数据/秘密/构建产物。

本批解决歌单条目超过200后的可达性，不代表实机大库性能Profile合格；组边缘未知邻居移动仍禁用。
选择器的200个匹配歌单上限仍要求缩小名称范围。播放全部/随机、系统歌单、Local Music/Settings仍在Phase6后续。
Phase7完整播放器/歌词/队列、Phase8真实导入/权限、Phase9在线来源、Phase10–11平台媒体/QA/发行均未完成。
默认新安装空库，Android Debug可构建不等于能导入日常听歌；Windows Debug依赖调试运行库，不是普通安装程序。

## 精确云端结果回填（Phase6H9开始时核验）

实现提交`33187c0491a6e6850f5a5bc6986df61f24e0c075`，Draft [PR #53](https://github.com/Z-YO-YI/YYMusic/pull/53) OPEN，未合并。
[push 34222808426](https://github.com/Z-YO-YI/YYMusic/actions/runs/34222808426)与
[PR 34222814936](https://github.com/Z-YO-YI/YYMusic/actions/runs/34222814936)均精确对应此head，
三项常规源码/Android/Windows job各自success；两项专用音频诊断job按条件skipped，不计为通过。
Linux690通过/84Golden跳过，Windows84Golden与1项真实窗口测试通过；默认Debug重建及65文件运行包检查通过。
Android51原生坐标/3全文法律材料/六包许可/48资产/v2单签名门禁通过。
push唯一Windows附件`10054902807`，名称`YYMusic-windows-debug-33187c0491a6e6850f5a5bc6986df61f24e0c075`，
67,329,030字节，digest `sha256:ed513106859ab5f739affe3161a6240b97591f8e3476e9754e6ddbcf5d1f21a7`，
过期时间`2026-09-22T12:03:56Z`。仅核验API元数据和运行日志，未下载/执行该附件；PR运行无附件，无新APK Release。
