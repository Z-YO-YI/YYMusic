# Phase 7J13E：Windows唯一播放根验证计划

2026-09-19，基线4380386，Z-YO-YI/YYMusic、codex/native-repeat-window、Draft PR #136。J13D的Windows引擎序列本机实测已经通过，前缀38ms真实归零，详见[D报告](phase_7j13d_windows_prefix_fix_report.md)。不重做该补丁、已完成的循环/随机算法或Android A/B探针。本文件只确定下一可独立验证增量，尚无新增实现或设备通过数。

## 缺口与最小范围

实施补记：本计划已进入E实现与全量回归，详见[E报告](phase_7j13e_windows_root_report.md)；下文准备事项为原计划，未执行的Windows设备项目仍不计通过。

引擎探针没有证明真实PlaybackController的队列、历史与SQLite提交；Android A的顺序根和B的随机根分别有原生证据，Windows仍缺。本批先只补Windows顺序根：q0→q1→q0自然跨轮，native/root/persisted身份一致、历史去重更新，关闭自动继续后本曲结束不重启，数据库关闭重开不自动播放。Windows随机与更长窗口压力另批验收，不借Android通过替代Windows。

准备从既有Android顺序场景提取可复用的测试注册/观测逻辑；Android入口默认仍严格要求android，原输出标记、结果合同与宿主门禁保持有效。Windows另建默认关闭的Profile入口、独立purpose/结果文件和精确source=native SHA校验，不把旧单曲/序列探针或Android结果扩大为通用成功。只复用生产根、真实引擎和文件SQLite，不复制循环业务实现，不人工emit、seek或手动下一首冒充自然事件。

准备新增或修改：`integration_test/`内共享场景与Windows独立入口、结果/反例单测；`tools/`内独立元数据/宿主结果门禁及Node隔离测试；现有Actions增加显式互斥的Windows根模式；阶段报告/ADR。生产lib、UI、设计参考、NEW_ICON_SPRITE/POLISH_CSS及Golden保持不变；只有发现可复现产品缺陷才另行最小修复。

## 验证与边界

- 先记录ADR，保护旧Android合同并补错误平台、错SHA、缺指标、失败/跳过、额外测试、旧文件、超时及清理失败反例；跨平台参数不得容许宿主自报或伪造通过。
- 合成低幅WAV、应用音量0.05、仅探针自有临时SQLite；不访问用户音乐、改系统音频设置、再次重启服务/电脑或切换输出。
- 格式、严格分析、完整Flutter/Node、来源/许可/生产隔离、差异审查后提交推送；GitHub编译精确SHA的独立Windows Profile，同时复验既有Android A场景，构建与原生运行分开记账。
- 下载官方归档后核对digest、SDK、身份、路径及运行前后文件；在新隔离目录原样执行，超时只停止自身进程，不复用或修改旧运行证据。
- 全部成功只关闭Windows最小顺序根状态/持久化/恢复出口；不会声明听感无间隙、长时资源、真机后台、标准化、Phase7完整出口或Phase8–11及正式发布完成。不自动合并PR。
