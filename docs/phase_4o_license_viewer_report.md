# Phase 4O — 原生许可查看入口报告

2026-09-05，分支 `codex/audio-license-viewer`，基于已 pull 的 `f324ed2`。
前置 Phase4N 两组云端三 job 均成功，证据已补入其报告。

## 实现与检查

新增 Domain `SoftwareLicense`/`LicenseRepository`、app 层 `FlutterLicenseRepository`、
设置共用 `LicensesScreen`、根路由/依赖注入与“开源许可”按钮。接口先记录于 ADR-043。
SDK LicenseRegistry 按需读取，不联网；保留没有组件标签的 SDK 原文组，不因空标签丢弃全文。
原生 JSON 验证范围、条目唯一、文本字节/SHA256 和引用；51 个坐标对应三份完整文本。
读取有超时/大小/条数限制，失败只给固定诊断，不把内部路径或异常内容暴露给用户。

页面使用已有 YY 主题/按钮/搜索/弹层：可搜索组件、查看完整原文、返回、关闭或 Esc 退出原文层、
失败重试；加载过程不重复请求，离开后不修改已销毁 Widget。不用 Material 默认页面或 WebView。
Android Phone 用 BottomSheet，宽屏用 Dialog，长原文可滚动；标记 Android 原生材料的适用范围。
没有增加依赖、网络/磁盘媒体访问、凭据、系统权限、Schema 或播放状态副本。

测试发现并修复重试的 setState 回调误返回 Future、旧错误在等待重试时继续显示、
SDK 无归属文本组被拒绝以及许可弹层未继承打包字体。没有关闭检查或放宽像素容差。

## 验证结果

- Dart format：168 文件零改动；严格 analyze：0 问题。
- Flutter：270/270，包括 6 个许可单元、6 个 Widget 场景、3 张新 Golden；总 35 张 Golden。
- 新视觉基线：390×844 浅色列表、1024×768 深色列表、1440×900 完整原文弹层。
  逐张查看，修正字体后重新查看和非更新复测；旧 32 张未改。另测 844×390 横屏与 130% 字号。
- Node：56/56；git diff --check 通过，依赖锁文件未改。
- build_runner 成功，内部缓存输出 64 项；跟踪生成代码/Schema 无 Git 差异，不把缓存输出数写成零。
- Android Debug：成功；48 设计资产、六个音频包 NOTICES.Z、原生许可资产均通过包内校验。
  APK 231,001,811 字节，SHA256 `0bfd62926c45ec6b3f83ad001c646d6f0bb1298b1536ebf769ad8d3c67aff042`。
  apksigner 验证 v2 有效，1 个 Debug 签名者；没有新发行签名。
- Windows 本机未重新构建/运行；GitHub 精确提交的 Windows Debug 已通过，不能用 Golden 替代。

实现 `60a79c7af54b30c9af09e883149fef27fdd8ed29` 已推送，Draft PR #31 未合并。
push [33959483011](https://github.com/Z-YO-YI/YYMusic/actions/runs/33959483011) 和
PR [33959503666](https://github.com/Z-YO-YI/YYMusic/actions/runs/33959503666) 均完成 success：
checks/Android Debug/Windows Debug 全部通过；原生 POC skipped，不算新的播放运行。
没有手动触发发布或创建 Release。
这不是完整设置业务页、整体发行许可批准或应用上线；releaseApproved 仍为 false。
生产仍为 UnavailableAudioEngine，下一批继续最终工程选型与真实音频根接线。
Phase2 网页截图对照仍欠验收，不声称新增 Golden 与网页逐像素一致。
