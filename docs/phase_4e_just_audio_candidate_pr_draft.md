# PR 草稿：just_audio + Windows WinRT 备用候选适配与打包验证

Head：`feat/just-audio-native-poc`；Base：`feat/native-audio-content-network-poc@3da2f61`。
创建为Draft，不自动合并、不改写历史。

## 变更

- 精确加入`just_audio 0.10.6`和`just_audio_windows 0.2.3`，记录六个新增解析包、Media3 1.4.1、
  Windows WinRT构建及包内许可证指纹。
- 新增项目自有JustAudioPlayerBackend与JustAudioEngine；插件只在单一playback backend文件，生产入口
  继续使用UnavailableAudioEngine。
- 映射Windows绝对文件URI、Android content URI及HTTPS瞬时来源；load不自动播放。
- Header能力必须显式声明，不支持时在插件调用前失败关闭；原始URL、Header与插件错误不进入状态或日志。
- 串行处理transport、Seek、音量、速率，保留未知时长并实现幂等释放；不增加缓存、下载或离线API。
- 为Windows跨盘符Pub缓存禁用Kotlin增量编译，补齐Windows插件登记及架构门禁。
- 仅对旧WinRT插件目标启用MSVC experimental coroutine兼容宏，保留其余目标的`/W4 /WX`。

## 本地测试

- 7项候选测试、完整232项Flutter含32张Windows宿主Golden、31项Node、24项ZIP全部通过。
- 152份Dart文件format零变化；严格analyze 0问题；lockfile可由Dart严格复现。
- Android Debug构建成功：279,085,047字节，SHA-256
  `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601`。
- APK的48份设计资产、0份参考源、SDK/包名/标签、v2单Debug签名通过；仅保留网络/网络状态和生成的
  not-exported receiver权限，没有存储、媒体、麦克风或通知权限。
- 本机Developer Mode关闭，不能创建Windows插件symlink；Windows Debug已由目标提交的GitHub Windows runner验证。
- 修复提交`a2b517b`的PR运行33936726367与push运行33936724989均为三job success；四类手动native
  POC job全部skipped。push只生成既有14天Windows Debug artifact，Android手动Release步骤skipped，
  匹配新Release为0。

## 影响与未验收项

正式入口和可见UI没有播放能力变化。本批只证明适配合同及双平台Debug打包。Phase4F才运行备用候选的Windows/Android本地WAV、无Header HTTPS和Android content URI；
Windows认证Header策略、实体设备、后台/焦点/系统媒体会话与最终NOTICE仍未验收。本PR不触发手动APK Release。
