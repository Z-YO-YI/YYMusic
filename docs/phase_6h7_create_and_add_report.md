# Phase 6H7 — 新建歌单并添加当前歌曲报告

2026-09-08，仓库 `Z-YO-YI/YYMusic`，分支 `codex/playlist-create-and-add`。
开始时工作区干净，fetch/pull后基于 `b2845a3b23852deb01f41538f4d79cc18a7a2076` 创建独立分支；
先验证五份指纹及ZIP24项、读取阶段记录/主指令歌单要求/源弹层，再记录计划与ADR-063后实现。

## 本批交付

- 在既有Phone底部面板与Tablet/Windows对话框加入“新歌单名称 / 新建并添加”，
  复用YYTextField、YYButton、原始plus SVG及现有Token。保留App.tsx最终NEW_ICON_SPRITE/POLISH_CSS和
  基础HTML新建歌单入口的设计依据，不使用WebView、新图标或默认Material/Cupertino控件。
  figma-design-to-code按离线原始资产/组件复用要求执行；ZIP无fileKey/nodeId，未伪造在线Figma读取。
- Repository增加createPlaylistWithEntry合同；父歌单和position=0的首条引用在同一个SQLite事务中创建。
  与单独创建共用名称、系统身份和父ID校验；entry ID全局碰撞失败，不覆盖现有记录、不自动重试。
  任一插入/校验失败回滚全部新记录，不串联UI层create与append，不用补偿删除伪装事务。
  完整TrackRef、描述、时间与软引用保留；同名歌单和重复引用可分别寻址，不要求来源或歌曲当前存在。
- 根PlaylistController生成各一个父ID/条目ID和一次UTC时间，调用一个Repository命令，
  共用busy、脱敏结果、离页entryFailure和有序关闭；选择会话复用已有“先登记，再通知”的接受写入路径。
  实际事务未结束前根不会释放数据库，弹层关闭也不取消已接受的写入，不创建额外播放器或存储。
- 名称与筛选词是独立草稿，显式操作，不将筛选输入自动用作名称。
  活动路由、当前TextEditingValue、原生IME组合、名称策略与根busy共同阻止错误提交；
  旋转、跨Phone/Tablet断点、零尺寸和低视口键盘保留名称/选择范围/组合状态。
  已有列表读取失败不会伪装成空成功，但创建不依赖其快照，允许独立尝试事务并按真实结果反馈。
  失败保留草稿，明确重试后才再次写入；离页失败返回音乐库仍可见，不泄露异常原文。

## 验证与复查

- **754/754 Flutter**，新增36项：18 SQLite/Fake合同及真实事务关闭、9根命令/选择会话、
  8三端Widget、1真实SQLite全根界面。覆盖身份/系统/名称、来源隔离/失效软引用、并发同父仅一次成功、
  watch不暴露半成品、父插入/条目插入/插入后故障回滚、根busy/同步关闭重入/离页错误、实际事务排空。
  真实SQLite界面测试在首条插入后注入失败，确认父子均不存在；去掉故障并由用户操作重试后，
  仅存在一个完整父子对，原Track路径不变，音乐库可见，无音频调用。
- **81张Golden**，仅3张歌单选择器因新增名称表单更新，逐张查看，其他78张字节不变。
  130%文字下Phone/Tablet深色/Windows名称输入、创建按钮和取消可见，无溢出；阈值未放宽。
- **94/94 Node**，新加2项原子合同/原生草稿门禁；既有条目事务数断言从3更新为4，仍禁止整表替换。
  严格analyze零问题，323个Dart文件format零修改。
  build_runner、make-migrations后生成代码、Schema、迁移测试和lockfile无差异。
  五份源指纹、ZIP24项逐字节、六个音频包LICENSE及原生完整材料校验通过。
- Android本地Debug预检通过（Gradle18.8秒），48份资产逐字节、完整NOTICES.Z/原生材料和v2单签名通过。
  APK 231,895,682字节，SHA256 `0b46dca811a814d7b890696a0731104b712c53bde559884c50be5fc963c99300`。
  APK/日志仅在忽略的build目录，不入Git，不用本地预检代替用户要求的GitHub构建；JDK警告未被隐藏。

首轮界面测试发现旧测试的两种假设不成立：原生单行输入会过滤换行；固定12次Tab在增加控件后可落到取消按钮，
Space合法激活取消，随后Esc当然会退出下层页面。定位记录已移除；没有为测试禁用正确键盘行为。
测试现明确调用SDK requestScopeFocus停在作用域，保留未消费Space不泄漏到后台播放器的检查，
并额外验证输入框Space与Esc/原行焦点恢复；非法原始名称另通过直接草稿赋值测试。
第一次全量仅3张上述旧Golden失败，检查更新后754项完整通过。

## GitHub与下一步

H6精确提交 `b2845a3b23852deb01f41538f4d79cc18a7a2076` 的
[push34215507725](https://github.com/Z-YO-YI/YYMusic/actions/runs/34215507725) 与
[PR34215576065](https://github.com/Z-YO-YI/YYMusic/actions/runs/34215576065) 标准三job全部成功，
Draft PR #51保持OPEN、未合并；本批回填其报告，明确Windows开发包而非通用安装程序。

本批审查后提交推送stacked Draft PR，base=`codex/playlist-add-picker`；对应PR记录本批精确提交、
push/PR源码与Android/Windows结果和Windows artifact，不以前置/本地成功冒充本批云端通过。
普通push仅上传保留14天的Windows开发Debug包，普通Android job构建验证但不上传APK；
专用音频/Profile/Release未触发。无合并、历史覆盖、全局安装、用户凭据/数据/构建产物入库。

下一步仍在Phase6：播放全部/随机、系统歌单和大歌单内容完整浏览，之后Local Music/Settings。
默认新安装空库、尚无真实导入，完整播放器/歌词、REST、平台媒体和正式发行仍待后续阶段；
Windows本机C++/Debug CRT限制、HTML网页截图对照和设备验收未被本批替代，不声称应用已上线。
