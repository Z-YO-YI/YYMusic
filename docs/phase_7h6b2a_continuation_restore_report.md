# Phase 7H6B2a：自动继续启动恢复保护

## 目标与来源

接续关机前未提交的根恢复接口，不重建项目。核验开发主指令、Phase 0 指纹、H6A/H6B1 报告及现有根播放代码。HTML autoplayToggle 的“从当前队列自动播放下一首”是功能依据；App.tsx NEW_ICON_SPRITE/POLISH_CSS 仍为视觉依据，本批不改视觉或参考源。不使用 WebView。

开始前确认 Z-YO-YI/YYMusic、独立分支 codex/continuation-restore-permit、基线 8ace598，并 fetch/ff-only pull 父分支，远程无新增。保留本批三个未提交代码文件及用户其他工作。

## 实现与边界

PlaybackContinuationRestoreAction 为存储 I/O 前捕获的一次性许可。PlaybackController 每个根只发出一次，任何显式选择（包括与默认值相同）或关闭均撤销。isCurrent 不消耗许可，给后续读取失败重试保留复核能力；应用前先消耗，通知期间更新的用户选择和关闭优先，结果为 superseded。

显式意图计数与自动完成策略 revision 分离：相同值选择不会发布多余通知，也不改变有效的自动下一首策略。恢复只改偏好，不加载、暂停、seek 或启动音频；已完成曲目不会恢复播放，无音频设备也能恢复偏好。修改共用接口前补 ADR127。

这只是 H6B2 的根接口子阶段。**AppDataServices、启动读取/保存协调器、设置开关尚未接入，不能宣称应用重启恢复已可用。** 不新增无缝或响度标准化假开关。

## 验证

新增11项恢复许可测试，覆盖两种布尔、一次捕获/应用、显式默认值、改回原值、捕获前选择、关闭、通知重入选择/关闭、完成后不重播及无音频设备。关机前保留日志显示2318全量通过；恢复后修复3条静态规范提示，并重新验证最终代码。

最终591 Dart文件格式零修改，严格分析0问题（9.3秒）；160 Node源码门禁通过（46.24秒）。Android Debug重新构建通过（35秒），48资产逐字节一致、六项音频许可与完整原生声明验证通过。Java原生访问警告仍存在，未更改SDK/依赖。

最终Flutter全量2318项通过（109秒），进程退出0。220张Golden未修改。ZIP、App.tsx、基础HTML、主指令四个SHA256与已审计基线一致；24个解压条目逐字节匹配。git diff --check通过，变更文本凭据/私钥模式扫描未命中。

本地Windows构建未运行：既有Developer Mode/symlink限制未变，由GitHub Actions构建。父提交8ace598的运行34746874518已success，源码、Android、Windows均通过，可选音频探测跳过；不以父提交成功代替当前提交CI，不宣称真机听感/安装验收。

## 交付与下一步

本批单独提交并推送，Draft PR基于codex/continuation-preference-storage，不自动合并/发布。下一阶段H6B2b接数据范围和恢复/保存协调器：晚到读取不覆盖用户、缺失不写默认、坏记录保留并反馈、显式新选择才可覆盖、退出先冻结并排空写入再关闭数据库。之后H6C接设置UI。Phase8–11及整体上线仍未完成。
