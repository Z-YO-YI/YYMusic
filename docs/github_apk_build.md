# GitHub Actions APK 交付

用户要求从本批起在GitHub上构建APK。正式下载入口改为[Native foundation工作流](https://github.com/Z-YO-YI/YYMusic/actions/workflows/foundation.yml)，本机旧APK仅是Phase2B历史验证产物，不再当作新版本交付。Actions产物额度已满，因此测试APK改存私有仓库的草稿Release，不发布为正式版本。

## 构建和下载

推送feat/fix分支或打开PR仍执行源码及原生构建，但不生成下载产物。需要APK时手动触发workflow_dispatch并选择目标分支；只有该事件会在所有门禁通过后创建`ci-debug-<run-id>-<attempt>`私有草稿Release。下载需要登录且具有仓库读取权限。

顺序：源码指纹/格式/分析/测试 → GitHub Ubuntu runner编译 → apksigner验签 → APK内48个原始SVG/字体/许可证比对 → 生成校验和/提交信息 → 手动运行时创建草稿Release。检查或构建失败时不上传APK，不使用continue-on-error或always掩盖失败；Windows job独立保留，不阻塞Android job，二者都依赖checks。

产物仅含：

- `YYMusic-debug.apk`
- `SHA256SUMS`：APK文件本身的SHA-256
- `build-metadata.json`：仓库、完整commit、run URL、attempt、Flutter版本、文件体积/哈希、Debug签名说明

草稿Release不自动发布，每次手动运行使用唯一标签且不覆盖既有资产；是否清理或发布必须另行确认。该metadata是构建记录，不是密码学来源证明。

`tools/android_artifact.mjs`拒绝普通本地打包，并核对checkout SHA与GitHub运行身份；工作流只从本次runner编译输出取文件。不会上传开发者电脑中的旧APK、整个build目录、环境变量、凭据或源参考包。全局及其他任务保持contents:read；Android任务单独使用contents:write，并且只有手动运行的末尾步骤调用runner自带GitHub CLI创建draft/prerelease。GITHUB_TOKEN仅限本仓库且随任务结束失效，不注入个人令牌。

## 签名限制

目前只构建Debug，未请求或配置Release签名。新runner默认debug key可能每次不同，也不同于旧本机APK；直接覆盖安装可能签名冲突。不要为更新而擅自卸载含真实数据的应用。稳定升级/发行签名需要后续单独配置受保护的密钥，绝不将keystore或密码入Git。

## 当前核验边界

2026-08-31：前两次核验分别暴露Linux隐藏文件和sdkmanager PATH问题。8e6915a的[第三次运行](https://github.com/Z-YO-YI/YYMusic/actions/runs/33415790519)已完成Android编译、验签、48项资源比对及Windows构建，但Actions返回artifact storage quota已满。用户在2026-09-01明确允许改用私有草稿Release；4be8ba2的首次草稿Release交付证据见[CI记录](ci_reference_audit_fix.md)。Phase2D实现提交9a3a345的手动[运行33455489191](https://github.com/Z-YO-YI/YYMusic/actions/runs/33455489191)三项任务全部成功，三个Release资产已重新下载并核对commit、run、metadata、SHA256SUMS、API digest和v2签名，证据见[Phase2D报告](phase_2d_android_report.md)。

Phase2E实现提交86d5cf5的手动[运行33459298221](https://github.com/Z-YO-YI/YYMusic/actions/runs/33459298221)三项任务全部成功；当前[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-5fff7c5595429dc428bf)仍未正式发布。三资产已独立下载，APK为175767817字节，SHA-256/API digest为`ee0030157e359d959373af760a09c4c23c7c6b7a0943a0771ecaf13bbd051a08`，metadata与完整commit/run一致且v2签名有效；完整证据见[Phase2E报告](phase_2e_cross_platform_report.md)。

Phase2H实现提交9f71d14的手动[运行33469832392](https://github.com/Z-YO-YI/YYMusic/actions/runs/33469832392)三项任务全部成功；[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-c5e2a9460a012a4acfc7)保持draft/prerelease且只含三项白名单资产。APK为175828689字节，SHA-256/API digest为`b9494ff75b5176b97ac11360a4b496c5182acdc5b0e875087a25d299989f6231`，metadata与完整commit/run一致且v2签名有效；完整证据见[Phase2H报告](phase_2h_state_surfaces_report.md)。

当前Phase3D实现提交9468c2a的手动[运行33496511117](https://github.com/Z-YO-YI/YYMusic/actions/runs/33496511117)三项任务全部成功；[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-b67861d16f9671c7c750)保持draft/prerelease且只含三项白名单资产。APK为183604101字节，SHA-256/API digest为`d6b03be16d907103b7b3bbb421108f82a32a06e7687d115194be73a86b9fffb9`，metadata与完整commit/run一致、48份资产匹配且v2单签名有效；完整证据见[Phase3D报告](phase_3d_collection_repository_report.md)。

API访问仅限YYMusic；访问凭据只通过无回显输入进入短生命周期进程内存，不写入仓库、配置、环境持久值或构建产物，不读取现有本机Git凭据。必须取得目标commit的成功run、draft Release及三个资产记录并下载复核后，才可宣称“GitHub APK交付成功”；推送成功、YAML测试通过或旧本机APK都不能替代。

依据：[GitHub CLI创建Release](https://cli.github.com/manual/gh_release_create)、[GitHub GITHUB_TOKEN说明](https://docs.github.com/en/actions/concepts/security/github_token)、[GitHub Release管理](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)。
