# Phase 4N — Android 音频原生许可材料报告

2026-09-05，分支`codex/native-audio-notices`，基于已fetch/pull的`6cd370b`。

## 新增与修改

新增Gradle精确解析报告、POM/父POM/归档许可生成器、数据校验器、两平台包内校验和5项工具测试。
新增`assets/legal/android_audio/notices.json`：66,604字节，SHA-256
`17c6871762ed7e3c2eb6fab4604530bc053100e41065fbb8153d0fedd60a8c72`。
内容含完整Apache、ExifInterface归档Apache和checker-qual带著作权MIT三份去重原文，
每个坐标均有原文引用、POM/父POM、实际归档指纹和嵌入材料路径。原文与来源详情见ADR-042。
`docs/legal/just_audio/native_manifest.json`固定范围、变体差异和资产指纹。

实际Debug/Profile音频闭包51项；Release只读解析48项，三个明确缺席的注解坐标已单独固定，
其余版本与归档指纹一致。没有执行Release构建或签名。
CI在Android构建后重新解析依赖并从POM/归档重新生成比较，两端核对真实包内资产。
原48项设计资产、六个Dart音频包、禁用候选/私密文件检查全部保留；只新增一项许可资产。

## 本地验证

格式161文件0改动，严格analyze 0问题；Flutter255/255含32张Windows宿主Golden通过；
Node56/56通过。新增测试覆盖完整原文、父POM、版本/归档漂移、缺失/重复/篡改资产、私有路径、
三种构建变体差异及真实Android/Windows校验入口。原ZIP24/24一致；build_runner/Drift生成
0输出、代码/Schema零差异；锁文件未改变。源码生成Check和三个变体的归档/坐标比对均通过。

本机Android Debug构建成功，APK230,987,176字节，SHA-256
`f1fb121cd83397ea8028a45b3a93d3faf7a412a35ee6ab61d05c3636229348a1`；
48项设计资产、六包NOTICES.Z、新原生许可资产均通过；apksigner v2有效且只有1个Debug签名。
Windows本机构建未运行，使用GitHub补齐；本批未重跑原生播放，原生计时仍属于Phase4L。

开发中修复了AGP本地插件多变体归档歧义、同字节重复变体归档，以及Debug/Release闭包差异。
最初Release精确比较真实失败；记录48项证据和3项明确差异后补充回归，未放宽为任意子集。
POM查询显式使用Gradle自身API，避免全新CI仅有`.module`而缺POM缓存。JSON固定LF；
XML禁DTD/外部实体；嵌套JAR与文本读取有界；开发机绝对路径不进入许可资产。

## GitHub、范围和下一步

代码提交及云端双平台结果将在推送后按精确SHA补充；不能把本机Android成功当作Windows通过。
未改变发布权限、手动发布条件或保留期，没有创建新Release。
本批不改HTML/App.tsx Sprite、POLISH_CSS、字体和UI；Phase2网页视觉对照仍欠验收。
这是当前Media3闭包的工程许可材料，不是整个应用发行法律批准；`releaseApproved=false`。
下一批完成许可查看入口与共用播放器生产接线，之后验收Phase4出口；不跳过Phase5—11。
