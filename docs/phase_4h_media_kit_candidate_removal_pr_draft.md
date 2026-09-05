# PR 草稿 — Phase 4H 移除被拒绝的 media_kit 候选

PR：<https://github.com/Z-YO-YI/YYMusic/pull/24>

## 摘要

- 从当前pubspec/lockfile、适配器、测试、CI和双平台生成注册删除Phase4G已拒绝的media_kit候选；保留Git历史与完整原生审计证据。
- 历史manifest固定为`blocked`/`rejected`/`activeDependency=false`，门禁拒绝依赖、源码、CI、生产接线和APK原生库回流。
- Android干净Debug不再包含libmpv/helper，体积由279,085,047降至194,098,216字节；just_audio候选和生产Unavailable状态不变。
- 补齐`refactor/**`、`docs/**` push CI触发，确保Windows portable artifact可供清单复核。
- Windows构建在artifact上传前运行专用bundle verifier，缺少可执行/Flutter资产或出现libmpv/media_kit文件即失败。

## 影响范围

- 删除2个media_kit适配文件、5项Fake测试、2个历史集成测试、4个media_kit POC job。
- 移除2个直接依赖与11个专用传递包；不改UI、路由、数据库schema、权限、生产Bootstrap或Release策略。
- 保留Android debug-only Provider、短期TLS生成器和HEAD探针，供后续受控来源验证复用；它们不进入生产。

## 本地验证

- Node：35/35。
- Flutter：227/227；严格analyze 0问题；152文件format 0变化。
- build_runner/Drift：生成完成且受控输出零差异。
- 原始设计ZIP：24/24逐字节一致。
- Android干净Debug：194,098,216字节，SHA-256 `4f36802c6807371c383d91e9a69d320ada0f0857caa4da45f1637ba005241e69`；48项资产、0项media_kit原生库、v2单Debug签名通过。
- Windows本机：Developer Mode关闭，插件symlink门禁失败；不伪装为本机构建成功，交由GitHub Windows 2025验证。

## 发布与注意事项

- 这是候选清理，不是正式backend选型；Phase4F Windows真实播放端点仍未通过，Phase4/Phase5状态不变。
- 普通push/PR不创建Android Release；PR artifact应为0，push仅保留14天Windows Debug审查包。
- 不提交JAR/SO/DLL/7z、源码clone、音频、证书、私钥、Token、`.env`或本机构建产物。

## GitHub验证

- 目标提交：`2ec37ef02a37254d290cb084d200d5f4eacaf0c2`。
- push运行33946021637与PR运行33946023102：checks、Windows Debug、Android Debug全部success；手动just_audio jobs skipped。
- PR artifact 0、匹配Release 0；push Windows artifact ID `9963448349`，66,407,581字节，保留14天。
- 下载ZIP SHA-256 `e2e0acff719ec63a84861db2bc7582ff25c86bbd65c04f72ca414fa4caecc4826`与API digest一致；64项文件中所需应用/Flutter资产齐全，libmpv/media_kit为0。
