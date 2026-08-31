# GitHub Actions APK 交付

用户要求从本批起在GitHub上构建APK。正式下载入口改为[Native foundation工作流](https://github.com/Z-YO-YI/YYMusic/actions/workflows/foundation.yml)，本机旧APK仅是Phase2B历史验证产物，不再当作新版本交付。

## 构建和下载

推送feat/fix分支或打开PR触发；也保留workflow_dispatch（手动入口是否可见取决于默认分支是否已有此工作流）。找到目标提交的运行，等待`Android Debug APK and download`成功，在运行摘要或Artifacts下载`YYMusic-android-debug-<commit>-<attempt>`。

顺序：源码指纹/格式/分析/测试 → GitHub Ubuntu runner编译 → apksigner验签 → APK内48个原始SVG/字体/许可证比对 → 生成校验和/提交信息 → 上传。检查或构建失败时不上传APK，不使用continue-on-error或always掩盖失败；Windows job独立保留，不阻塞Android job，二者都依赖checks。

产物仅含：

- `YYMusic-debug.apk`
- `SHA256SUMS`：APK文件本身的SHA-256
- `build-metadata.json`：仓库、完整commit、run URL、attempt、Flutter版本、文件体积/哈希、Debug签名说明

产物默认保留14天（还受仓库策略影响），上传不覆盖同名历史产物。下载需登录且具有仓库读取权限；过期后需重新构建。ZIP容器的artifact digest与APK文件SHA不同。该metadata是构建记录，不是密码学来源证明。

`tools/android_artifact.mjs`拒绝普通本地打包，并核对checkout SHA与GitHub运行身份；工作流只从本次runner编译输出取文件。不会上传开发者电脑中的旧APK、整个build目录、环境变量、凭据或源参考包。Action固定官方v7.0.1 SHA，contents:read，无发布/部署或Secrets注入。

## 签名限制

目前只构建Debug，未请求或配置Release签名。新runner默认debug key可能每次不同，也不同于旧本机APK；直接覆盖安装可能签名冲突。不要为更新而擅自卸载含真实数据的应用。稳定升级/发行签名需要后续单独配置受保护的密钥，绝不将keystore或密码入Git。

## 当前核验边界

2026-08-31：标准Git push可用；此前GitHub连接器访问仓库404，后经用户明确授权恢复临时API访问。首次核验cafb942的[运行33404830686](https://github.com/Z-YO-YI/YYMusic/actions/runs/33404830686)：ZIP校验因Linux隐藏`.gitattributes`读取失败，Android/Windows任务跳过，产物为空。修复及后续证据见[CI隐藏文件记录](ci_reference_audit_fix.md)。

API访问仅限YYMusic；访问凭据只通过无回显输入进入短生命周期进程内存，不写入仓库、配置、环境持久值或构建产物，不读取现有本机Git凭据。必须取得目标commit的成功run和artifact记录后，才可宣称“GitHub APK构建成功”；推送成功、YAML测试通过或旧本机APK都不能替代。

依据：[官方upload-artifact](https://github.com/actions/upload-artifact)、[GitHub工作流产物](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflow-artifacts)。版本SHA通过官方git tag核验为`043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`。
