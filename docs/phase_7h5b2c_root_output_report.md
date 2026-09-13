# Phase 7H5B2c：生产根输出观察与前台刷新

## 已接入的范围

AppBootstrap在创建音频引擎后创建平台输出Gateway，转交DependencyGraph所有。Android和Windows生产工厂均使用已实现的NativeAudioOutputGateway；直接创建测试Graph仍默认安全不可用实现。构造失败时Bootstrap释放已获取的Gateway、引擎和数据范围，逐项清理不因前项失败跳过。

Graph拥有一个AudioOutputController，在播放及睡眠恢复初始化完成后非阻塞启动输出观察；可选设备名称不延迟首个业务页面、不自动播放。关闭先同步停止观察器，再排空观察、关闭Gateway，随后释放引擎和媒体会话；原生关闭失败映射既有安全app.shutdown-failed并继续释放其余资源。

YYMusicApp沿用既有WidgetsBindingObserver，保存根观察器引用，仅非前台→resumed时refresh；重复resumed不重复读，卸载移除监听并清除引用，不在Widget内关闭根资源。覆盖从系统设置或其他应用返回的前台通知，但没有新系统设置界面入口；本批未注册设备热插拔通知。

遵循主指令第26节：Windows观察仍区分systemDefault与playerRoute，Android仍unknown；不切换设备、不改音量、不持久化设备名称。Presenter与输出面板下一阶段接入，不能把后台观察已绑定写成设备选择界面完成。

## 回归中发现并修复

观察器上一阶段用Future事件任务登记关闭，接入根后暴露界面销毁时零延迟Timer残留。改为Future.microtask，继续保证登记先于依赖调用，不增加Timer。专项覆盖原13项协调器、双平台生命周期以及原Android Golden，20项通过；没有更新Golden图片或跳过断言。

全量中首次启动测试有一次关闭等待失败，单独11项启动测试通过。既有closeGraph只允许12次事件循环，现改为最多5秒墙钟等待、每轮推进真实和测试事件，仍要求关闭实际完成并await原Future；不隐藏关闭失败。两项Node门禁精确加入audioOutput.dispose和新的初始化花括号，保留原歌词/收藏/播放顺序验证。

## 验证记录

- 新增6项根/工厂单测、双平台2项生命周期测试、1项启动工厂失败测试；既有双平台resize/所有权和构造失败测试增强，检查输出只创建/初始化/释放一次。
- 最终全量2239 Flutter通过（98秒）；严格分析0问题（13.9秒），579 Dart格式零修改，160 Node通过（19.77秒）。初始测试API误用、Timer残留和两项门禁不匹配均保留失败日志，不将失败轮记为通过。
- 最终Android Debug预检17.8秒；48资产、六包音频许可及原生许可通过。APK SHA256：0ca24c699d5215bee5e27e30cd154ba78517bd9455d2e1f35e93497d4a3c5006。Java原生访问警告保持，无新增真机安装/听感验证。
- ZIP、主指令、App.tsx、基础HTML四个SHA256仍匹配既有Phase0基线，解压24条目逐字节通过；未修改NEW_ICON_SPRITE/POLISH_CSS或引用输入。无依赖/schema/生成输入变化，无需重新生成代码。
- 父6345f49的GitHub运行34742660029已整体SUCCESS，源码/Android/Windows均成功。当前提交的云端原生构建须另验，本机symlink限制未更改。

## 同步与下一步

基线6345f49，开始前fetch/ff-only pull且工作区干净。分支codex/root-audio-output，Draft目标codex/audio-output-observer；不自动合并/发布，不提交构建产物或敏感信息。

下一阶段接输出Presenter及界面入口：未知状态、系统默认来源说明、固定系统设置操作与失败反馈；保留有效页面操作许可并做布局/Golden验证。Phase7其他播放偏好和Phase8–11仍待完成。
