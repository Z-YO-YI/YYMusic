# CI 修复：隐藏参考文件与 Android SDK 工具路径

2026-08-31。分支`fix/reference-audit-hidden-files`基于已fetch/pull且工作树干净的`feat/android-ci-and-form-controls@cafb942`。本批只修CI校验与构建环境，不增加业务功能，也不提前进入后续Phase。[PR #1](https://github.com/Z-YO-YI/YYMusic/pull/1)指向原功能分支，未自动合并。

## 远程故障证据

用户明确授权临时API访问后，核验[运行33404830686](https://github.com/Z-YO-YI/YYMusic/actions/runs/33404830686)，head为cafb94245cb2c1f8f58d5c33169ef25363194b9a。23项Node检查通过；`Verify all ZIP entries`失败，随后Flutter分析/测试及Android、Windows构建均跳过，artifacts为空。

任务日志定位到`verify_reference_archive.ps1`的`Get-Item -LiteralPath $targetPath`：Unix将`.gitattributes`作为隐藏文件，缺少`-Force`时无法取得其属性。之前Windows上的原始点文件没有Hidden属性，因而未复现；这不是源文件丢失或哈希变化。行为依据：[PowerShell Get-Item -Force](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-item#-force)。

## 修复与回归

- 只给该读取操作增加`-Force`。ZIP固定SHA、24个文件、长度/SHA-256逐项比对、重复/路径越界和额外文件检查全部保留。
- 新增5项Node测试，实际调用PowerShell 7校验器：完整隐藏文件通过；隐藏文件内容改动、隐藏文件缺失、多出隐藏文件、ZIP改动均失败。
- 每个测试复制原始ZIP和24份文件到唯一临时目录；Windows仅在副本中设置Hidden属性。清理前核验绝对父路径和唯一目录名前缀，原始参考及其文件属性不变。
- 修复前5项中3项复现相同Get-Item错误，修复后5项全部通过。新增测试随已有CI的`node --test tools/*.test.mjs`执行，不跳过Linux，也不放宽哈希或Golden容差。

## 验证及交付边界

本地已通过：53份Dart文件格式检查（0变更）、fatal-infos严格分析、74项Flutter测试（包括11张未更新的Golden）、28项Node检查及`git diff --check`。5份源指纹、44SVG、52份确定性派生产物及24个ZIP entry全部保持原始字节。修复提交的GitHub运行结果须在实际执行后另行核验，不能依据旧APK或仅推送成功声称云端成功。

本批不在本机编译新APK。GitHub成功产物须带完整commit/run/attempt、SHA256SUMS及构建metadata；临时Debug签名边界不变。访问凭据不写入本文件、Git提交、持久配置或构建产物。

## 第二次云端核验：sdkmanager 不在 PATH

隐藏文件修复已作为9f08a71提交并推送。[运行33415055087](https://github.com/Z-YO-YI/YYMusic/actions/runs/33415055087)的源码、28项Node检查、全部24个ZIP entry、Dart格式/分析及非Windows Flutter测试均通过；Android任务在安装固定SDK组件时报`sdkmanager: command not found`（exit 127），未产生APK。

GitHub的[Ubuntu镜像清单](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md)声明ANDROID_HOME；其[官方安装脚本](https://github.com/actions/runner-images/blob/main/images/ubuntu/scripts/build/install-android-sdk.sh)把工具安装到cmdline-tools/latest/bin/sdkmanager。工作流改为从ANDROID_HOME解析并带引号调用该路径，先要求环境变量非空、文件可执行。不下载额外Action、不改JDK17/API36/Build Tools36/NDK28版本、不批量接受新许可。

新增YAML回归要求固定工具路径、可执行检查、精确组件参数、安装先于构建；旧工作流先验证为失败。修复后本地75项Flutter（含11张Golden）、28项Node、53文件format及严格analyze全部通过，24份ZIP entry仍保持原始字节。实际构建仍由GitHub执行，需再次核验新提交的运行和产物，不把环境修复等同于APK成功。

## 第三次云端核验：编译成功但产物额度已满

8e6915a的[运行33415790519](https://github.com/Z-YO-YI/YYMusic/actions/runs/33415790519)完成Android assembleDebug、apksigner v2验签、48项打包资源字节比对及Windows Debug/Golden；runner报告APK SHA-256为`1900a5710ecd65011516727265e24c4008590ebaa46cbfe106d5c4c2bca8f0b9`。该哈希当时未能通过下载副本独立复核。

末尾upload-artifact返回`Artifact storage quota has been hit`，工作流因此失败且YYMusic仓库artifacts列表为空。用户于2026-09-01明确允许改用私有草稿Release。新流程只在手动workflow_dispatch时创建唯一`ci-debug-<run-id>-<attempt>`draft/prerelease并附加APK、SHA256SUMS和metadata；普通push/PR不创建Release。实际新运行、三个Release资产与下载后校验完成前，交付状态仍保持待验收。

## 草稿 Release 交付验收

4be8ba2的手动[运行33451875605](https://github.com/Z-YO-YI/YYMusic/actions/runs/33451875605)三项任务全部成功：源码门禁、Windows Debug/Golden、Android Debug编译/验签/48项资源比对及草稿Release上传均通过。生成的[私有草稿Release](https://github.com/Z-YO-YI/YYMusic/releases/tag/untagged-9a49a12002f0c9cc058a)标签为`ci-debug-33451875605-1`，保持draft和prerelease，未正式发布。

通过用户授权的YYMusic只读API重新下载且只得到三个预期资产：`YYMusic-debug.apk` 175733601字节、`SHA256SUMS` 84字节、`build-metadata.json` 460字节。下载后APK SHA-256为`3c69bead8bc20c9a3ab12f35b2ab3dfe684dbbf6d0bc1be6dcb605344d8cd902`，与SHA256SUMS、metadata及GitHub API asset digest一致；metadata的仓库、完整commit、run、attempt、Flutter 3.47.2和Debug签名字段均匹配。本机apksigner再次验证v2签名有效、1个签名者；临时副本随后清理，不提交APK到Git。
