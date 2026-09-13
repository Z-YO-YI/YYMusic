# Phase 7H5C2：生产播放设置中的音频输出面板

## 设计与真实能力

按figma-design-to-code技能先读现有组件和本地合成来源；没有在线Figma节点URL，未虚构get_design_context结果。核对App.tsx的NEW_ICON_SPRITE（含i-speaker）及尾部sprite替换/POLISH_CSS追加逻辑，保留其对话框30px圆角、按钮/字体等已映射token。基础HTML optionsOverlay在睡眠定时前为音频输出，原两张设备卡是演示。依主指令第26节，不复制“本机扬声器/蓝牙耳机”模拟选择，而用只读观察信息和系统设置入口。

复用现有YYDialog/YYBottomSheet、YYButton、YYTypography、YYRadius及主题色，无Material/WebView、无新图标或伪设备资产。手机底部面板、平板/Windows居中对话框，标题为播放设置，副标题为音频输出与睡眠定时；正文滚动，完成按钮保持固定。只读信息不是可点击设备卡。

## 生产接线与交互

PlaybackPresenter借用根AudioOutputController；生产Bootstrap一直显式创建原生Gateway，Graph因此传入观察器，既有播放页、歌词页、Inspector的播放设置路由自动显示输出区。未注入输出平台的独立旧测试/展示Graph保持sleep-only表面；实际生产即便输出未知或设置能力false也显示说明，不能因未知而隐藏整区。

AudioOutputSection局部监听输出，busy/输出变化不会通过PlaybackPresenter重绘其他播放功能或使自己的在途页面许可失效。显示三类来源：未知、系统默认（不保证播放器实际输出）、实际播放器路由。当前Android仍unknown，Windows只在宿主确实读取到默认端点时显示systemDefault。

系统设置按钮根据真实能力/busy禁用。点击使用父播放设置的路由、TickerMode、焦点、尺寸与generation许可，并叠加组件generation；旧回调、父表面覆盖再恢复、关闭与Widget替换不能重新获得许可。调用前/原生提交前/反馈前复核；错误使用固定中文提示、可显式重试，不显示原始异常。opened只显示已请求系统打开，不写“切换成功”；返回前台由H5B2c自动重读。组件不关闭借用根，不改变音量、队列或睡眠状态。

## 测试与视觉验收

新增11项Widget测试：三类输出、能力禁用、真实按钮调用、异常重试、旧owner回调、覆盖/恢复、慢启动重复与关闭迟到，以及320×568手机/1000×500Windows下128字符标签的滚动可达性。生产Bootstrap既有双平台测试增加Presenter与根观察器身份检查。

新增3张Windows宿主Golden，130%字体：390×900手机未知、1280×900暗色平板系统默认、1440×650Windows不可用。已逐张实际查看PNG：信息来源说明、禁用提示、正文滚动与固定完成按钮可见，无溢出；旧217张Golden未修改，合计220张。不是原生设备安装截图或真实硬件路由验收。

测试清理最初停在真实/模拟事件区的流关闭等待，增加有5秒上限、必须实际完成的输出fixture清理器后，面板与新Golden共12项通过。初始并行追加测试因sqlite3.dll被全量测试占用而未启动，改为单个Flutter测试进程重跑；没有删除/绕过动态库或跳过断言。旧架构门禁明确增加Presenter的新参数，仍验证根只创建一个Presenter。

严格分析0问题（10.2秒），584 Dart格式零修改，160 Node通过（35.48秒）。首轮完整2267 Flutter通过（114秒），增加两项长标签压力测试后最终2269 Flutter通过（102秒，不更新Golden模式）。Android Debug预检28.5秒，48资产/六包音频许可/原生许可校验通过，APK SHA256 af9392b63b01ffb6ab43c15505ec5a27612bd7e3b453727524a14081998e003a；既有Java原生访问警告保持。

ZIP/主指令/App.tsx/基础HTML四个SHA256仍匹配既有Phase0基线；24ZIP条目逐字节验证通过。没有依赖/schema/代码生成输入变化，无需迁移生成。本地Windows构建仍受已知symlink环境限制，本提交双平台打包由GitHub Actions另验。

## Git与下一步

基线ab29b7f，开始前fetch/ff-only pull且干净；分支codex/audio-output-panel，Draft目标codex/output-settings-action。父运行34744526576源码、Android和Windows全部SUCCESS。不得将父结果冒充本提交；不自动合并或发布。

本批输出设置已生产可见，但真实设备设置返回/路由和听感仍待验收。下一步审计Phase7剩余播放偏好（无缝、响度标准化、自动续播）的平台能力与可实现范围，不提供无效开关；随后Phase8–11继续。整体未正式上线。
