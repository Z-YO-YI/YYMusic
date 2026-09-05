# PR 草稿：审计 media_kit 原生分发链并失败关闭

Head：`feat/media-kit-license-closure`；Base：`feat/just-audio-native-run-poc@4703c52`。保持Draft，
不自动合并、不改写历史。

## 变更

- 记录四个media_kit相关包和Android/Windows native产物的版本、尺寸、SHA-256、release与commit。
- 逐entry确认Android JAR→APK三ABI映射；确认Windows release DLL→Phase4C GitHub bundle字节一致。
- 从真实SO/DLL核对GPL/nonfree/LGPLv3+构建模式，不只相信wrapper许可证或历史脚本。
- 记录Android helper未固定、Windows未记录的workflow自定义命令/可变cache/浮动依赖等来源阻断。
- 新增机器可读`blocked`清单、CLI和四项反向测试；生产仍是`UnavailableAudioEngine`。
- 不添加不完整的应用许可证assets，不提交JAR/SO/DLL/7z/源码归档，不创建Release。

## 测试

- Node 35/35；Flutter 232/232；32张Windows宿主Golden；严格analyze 0问题；format零变化。
- build_runner、Drift迁移与生成文件零差异；原ZIP 24/24 entry逐字节匹配。
- Android Debug成功：279,085,047字节，SHA-256
  `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601`；48项应用资产匹配。
- 门禁提交`d33b2d0`已推送；目标提交的标准GitHub checks/Windows Debug/Android Debug结果在PR中更新。

## 影响与注意事项

本PR完成的是可复核审计和失败关闭，不是法律批准。当前media_kit native链仍不可作为候选Release：
Windows对应源码/构建变换无法精确重建，Android helper并未固定，两个上游归档都缺完整NOTICE、对应源码/
重新链接材料。正式选型、实体设备、生命周期、系统媒体会话和可发布许可证包仍是后续独立门禁。
