# CI 修复：隐藏参考文件必须参与完整性核验

2026-08-31。分支`fix/reference-audit-hidden-files`基于已fetch/pull且工作树干净的`feat/android-ci-and-form-controls@cafb942`。本批只修CI校验器，不增加业务功能，也不提前进入后续Phase。

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

本批不在本机编译新APK。GitHub成功产物须带完整commit/run/attempt、SHA256SUMS及构建metadata；临时Debug签名和14天保留边界不变。访问凭据不写入本文件、Git提交、持久配置或构建产物。
