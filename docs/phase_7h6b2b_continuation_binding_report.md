# Phase 7H6B2b：自动继续生产持久化接入

## 本阶段目标与来源

继续H6B2a，基线312c399，独立分支codex/continuation-persistence-binding。开始前确认Z-YO-YI/YYMusic、干净工作区、fetch及ff-only pull，无远程差异。遵循主开发指令、ADR127、H6B1仓库约束，以及HTML autoplayToggle“从当前队列自动播放下一首”的语义；设计仍为基础HTML与App.tsx NEW_ICON_SPRITE/POLISH_CSS合成，不改参考源或UI。

目标为应用启动真实读取、用户选择保存及退出等待；风险是异步读取覆盖新选择、读取损坏数据时误写默认、关闭期间丢写入。出口是根/数据范围实际绑定，真实SQLite重开与关闭屏障验证通过，无音频自动启动。

## 实际修改

- 新增ContinuationPersistenceController，借用PlaybackController及PlaybackContinuationRepository；不直接依赖Drift或音频插件。
- AppDataServices新增专用仓库契约，DatabaseAppDataServices创建并销毁Drift适配，不改schema。
- DependencyGraph创建唯一协调器，在业务界面前初始化，根播放销毁前冻结意图，数据库释放前等待协调器排空；独立仓库注入与完整数据范围互斥。
- PlaybackController增加只读意图revision，复核相同值选择；不改变H6A自动完成策略计数。
- 新增Fake仓库、协调器/生产数据库测试与源码门禁；更新Bootstrap Fake及两处精确启动/关闭顺序断言，不削弱门禁。同步ADR128、README、状态与测试矩阵。

## 行为与安全

构造时先捕获一次性恢复许可。initialize幂等，缺失不写默认，坏记录/读取失败保留并反馈固定安全错误，不输出原始内容。晚到读取先复核意图；恢复不触发play、seek或load。通知期间的新选择优先，单纯关闭不把恢复误认为用户修改。

未来设置UI通过setEnabled提交显式选择，包括相同默认值；retry必须携带当前错误身份，旧错误不能重试或清除新错误。普通播放通知不触发偏好写入/反馈通知。直接根同值选择在读取、重试或关闭时仍会复核，但UI应走协调器以即时保存并更新反馈。

保存串行处理最新意图，已接受旧写入完成后保存最新值，失败显示可重试错误。close同步停止接受选择、冻结期望值并等待读写排空；未保存失败必须报告，不伪称落盘。协调器不关闭借用仓库或播放器；数据范围最终关闭适配器及数据库。

## 测试与构建

新增19项协调器测试，3项生产SQLite测试：同一文件三次打开经生产图恢复false/true；损坏记录在启动后保持原字节，只有显式选择才替换；阻塞SQL写入时graph.close不能提前关闭数据库。临时文件清理限定于本测试创建并验证位于系统临时目录内的目录。

初轮测试缺少Drift扩展导入，后续新增损坏测试又出现同名matcher导入冲突，均修正后重跑；初轮源码门禁也发现旧启动序列需要明确纳入新增恢复步骤，已更新精确断言。失败轮不记通过，不删除测试或关闭Lint。

最终2340项Flutter测试全部通过（122秒），161项Node源码门禁通过（20.18秒），595个Dart文件格式零修改，严格分析0问题（11.3秒）；Android Debug构建通过（103.2秒），48资产指纹、六项音频许可与完整原生声明通过。以上测试进程均确认退出0。现有Java native-access及SDK XML版本警告未处理，不擅自升级SDK/依赖。git diff --check通过，变更文本凭据/私钥模式扫描未命中。

ZIP、App.tsx、基础HTML与主指令SHA256匹配已审计基线，24个解压文件逐字节匹配；220张Golden不变。无WebView、无新图标、无下载操作或凭据提交。

父312c399的GitHub运行34747845051已success。本地Windows构建未运行：既有Developer Mode/symlink限制未变；本提交由GitHub Actions单独验证Windows与Android，不以父构建代替当前结果，不宣称真机听感或安装验收。

## 交付与下一阶段

本批单独commit/push并创建基于codex/continuation-restore-permit的Draft PR，不自动合并或发布。H6C接入设置开关、保存/错误/重试反馈并完成三套布局验证。此时仅生产启动读写已接通，用户界面尚无该开关；Phase7仍未整体结束，Phase8–11及上线验收仍待完成。
