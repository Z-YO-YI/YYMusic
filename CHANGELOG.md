# Changelog

## 2026-09-01 — 私有草稿 Release APK 交付

- 8e6915a的GitHub运行已完成Android编译、Debug验签、48项资源比对及Windows构建，但Actions产物存储额度已满，未伪称存在可下载APK。
- 经用户明确允许，APK交付改为仅在workflow_dispatch手动运行时创建私有draft/prerelease；普通push/PR仍执行构建但不产生Release。
- Release只附加APK、SHA256SUMS及构建metadata，使用唯一run/attempt标签，不覆盖或删除既有资产；个人令牌不进入runner。
- 全局与非Android任务保持contents:read；Android任务单独申请contents:write，上传前的测试、验签与资源字节门禁不放宽。

## 2026-08-31 — GitHub Android SDK 工具路径修复

- 隐藏文件修复9f08a71已在Linux通过源码/分析/测试；随后Android在SDK安装阶段暴露sdkmanager不在PATH的问题（exit 127）。
- 从ANDROID_HOME显式定位并校验cmdline-tools/latest/bin/sdkmanager，保留JDK与三个固定SDK组件版本；不安装新的Action或批量接受许可。
- 新增1项真实YAML合同回归，记录首次失败与第二次云端证据；PR #1保持待审核，不自动合并。

## 2026-08-31 — GitHub CI 隐藏参考文件校验修复

- 首次获得远程运行证据：cafb942的ZIP校验读取隐藏`.gitattributes`失败，Android任务跳过、未产生APK；不把本地回归通过当作云端成功。
- `Get-Item -LiteralPath`增加`-Force`，只允许校验器读取隐藏文件属性；24份原始参考、ZIP哈希、文件数量和字节比对不变，没有跳过失败门禁。
- 新增5项实际执行PowerShell校验器的Node回归，在临时副本中覆盖隐藏文件、隐藏文件篡改/缺失/多余与ZIP改动；Windows显式设置Hidden属性以复现Linux故障。
- 不改Flutter业务、设计基线、依赖、签名或账号/仓库权限；云端复验与证据见docs/ci_reference_audit_fix.md。

## 2026-08-31 — Android Phase 2C 输入与选择

- 新增YYSearchField，使用原生EditableText/选择手势/工具栏，支持IME组合输入、搜索提交、清空、错误公告与只读加载/禁用；不访问真实音乐服务。
- 新增受控YYToggle、YYSegmentedControl，共用触控/键盘/语义处理；保留46/28/22开关几何、分段14/11圆角，触控不小于44dp，支持RTL/减少动态与焦点自动滚入视野。
- Gallery实际外观开关接入根状态，新增纯本地文本与筛选示例；未加入假搜索结果、数据库或模拟音频。
- 新增11项Widget与3张130%真实字体Golden，旧8张不改；总计74项Flutter及23项Node检查。APK不在本机重建，云端状态仍待授权核验。

## 2026-08-31 — GitHub Actions APK交付

- 按用户要求，APK交付改由GitHub runner编译；补齐原工作流缺失的验签、资产比对、APK/校验和/构建身份上传与摘要下载链接。
- 固定官方upload-artifact v7.0.1提交，14天保留、严格文件白名单、不覆盖历史、失败不上传；不提交本地APK或签名密钥。
- 新增4项打包元数据测试与1项真实YAML门禁测试；云端运行/产物仍待GitHub连接器仓库授权，未宣称远程成功。

## 2026-08-31 — Android Phase 2B 导航与媒体基础控件

- 手机64dp/32圆角胶囊与平板72dp Rail 接入原有四条路由；599/600实时切换、SafeArea及根状态保留，Windows骨架不变。
- 新增原生受控 YYSlider：3dp轨道、14dp滑块、44dp命中区，拖动/取消、键盘、RTL、语义增减及Disabled/Loading；修复系统取消被识别器当作结束而误提交的问题。
- 新增七种 CSS 几何封面占位，采用 App.tsx 最终配色/尺寸与原生绘制，保留固定px偏移；Gallery只展示明确标注的示例，不伪造曲库或播放。
- 自定义低对比度强调色保留原值，仅增加可读导航边界；不改变正常珊瑚/深色翡翠基线。
- 新增14项Widget与5张Golden，保留既有40项回归和3张原始基线；无新增依赖、权限、系统安装，完整验证见Phase2B报告。

## 2026-08-31 — Android 优先 Phase 2A 设计基础

- 按用户最新要求先推进 Android；Windows 工具链与原生验收暂缓，保留 runner、布局分类和 CI，不标记整个 Phase 2 完成。
- 新增语义 Token、Light/Dark/System、五种预设及自定义 HEX；原色保留，文字/前景另行派生满足对比度的颜色；根 Controller 持有会话级外观。
- 按 App.tsx 原始 Sprite 接入44个 SVG，保留 POLISH_CSS 的字体、双环44dp账户头像、圆角与阴影；打包固定提交的 Inter / Noto Sans SC 及 OFL，不安装系统字体。
- 新增 YYButton / YYIconButton / YYSurface / YYGlassSurface / YYProfileHeader 和 Android 设计预览入口；触控、键盘、语义、减少动态/透明可验证，无 WebView、默认 Material 外观或假播放。
- 新增字体资产与架构检查、主题/对比度/控件/导航测试，以及3张原生 Golden。40项 Flutter 测试通过；Android Debug APK 构建及签名校验通过，未进行真机或网页像素一致性验收。

## 2026-08-31 — Android 工具链与 Debug 构建通过（Windows 待确认）

- 用户确认后复用现有 Flutter / Android Studio / JDK，仅补 Android 命令行工具 22.0、API 36 与 NDK 28.2.13676358。
- 配置用户级工具路径，统一 ADB 来源；原环境设置保存在本地忽略目录，未删除旧工具。
- 校验官方 Android ZIP 哈希和微软安装程序签名；Windows C++ 安装等待系统 UAC 确认，不绕过管理员权限。
- 记录安装范围、恢复方式及实际测试/构建状态，不改变设计参考、业务代码、项目依赖或发布签名。
- Android Debug APK 构建及签名校验通过；format/analyze、24 项 Flutter 测试、15 项 Node 测试和 24 个 ZIP entry 核验通过。Windows 尚未安装完成，不标记 Phase 1 全部完成。

## 2026-08-31 — Phase 1 工程骨架（构建出口待验证）

- 将旧 Sonic Gallery 的 13 个文件原样归档并单独提交，增加指纹测试。
- 使用 Flutter 3.47.2 创建 Android/Windows 原生 runner，品牌改为 YYMusic，不使用 WebView。
- 增加平台优先分类、三个空 Shell、根依赖注入、播放生命周期边界和独立 player/lyrics 路由。
- 增加分类、状态/滚动保留、路由返回、无障碍和 CI 配置测试，启用严格静态分析。
- CI 配置源码审计、分析/测试、Windows/Android Debug 构建；Action 固定 SHA、仅 contents:read。
- 本机 Windows 构建缺 Visual Studio；Android 工具/许可待确认，双平台出口未完成，不进入 Phase 2。

## 2026-08-31 — Phase 0 设计审计

- 校验 ZIP、App.tsx、基础 HTML、package.json 指纹，并锁定主指令文档本次 SHA-256。
- 归档完整导出包，复现 Sprite → 账户替换 → Polish 注入的最终参考合成。
- 提取 44 个 SVG、全部 81 个 CSS 规则块 / 203 个声明，生成可复核清单及映射。
- 记录四个页面、七个 Overlay、交互与模拟行为、状态、持久化、16 个媒体查询及层叠冲突。
- 建立 Token、三套 Shell 边界、视觉验收计划、依赖候选证据和双平台音频 POC 计划。
- 提供零外部依赖的生成/检查工具和测试；未进入 Flutter 骨架、页面实现或音频 POC。
- 保留原有 Sonic Gallery 源码与测试不变；未将它们自动纳入新 Git 基线。
