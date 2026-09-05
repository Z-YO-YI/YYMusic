# Phase 4P — 正式音频根接线

2026-09-05，基于已 pull 的 `60a79c7`；分支 `codex/production-audio-bootstrap`。
前置 Phase4O 云端仍运行，先准备同阶段改动；前置失败则修复，不宣布阶段出口通过。

依据 Phase4L 双平台真实来源证据、Phase4M/N 原文与实际包内核验、Phase4O 查看入口，
按 ADR-044 选择 just_audio/Windows WinRT 为当前工程后端，不等于批准整个应用发行。
先改公共合同：根部可注入 AudioEngineFactory、Controller/Graph 可等待 close，
平台明确的本地引用解析器。再接默认 AppBootstrap、保留开发 Fixture 的不可用后端。

实现只创建一个播放器，不自动播放恢复队列，不请求网络；Android content URI 优先，
Windows 本地绝对路径；REST 仍失败关闭到 Phase9 Adapter，不把 metadata 地址直接拿来播放。
Root 创建失败/异步到达已销毁页面必须释放所有已获取资源；关闭等待在途队列/媒体同步后再关闭数据库。
测试覆盖二次关闭、延迟 load、初始化和清理异常、根退出、路径平台差异与安全失败。
完成格式/静态分析/完整回归/生成代码/指纹、Android 本地和 GitHub 双平台 Debug 后提交证据。
不实现后台服务、SMTC、导入器、音乐页面、签名或发布；随后继续 Phase4 出口与 Phase5 Shell 接线。
