# PR 草稿：just_audio 双平台原生运行比较

Head：`feat/just-audio-native-run-poc`；Base：
`feat/just-audio-native-poc@9b5558bd4ec7ae4ed708be7c50395e054d1673d4`。保持Draft，不自动合并、不改写历史。

## 变更

- 新增默认关闭、显式手动触发的Windows/Android `just_audio`本地WAV原生POC。
- 运行时生成3秒PCM16 WAV，不提交或上传媒体；显式关闭请求Header代理与Header能力。
- 覆盖load不自动播放、duration、volume/rate、play/position、seek、pause、completed、stop与dispose。
- 等待Windows惰性duration；修复WinRT插件在0/0状态提前报告completed的适配层归一化。
- Windows job启动音频服务并要求至少一个真实播放端点；无端点时以固定诊断失败关闭。
- POC继承`contents: read`，没有Secret、artifact、Release、APK/AAB、WebView、缓存或下载。

## 测试与远端结果

- 本地：format零变化、严格analyze 0问题、Flutter 232/232、Node 31/31、ZIP 24/24。
- Android Debug：279,085,047字节，SHA-256
  `bba16856f7cdbc3c909172cafa75ee07c345067cb50f66dcc6cfe21e9adbf601`；48资产匹配，v2单Debug签名有效。
- `037db44`的push运行33941592336与PR运行33941595645均完成checks、Windows Debug、Android Debug并成功。
- 专用运行33942090875：Android成功（load 596 ms、首进度68 ms、seek 9 ms、duration 3000 ms、completed）；
  Windows音频服务均Running但播放端点为0，按验收要求失败关闭。该运行artifact 0、匹配Release 0。
- 本机Windows同样没有播放端点，且Developer Mode关闭使Flutter在构建前拒绝plugin symlink；没有把该条件记为通过。

## 影响与未关闭项

生产仍使用`UnavailableAudioEngine`，可见UI没有播放能力变化。Phase4F未关闭，未继续无Header HTTPS或
Android `content://`小批。需要有真实播放端点的Windows环境重跑；在此之前`just_audio_windows`不能成为
正式backend。下一批只审计已通过受控双平台时钟POC的`media_kit` native分发与许可证，不提前生产接线。

