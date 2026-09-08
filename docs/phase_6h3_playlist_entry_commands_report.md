# Phase 6H3 — 歌单条目原子命令报告

2026-09-08，`Z-YO-YI/YYMusic`，分支 `codex/playlist-entry-commands`，
基于 fetch/pull 后的 `a7dd5d05c4064951b281da7718bb0c48e076405e`。
本批完成条目添加、移除、排序的命令基础；不把底层测试通过称为管理界面或上线完成。

## 交付

- ADR-059 先于公共合同变更。新增不可变 PlaylistEntryDraft，仅包含独立 ID、完整 TrackRef、UTC addedAt。
  appendPlaylistEntry 在当前事务中确定尾部位置；全局条目 ID 碰撞拒绝，不覆盖已有记录。
- removePlaylistEntry 按条目身份移除；movePlaylistEntry 按当前同歌单锚点插入之前，null 表示末尾。
  不以过期数字下标或整表快照覆盖存储。相同歌曲可重复，本地/在线/已移除来源软引用保留。
- 三命令只允许现存自定义歌单；缺失歌单/移动目标/锚点和跨歌单条目均失败。
  移除真正不存在的条目幂等；自己作为锚点、已经相邻或已在末尾均不改变时间。
  共享安全文案明确“歌单或歌曲条目”不存在，已有 Widget 回归相应更新，未改布局或视觉基线。
- SQLite count/max 联合既有唯一和非负约束验证连续位置。邻居通过空闲正数区间两次位移，
  避免逐条唯一约束冲突；不删掉再重插全表。位置及父歌单单调 updatedAt 在同一事务中提交/回滚。
  原有名称、说明、createdAt、条目 ID/来源/addedAt 不变，无曲目/收藏/历史/队列/来源/文件写入。
- 根 PlaylistController 复用已有 busy、先登记后通知及关闭排空；元数据和条目命令不能重叠。
  追加的 128 位随机 ID 仅在接受后产生，ID 工厂重入关闭也等待已登记写入；异常不输出原文。
  Library 继续用原有订阅观察父歌单变化，无第二份列表、数据库、构造期查询或音频副作用。
- Fake 新命令对齐身份、系统保护、缺失目标、连续顺序和时间语义；引导/导入 save/replace 合同保持。
  本次写入仅发生在隔离测试库，未修改用户真实歌单或歌曲文件。

## 验证

- 最终 **615/615 Flutter**，新增 43 项：21 项真实 SQLite/Fake 共用合同与模型测试、
  11 项 SQLite 专项、11 项根 Controller/关闭测试。原 73 张 Golden 字节未改且全量通过。
- 覆盖并发追加/ID 碰撞/追加移除改序组合、混合来源/重复引用、三类系统歌单、跨歌单保护、
  缺失/非法/带引号身份、空列表及首中末移除、前后移动/无操作、每条加入时间/元数据保持、
  时钟回退、两种存储各 120 步确定性随机指令与独立列表模型比对。
- SQLite 在插入、删除、临时位移、回填、最终目标位置、父时间更新六个阶段注入失败，
  全部回滚且错误脱敏；追加/移除的父更新失败另有回滚用例。损坏位置拒绝而非静默修复。
  既有曲目/收藏/历史/队列/其他歌单保留，现有 Library 真实投影随根命令更新且无播放。
- 元数据/条目共享 busy、拒绝命令不生成 ID、不可用/关闭拒绝写入、安全错误/明确重试、
  工厂异常与重入、三命令成功和失败的根关闭排空均通过。
- **86/86 Node**；严格 analyze 零问题；287 个 Dart 文件格式零修改。
  build_runner 和 make-migrations 重跑，生成代码、Schema、迁移、依赖与 lockfile 零差异。
  五份指纹、ZIP 24 项逐字节、源码与 APK 包内完整音频许可均通过。
- Android Debug 本地预检成功（Gradle 22.8 秒），48 SVG/字体/许可资产逐字节一致，v2 单签名验证成功。
  APK 231,818,127 字节，SHA256 `e70e5b45674d8498a571df5556d200142bffa0a73540bcc7558e21f319e75799`。
  `build/app/outputs/flutter-apk/app-debug.apk` 仅本地产物，不入 Git；Java 原生访问警告保留，未绕过检查或升级环境。

验证命令沿用 `dart format --output=none --set-exit-if-changed lib test integration_test`、
`flutter analyze --no-pub --fatal-infos`、`flutter test --no-pub --reporter expanded`、
`node --test tools/*.test.mjs`、两个 Drift 生成命令、指纹/ZIP/许可检查、
`flutter build apk --debug --no-pub`、`verify_android_apk.ps1` 和 `apksigner verify --verbose`。

## GitHub 与边界

前置 H2 精确提交 a7dd5d0 的 [push 34195449767](https://github.com/Z-YO-YI/YYMusic/actions/runs/34195449767)
与 [PR 34195529670](https://github.com/Z-YO-YI/YYMusic/actions/runs/34195529670)
两组 checks/Android/Windows 全成功，本批已回填 H2 报告；Draft PR #47 仍 OPEN。
本批实现提交 `cbe7bdc1b8c3e11bde293250db82d48162e9693c` 已同步远端，
[Draft PR #48](https://github.com/Z-YO-YI/YYMusic/pull/48) OPEN，base 为 `codex/playlist-editor-surfaces`。
2026-09-08 在 H4 开工前复核该精确提交的 [push 34198822942](https://github.com/Z-YO-YI/YYMusic/actions/runs/34198822942)
与 [PR 34198919253](https://github.com/Z-YO-YI/YYMusic/actions/runs/34198919253)：两组 checks/Android Debug/Windows native 均成功。
专用音频诊断 job 按普通触发条件 skipped，不计作新的实机音频通过。
本地结果或前置成功不代替新提交云端验收。普通 push 的 Android job 不上传 APK；Windows Debug 为开发包。
未合并/发布/改写历史，未提交凭据、日志、用户数据或构建产物。本机 Windows C++/Debug CRT 限制仍在，Windows 由 GitHub 构建。

后续继续歌单内容读取会话、三端歌曲管理入口与播放动作，再推进 Local/Settings 等阶段。
导入/恢复、实时 REST、完整播放器/歌词、平台集成及发行仍未完成，默认新安装为空库，尚非上线版本。
App.tsx NEW_ICON_SPRITE/POLISH_CSS 和基础 HTML 都保留为设计依据。
既有网页对照安全限制不绕过；本批无新实机音频或 HTML 网页对照证据，Golden/构建不替代这些验收。
