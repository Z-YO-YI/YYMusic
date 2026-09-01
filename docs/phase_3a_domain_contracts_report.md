# Phase 3A — Domain 模型与数据合同报告

2026-09-01。开始前已fetch并确认`feat/cross-platform-queue-lyrics-primitives@3c09ed7`与远端0/0同步、工作树干净；从该提交创建`feat/domain-model-contracts`，未在main/master开发。阶段来源、范围和出口见[计划](phase_3a_domain_contracts_plan.md)。

## 当前实际进度

本批是Phase3首个小批次，只固定纯Domain模型、Repository/Gateway合同和测试Fake。Drift/SQLite、Schema、Migration、正式Repository、安全存储实现、Dev Fixture、Controller和UI接线均未开始；Phase4播放状态机保持原骨架。

## 实现与来源映射

1. Track保留稳定id/sourceId/sourceType，remote与Windows path/Android content URI互斥；TrackRef可在来源删除或文件失效后继续被歌单/收藏/历史引用。
2. QueueEntry拥有独立entryId、连续position和UTC时间，同一TrackRef可重复；QueueSnapshot验证唯一entryId/position及合法cursor，不复制HTML仅存queueIds的限制。
3. Lyrics区分plain/synchronized，验证成对时间、排序、翻译语言与不可变行；不复制网页按标题生成歌词或自动Seek。
4. MusicSourceConfig只保存无userinfo/query/fragment的HTTPS base URL、公开Header、相对endpoint、受限字段路径和credentialRef；秘密由SecureCredentialGateway隔离。
5. Library/Collection/Lyrics/MusicSource Repository只暴露项目自有类型；Fake覆盖分页、流更新、可用性、重复队列、歌词、来源和凭据替换。

## 本地验证结果

| 检查 | 实际结果 |
| --- | --- |
| 格式与严格分析 | 108个Dart文件格式无变更；`flutter analyze --no-pub --fatal-infos --fatal-warnings`为0问题 |
| Flutter完整回归 | 147项通过：Phase2J 131 + Phase3A模型/Repository合同16；既有32张Golden原样通过 |
| Domain不变量 | 不可变集合/JSON、local/remote引用、UTC、稳定ID、重复队列、歌词时序/翻译、来源HTTPS/Header/映射、凭据与失败脱敏、分页均通过 |
| Repository替换 | Library/Collection/Lyrics/Source/Credential Fake通过；DependencyGraph对Library Fake只释放一次 |
| 流时序修正 | 前两次定向运行暴露测试在broadcast订阅建立前写入而超时；改为显式StreamIterator先建立第二事件监听，16项随后全部通过，未把Fake改成缓存型伪流 |
| Node/源码门禁 | 新增Domain/UI依赖边界后29项Node通过；五份源指纹、44 SVG、52项派生产物和13个归档文件保持完整 |
| ZIP复核 | 24个entry与原始ZIP逐字节一致，包含隐藏文件 |
| 依赖与权限 | pubspec/lockfile、平台权限、机器环境、视觉基线和用户数据均未变 |

## 云端与限制

实现提交`8506afc030937ed2a18573ad3b490d7f57061cb5`的push[运行33480316280](https://github.com/Z-YO-YI/YYMusic/actions/runs/33480316280)与PR[运行33480358335](https://github.com/Z-YO-YI/YYMusic/actions/runs/33480358335)均成功；两组各自的Source checks、Windows Debug（含32张Golden）和Android Debug三个job均逐项确认success。

手动[运行33481171269](https://github.com/Z-YO-YI/YYMusic/actions/runs/33481171269)同样三个job全部成功，并创建私有[草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-f5b6c426f6491e3ebca0)。Release为draft/prerelease，标签`ci-debug-33481171269-1`，target commitish为完整实现commit；仅有`YYMusic-debug.apk`、`SHA256SUMS`、`build-metadata.json`三个白名单资产。三者已独立下载，metadata的repository、commit、run URL、attempt、Flutter3.47.2、Debug临时签名身份和APK字段均一致。

APK为175891537字节，本地SHA-256、SHA256SUMS、metadata及GitHub API digest四方均为`1500bd28956befbb697cbe160c388d25a1c900e6454b180bed4335aaec05b712`。Build Tools36.0.0验证v2为true，v1/v3/v3.1/v4为false，且只有一个Android Debug signer；APK中的44 SVG与4份字体/许可证逐字节匹配仓库，参考资料及私钥未打包。临时下载目录经解析路径、非重解析点和三文件白名单复核后清理，可从草稿Release重新下载。

本机Windows C++工具链仍受远程UAC限制，不声称本机构建或安装成功。测试Fake不进入正式Shell，也不证明SQLite Migration、安全存储、真实来源、搜索或持久化已完成。

## 主要文件

- `lib/domain/models/track.dart`
- `lib/domain/models/collection_models.dart`
- `lib/domain/models/lyrics.dart`
- `lib/domain/models/music_source.dart`
- `lib/domain/models/load_state.dart`与`domain_failure.dart`
- `lib/domain/repositories/`四类合同
- `lib/platform/contracts/secure_credential_gateway.dart`
- `test/support/fake_domain_repositories.dart`
- `test/unit/domain_models_test.dart`
- `test/unit/repository_contracts_test.dart`

下一批应独立核验数据库候选与官方资料，完成首版Schema/Migration及内存数据库测试；不得一次把正式Repository、Controller、UI和音频全部接入。Draft PR为[#9](https://github.com/Z-YO-YI/YYMusic/pull/9)，保持待审核且不自动合并。
