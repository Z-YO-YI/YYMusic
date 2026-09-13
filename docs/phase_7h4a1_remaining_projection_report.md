# Phase 7H4A1：睡眠剩余时间根接口

2026-09-13；基线8e84f9aaf63f471eb611733c0cba7ecc696fb138，fetch/ff-only pull且干净；分支codex/sleep-remaining-projection，Draft base codex/playback-capability-audit。先[计划](phase_7h4a1_remaining_projection_plan.md)/ADR108，再只读API与测试。

PlaybackController.sleepRemaining仅在未关闭、armed分钟意图有效时使用既有注入时钟计算UTC截止差值，负值夹零；off/本曲结束/pausing/expired/failed返回null。零仅表示时间已到但业务回调可能尚未处理，不会因读取而消费意图或暂停。时钟回拨不重写截止，绝对时间语义保持不变。

PlaybackPresenter.sleepRemainingSeconds对微秒向上取整，不在小于1秒时提前显示结束；dispose后不读取根。查询无通知、Timer、音频命令或状态写入，原duration选中项与旧动作许可不被读操作撤销。**本批未接入界面刷新，§26“显示剩余时间”仍待H4A2，不声称UI倒计时已完成。**

18新增单测：off无时钟读取；三种分钟选项；1000001/1000000/999999/1/0/-1微秒边界；墙钟回拨/前跳；100次读取无业务副作用且原选择动作有效；重设/取消及旧Timer；暂停墙钟仍推进、本曲结束不伪造秒数；延迟回调处理到期；调度失败、Presenter/root关闭。无新Widget/Golden。

验证：完整1972 Flutter通过（112秒，211原Golden不变），153 Node通过（31.7秒）；543 Dart文件格式零修改，严格分析0问题（14.6秒）。build_runner52秒与Drift迁移通过，生成/schema无差异；四份设计原文件指纹一致，24ZIP条目匹配，音频源许可通过。

Android Debug18.6秒；48资产、完整音频许可、v2单签名者通过。APK232267353 bytes，SHA256 `dbb6da46418066b0776796fd9d4d36b9b73c597db399ca2d3cde39e352028272`；保留Java native-access警告，不提交构建产物。无新增设备安装/出声或本地Windows编译验收，Debug不是上线。

前置8e84f9a的push34728554610已SUCCESS，PR34728571947核验时仍in_progress；本批新SHA云端另验，不用前置成功代替。提交/PR精确链接在Draft，不自动合并或发布。

主要文件：playback_controller.dart、playback_presenter.dart、剩余时间单测/Node门禁及ADR/计划/报告/README/状态/矩阵。下一增量H4A2定义展示刷新生命周期，隐藏/关闭停止刷新、重新显示立即读取根，复用原睡眠面板并避免每秒读屏播报；恢复/淡出/输出设备/其余偏好与Phase8–11仍未完成。
