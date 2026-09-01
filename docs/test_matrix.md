# 原生基础验证矩阵

保留Phase2G的104项Flutter检查，Phase2H新增状态Widget6项及Golden3项，共113项Flutter、28项Node；不包含网页视觉对照、真实异步业务、音频POC或用户音乐数据。当前结果集中在phase_2h_state_surfaces_report.md。

| 类别 | 已有自动检查 |
| --- | --- |
| 源身份 | ZIP/App/HTML/package/master 五份指纹；24 个 ZIP entry；44 SVG、81/203 Polish、合成确定性 |
| 原型保留 | 13 个归档文件的大小/SHA-256 和完整文件集合 |
| 代码边界 | 无 WebView/HTML 嵌入、无 Gradient/旧原型导入；注入/路由库局限 app；Shell 不创建业务 Controller |
| 布局单元 | Windows 1440/1439/1024/1023/599；Android 599/600/正方形/844×390/1024×768/大竖屏；非法约束、非支持平台 |
| 根状态 | ProviderScope 内单一 graph；无后端不伪播放；音频事件/错误；取消订阅与只销毁一次；按路由存偏移/选中 |
| Widget | Windows 1440/1024/840/599实时切换且始终Windows，240/72侧栏与320 Inspector条件正确；Android Phone/Tablet/横竖屏实时切换；route/controller/position/selection不丢 |
| 导航 | player→lyrics返回player；主页面→lyrics返回主页面；系统pop/Esc；直接lyrics回home；未知路径不显示敏感query |
| 滚动 | 实际拖动、切主路由再返回、Phone→Tablet后的合法范围内偏移恢复 |
| 无障碍 | 360宽+130%文本、Semantics标签、按钮命中区>=44、点击导航 |
| CI 配置 | YAML真实解析、三个job、构建依赖checks、固定SHA与contents:read、SDK与pubspec一致 |
| Phase2A资产 | Google Fonts固定提交/大小/SHA/OFL、44SVG枚举全覆盖与真实解码；pubspec严格assets白名单、无默认Material视觉/网络字体 |
| 外观 | 五预设+216自定义色网格的正常/按下/浅深文字对比；非法HEX不改状态、System亮度/减少动态、会话通知 |
| 原生控件 | 键盘/指针动作、语义、44dp、选中、Disabled/Loading、Hover/Pressed/Focus、Reduce Glass几何保留 |
| 跨平台 Gallery | Android返回和根状态保留、真实字体130%手机/平板/横屏尺寸、示例动作与HEX校验；Windows同一路由保留Shell并展示明确标注的Chrome Fixture |
| Android原生导航 | Phone64/32、Tablet72及3×18条、低高度滚动、键盘/语义/Disabled、低对比色边界；599/600/1280/844横屏、SafeArea和根图保留 |
| Slider | 3/14/44几何、两端/步进、预览/单次提交/系统取消、纵向滚动不改值、RTL/键盘/语义、禁用/Loading/零范围/拖动中禁用、ReduceMotion |
| Artwork | 七种最终CSS背景真实像素、48/96/192尺寸、10/20/26圆角、image语义、local accent更新与Gallery本地数值 |
| Phase2C输入 | Switch几何/语义/键盘/RTL/取消、分段可滚动与单次选择/焦点可见、IME组合区/提交/清空、复制粘贴替身、禁用/Loading/错误公告、外部状态所有权、130%/360/600/键盘insets |
| Phase2D内容组件 | Album/Track几何、Hover/Pressed/Focus/Disabled/Selected或Playing/Loading、主动作与更多动作分离、键盘/语义、130%/390/600、Phone隐藏时长与长来源省略、Gallery仅本地状态 |
| Phase2E Windows Chrome | 42工具区、240/72侧栏、3×18选中条、Profile/Source状态、Hover/Pressed/Focus、Tab/Enter、Tooltip、独立窗口Fixture动作；正式Shell无假窗口/在线状态 |
| Phase2F播放器表面 | Mini64、Desktop88/76、封面54/50/48、视觉控制34/42与44命中；独立动作、语义/键盘、进度预览/提交/取消、音量、低宽降级、Loading/Disabled；不调用音频/队列/系统/持久化 |
| Phase2G弹层原语 | Context Menu 224/244/20/7/44、Dialog 680/30/72、Phone Sheet、Toast 42/420/14；受控动作、禁用/加载、方向键/Tab/Enter/Space/Esc、焦点闭环/恢复、live region、130%与Reduce Motion；不插入业务Overlay/Route/计时器 |
| Phase2H状态原语 | Swatch 30视觉/44命中及指针/键盘/语义；Empty 28/16/24；Error 12/14/15与live region、独立禁用/加载action；Skeleton纯色/填宽/无渐变；Gallery只更新本地状态 |
| Golden | 保留Windows Shell及既有组件23张；新增浅珊瑚/深翡翠/自定义白ReduceGlass状态组件板3张，总计26张精确像素比较，旧基线不改 |

## CI

`.github/workflows/foundation.yml`：checks 在 Ubuntu24.04 跑 Node/PowerShell 源核验、Dart格式/严格分析/Flutter测试；checks 成功后独立 Windows2025 Debug 和 Ubuntu Android Debug 构建。push feat/fix、PR或手动运行触发，超时20/30分钟。Android执行验签/48文件比对/三文件白名单；只有手动workflow_dispatch在全部门禁后创建私有draft/prerelease，普通push/PR不创建下载产物。个人令牌不注入runner，checkout不保留凭据。

26张Golden按Windows宿主标记，Linux明确跳过（非静默通过），Windows job构建前执行`flutter test --tags windows-golden`；其余87个Flutter测试仍在checks执行。没有删除或跳过原有回归，CI自动发现新增文件。远程状态须按目标commit单独核验，本地通过不冒充远程通过。

云端交付增量：1项YAML门禁测试、4项Node元数据/拒绝本地打包测试。APK必须在build→signature→assets→package均成功后上传，不使用always/continue-on-error；metadata不复制环境变量或秘密，下载URL必须属于本run。4be8ba2的手动运行已完成既有交付复核；每个新commit仍须重新取得运行证据。

Phase2E实现提交86d5cf5的push运行33458611100、PR运行33458660012与手动运行33459298221均为三job success。手动运行的草稿Release三资产已下载，APK大小、SHA256SUMS、metadata、API digest及v2签名一致；此证据只适用于该实现提交，不扩展为本机安装或正式发布证明。

Phase2F实现提交a1eacd9的push运行33462315349、PR运行33462439635与手动运行33462929516均为三job success。手动运行的草稿Release三资产已下载，APK为175792949字节，SHA256SUMS、metadata、API digest与`df0b96062e96332206630ded3cc35117f244d31c079f2ec76c3f3b3d06a3254a`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2G实现提交a56d4aa的push运行33465720644、PR运行33465784721与手动运行33466396076均为三job success。手动运行的草稿Release三资产已下载，APK为175818389字节，SHA256SUMS、metadata、API digest与`836e97c46aef2ed0036aaec085b8fb6113beeb2fe363749a7dfa3e817f648a88`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Phase2H实现提交9f71d14的push运行33468979883、PR运行33469047182与手动运行33469832392均为三job success。手动运行的草稿Release三资产已下载，APK为175828689字节，SHA256SUMS、metadata、API digest与`b9494ff75b5176b97ac11360a4b496c5182acdc5b0e875087a25d299989f6231`一致且v2签名有效；临时副本已清理。证据只适用于该实现提交。

Actions 固定 SHA，来源为维护者公开 refs 和说明：[checkout](https://github.com/actions/checkout)、[setup-node](https://github.com/actions/setup-node)、[setup-java](https://github.com/actions/setup-java)、[flutter-action](https://github.com/subosito/flutter-action)。静态配置验证不代表远程工作流已经通过；私有 CI 结果必须可读取后才记录成功。
