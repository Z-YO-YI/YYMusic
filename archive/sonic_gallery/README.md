# Sonic Gallery 历史原型归档

2026-08-31，进入 YYMusic Phase 1 前，将原本未跟踪的旧 Flutter 源码、两份测试、pubspec、分析配置和封面原样移入此目录。13 个文件的 SHA-256 与移动前一致，清单见 manifest.json，验证命令：`node --test tools/legacy_archive.test.mjs`（在仓库根目录）。

本目录不是 YYMusic 正式客户端，不会导入根工程、不会打包为 Release assets，也不属于根工程 format/analyze/test 范围。没有删除旧测试或修改原型来制造通过结果；原型已知问题见 docs/existing_flutter_audit.md。本次只验证归档完整性，不宣称旧原型可分析/可构建。

后续恢复请从本目录复制到新的独立目录，不覆盖根 YYMusic 工程。根 README 的旧原型说明另保留在 Phase 0 Git 历史。
