# Phase 7H4B3b：生产分钟定时持久化协调

基线154df75。SleepPersistenceController构造时捕获恢复许可、观察睡眠意图而非普通进度；仅有效许可恢复，用户变更优先。分钟armed保存原快照；off/本曲结束/到期清除分钟记录，本曲结束仍明确仅本次启动有效。

schemaMismatch坏记录（含未知版本）由协调层清理，不把I/O失败当missing。失败保留记录并反馈/重试；恢复失败或引擎不可用不自动播放。单worker协调最新意图，旧失败不得覆盖新成功。关闭先冻结观察并排空接受写入，再释放根/数据库，禁止把退出的临时off当用户取消。

接入AppDataServices/DependencyGraph创建和关闭顺序；Presenter只读反馈，原面板显示读取/保存/失败及受保护重试。无Repository环境继续session-only说明。复用本地导出和现有caption/YYButton，无在线Figma节点，不新增图标或WebView。

验证慢读期间取消/新设、普通通知、过期/坏记录、失败重试/旧失败、关闭保存、Graph+SQLite重开、无自动播放、面板旧回调和截图；完整检查后提交/推送Draft，不以测试替代实机验收。
