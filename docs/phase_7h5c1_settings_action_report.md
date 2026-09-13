# Phase 7H5C1：根输出系统设置操作

## 范围

H5B2c已生产绑定输出观察与前台刷新，本批为其增加受控系统设置操作，供下一阶段Presenter/面板借用。AudioOutputController.openSystemSettings必须接收isCurrent页面/用户意图检查；不存在无参数自动启动入口，仍只调用原生Gateway的固定设置目标，不接受URI、设备ID或播放命令。

调用时先拒绝关闭、能力不可用和重复请求；登记Future与busy状态后等待本控制器读取排空，再检查当前能力与页面许可。许可回调异常安全拒绝，回调引起的关闭/能力撤销也复核。忙碌通知期间重入不能重复启动，未知路由但canOpenSettings为true仍可打开设置。

原生opened仅表示OS接受启动，原样返回；不会改写输出观察、不会声称切换成功，也不立即refresh推断变化，真正返回前台由上一阶段已有生命周期逻辑刷新。异常映射failed，允许用户显式重试；异步反馈由未来Presenter再次检查页面许可。调用完成后释放busy；关闭撤销排队操作，等待已接受的原生启动完成，然后根再释放Gateway。已被OS接受的启动即使此时页面关闭也仍返回opened，不能假称撤销了系统副作用。

## 验证与边界

新增15项操作单测和1项根关闭测试，覆盖正常/未知能力、失效许可及异常、重复请求、刷新后再验许可/能力、许可/通知重入关闭、能力撤销、启动排空、原生异常重试和unavailable。首轮含既有观察器/根共32项通过；追加用例纳入最终全量验证。

严格分析0问题（8.2秒），580 Dart格式零修改，160 Node通过（35.52秒），24ZIP条目逐字节匹配。没有改变主指令、App.tsx的NEW_ICON_SPRITE/POLISH_CSS、HTML、依赖/schema或生成输入；无Golden图片变更。本批没有真实打开系统设置、设备热插拔/听感或新安装验收。

最终2255 Flutter通过（117秒），Android Debug预检49.8秒；48资产、六包音频许可和原生许可校验通过。APK SHA256为0ea01f5169ca6d456edd574589011596969e9bf5778ed1583498aa1f9cfee72b；保留既有Java原生访问警告。Android/Windows本提交以GitHub Actions另验，不将父构建结果算成本提交证据。本地Windows已知symlink限制未更改。

## Git与下一步

开始前fetch/ff-only pull且工作区干净；基线b7ffb6f，分支codex/output-settings-action，Draft目标codex/root-audio-output。父运行34743761185现已源码、Android和Windows全部SUCCESS。提交前检查变更及敏感信息，不提交产物，不自动合并/发布。

下一阶段输出Presenter/面板：复用根观察器及本操作入口，显示未知/系统默认/实际路由来源、能力与忙碌状态，按有效页面许可反馈结果，完成三尺寸与Golden验证。目前仍没有可见输出面板或应用内设备切换功能；Phase7及Phase8–11未完成。
