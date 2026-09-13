# Phase 7J1：原生序列加载边界

## 来源与范围

基线3b3367d，仓库Z-YO-YI/YYMusic，工作区干净且fetch/ff-only pull后建立codex/native-sequence-backend。主指令、ZIP、App.tsx、基础HTML四项SHA256均匹配既有审计基线；设计合成中的NEW_ICON_SPRITE/POLISH_CSS未修改或绕过。本次纯播放底层增量，无UI改版、WebView、新依赖或数据库变更。

依据主指令播放能力要求与H4审计，按ADR132先补真实原生序列调用。读取本机锁定just_audio0.10.6及platform_interface4.6.0一手源码确认setAudioSources和事件格式，未据插件能力声称应用无缝完成。

## 实现

- 新可选JustAudioSequenceBackend复用PlayableSource，不修改AudioEngine或根队列协议。复制输入列表并整批检查初始索引和请求头能力，拒绝时不替换已有媒体。
- NativeJustAudioPlayerBackend调用真实setAudioSources，初始位置零；保留local/content/HTTPS与Windows路径编码。无主动play、无日志/持久化URI或请求头。与插件一致，替换时不自行改变既有playing状态，调用方必须先暂停并独占串行调用。
- 快照加入插件currentIndex并监听索引独立变化。该值不是应用queue entry ID，也不是声学边界测量；现有生产根仍用单曲load，不消费序列能力。
- 序列加载原生异常转换为固定StateError，异步错误继续只发void。关闭后拒绝新序列；单曲open可替换先前序列。修正旧POC注释，保留ADR044生产选型事实。

## 验证与限制

11项专项测试通过真实锁定插件的MethodChannel与EventChannel，不伪造适配器实现：三类源顺序、初始索引/位置、不请求play、只改变索引时快照更新且不reload、两种越界、空列表、后项头不支持时整批拒绝、输入列表与头快照、UNC/POSIX编码、单曲重置、加载错误脱敏/后续恢复、关闭后无原生调用。

初次严格分析指出测试多余dart:async导入，已移除，不关闭Lint。最终严格分析0问题（8.8秒），604 Dart文件格式零修改；2391 Flutter测试通过（112秒），161 Node门禁通过（30.40秒），进程均退出0。226张Golden未修改。

Android Debug构建通过（33.4秒）；48资产字节一致，六项音频许可与完整原生声明通过；24个解压文件与原ZIP逐字节匹配。既有Java native-access警告仍在。git diff --check及变更文本凭据/私钥扫描在提交前执行，不将产物加入版本管理。

本地Windows仍受既有Developer Mode/symlink限制，以GitHub正常Windows构建验证；不运行可选设备音频探针。通道测试不是Android/Windows真机听感，APK构建不是上线验收。

## 下一阶段

必须将序列绑定至根队列的entry身份/修订，处理自动继续关闭、睡眠本曲结束、重复/随机、失效跳过和过期来源；再显式验证原生曲间边界，才可暴露用户无缝开关。标准化仍需真实响度与削波策略，不能以setVolume代替。Phase7及总体上线目标仍未完成。

提交推送并创建以codex/queue-skip-feedback为base的Draft PR，不自动合并或发布，不提交构建产物。
