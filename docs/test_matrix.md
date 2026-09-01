# 原生基础验证矩阵

保留Phase2D的82项Flutter检查，Phase2E新增Windows Widget3项及Golden3项，共88项Flutter、28项Node；不包含网页视觉对照、真实音频POC或用户音乐数据。当前结果集中在phase_2e_cross_platform_report.md。

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
| Golden | 新增Windows 1440×900/1024×720/840×640三张；账户空格修正后审查更新旧浅/深组件两张；总计17张精确像素比较，旧Android导航基线不改 |

## CI

`.github/workflows/foundation.yml`：checks 在 Ubuntu24.04 跑 Node/PowerShell 源核验、Dart格式/严格分析/Flutter测试；checks 成功后独立 Windows2025 Debug 和 Ubuntu Android Debug 构建。push feat/fix、PR或手动运行触发，超时20/30分钟。Android执行验签/48文件比对/三文件白名单；只有手动workflow_dispatch在全部门禁后创建私有draft/prerelease，普通push/PR不创建下载产物。个人令牌不注入runner，checkout不保留凭据。

17张Golden按Windows宿主标记，Linux明确跳过（非静默通过），Windows job构建前执行`flutter test --tags windows-golden`；其余71个Flutter测试仍在checks执行。没有删除或跳过原有回归，CI自动发现新增文件。远程状态须按目标commit单独核验，本地通过不冒充远程通过。

云端交付增量：1项YAML门禁测试、4项Node元数据/拒绝本地打包测试。APK必须在build→signature→assets→package均成功后上传，不使用always/continue-on-error；metadata不复制环境变量或秘密，下载URL必须属于本run。4be8ba2的手动运行已完成既有交付复核；每个新commit仍须重新取得运行证据。

Actions 固定 SHA，来源为维护者公开 refs 和说明：[checkout](https://github.com/actions/checkout)、[setup-node](https://github.com/actions/setup-node)、[setup-java](https://github.com/actions/setup-java)、[flutter-action](https://github.com/subosito/flutter-action)。静态配置验证不代表远程工作流已经通过；私有 CI 结果必须可读取后才记录成功。
