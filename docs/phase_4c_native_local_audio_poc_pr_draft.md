# PR 草稿：Windows/Android 原生本地音频运行 POC

Head：`feat/native-audio-local-poc`；Base：`feat/media-kit-audio-poc@e1c50ca`。
创建为Draft，不自动合并、不改写历史。

## 变更

- 运行时生成固定3秒PCM16单声道WAV；不提交音频二进制、用户音乐或路径。
- Windows/Android使用同一Flutter集成测试真实创建候选Player，覆盖load不自动播放、duration、
  play/position、seek、pause、volume/rate、completed、stop与dispose。
- 新增只允许手动触发、全局`contents: read`的双平台native POC工作流；Android emulator action
  固定完整SHA，不上传artifact、不创建Release、不使用Secret。
- 生产入口、Shell、权限、数据库Schema和可见UI不变，正式AudioEngine仍不可用。

## 测试

- 2项WAV生成器测试通过；固定96,044字节和SHA-256
  `571edd11f9568729867f4a1db7b5f4318e3868024e41253f5c5ca4a09787d51e`。
- 149文件format 0变化、严格analyze 0问题、完整221项Flutter含32张Windows宿主Golden通过。
- 31项Node、24项ZIP通过；lockfile严格复现，build_runner/Drift后g.dart/v1快照零差异。
- 本机Android Debug成功；279,083,994字节APK的48资产和v2单Debug签名通过，诊断SHA-256为
  `91bee6ec8cc76c324bf009e011a9dd38658bdbbf3f7e32971489af604caa065e`。
- GitHub标准双平台构建和专用Windows/Android原生运行待实现提交推送后填写。

## 影响与未验收项

本批不改变正式应用行为。无头runner的position/completed不能证明实体扬声器、音质、真机、后台、
焦点、媒体会话或设备切换；本批也不覆盖Android `content://`、SAF、受控HTTPS/Header及失败矩阵。
native LICENSE/NOTICE链仍未闭合，候选不进入生产组合，本PR不触发手动APK Release。
