# 源码词法保真与原始解析验收

2026-10-05，实现提交 `0e4892ea936c8a17e9318a1973d262042ad8d450`。
固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后差分均在干净工作区执行。**AST/原始解析 173/173，lint 409/410；
格式化器与整体对齐仍未完成。**

## 本批能力

新增 `ParsedSource::parse`、`text`、`parts`、`ast`，提供原始解析与源码恢复入口。
同一词法扫描可选择保留每个 token 前的空白/行注释/块注释及尾部材料；片段携带
原始文本和 UTF-8 字节范围。数字、字符串引号/转义、verbatim、文本块缩进、
CRLF、shebang 和无末尾换行均可原样恢复。普通 Program 解析不保留这些 trivia。

ParsedSource 解析语法但不执行代码或检查词法作用域，因此可保留 unknown、self、
super 等待分析输入。`ast()` 返回独立语义视图；转成 Program 时仍须通过作用域
校验。修改返回的片段数组或 AST 不改写原始文档。源字节和 AST 深度限制适用。

同时将重复 local 名称和重复字面字段拼写检查前移到解析期，按 Go 的位置、消息
和优先顺序报告。计算字段不参与字面拼写检查，完整词法扫描错误仍优先。

这是格式化器的前置实现。尚不提供 Go Fodder 规范化、注释的 AST 归属、可编辑
原始语法树、格式化选项、FormatNode 或 jsonnetfmt；语义视图仍会移除语法糖。

## 对照与验证

新增 28 项原始解析/源码恢复用例、8 项重复声明消息/位置用例。Go 适配器通过
`formatter.SnippetToRawAST` 验证接受或报错；成功时返回原输入。本地另验证所有
片段拼接和 text() 均逐字符等于输入，不据此宣称 Go token/Fodder 表示等价。
上游 empty_comment 和 regular_expression 输入已保留来源；后者本身应报转义
错误，没有改为成功或移除。

旧 release 基线 AST **149/173**、lint **402/410**，保存在对应目录
`source-before.json`。旧 probe 的 4 个错误输入能匹配相同错误片段，不代表它
已有原始解析入口。新实现新增 36 项全部通过；带冻结位置的 lint 用例 **190/190**。
本地 5 项新测试另外验证片段边界、Unicode 字节列、复制隔离、惰性和资源限制。

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；新增 ParsedSource、SourcePart、SourcePartKind |
| native debug / release | 各 224/224 |
| Go AST/原始解析 / lint API | 173/173；409/410，source_dirty=false |
| Go CLI / C++ CLI / 上游语言 | 1132/1150；98 通过 + 10 声明差异且 0 失败；303/303 |
| lint CLI / 独立归档消费者 | 两边各 23 项；22/22 |
| 隔离 ASan | 224 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 173 AST/原始解析 fixture + 23 lint CLI 检查通过 |

Go CLI 的 18 项失败名称集合与本批前完全相同；lint 唯一失败仍为
`distinct-entry-cross-import` 的参考 panic，两 runner 均保留失败并退出 1。
旧 Evaluator ImportAST 重试差异沿用原 20/21 Go API 证据，本批未重跑该参考序列。
错误片段/开始坐标不代替完整错误排版及运行时帧等价；其他源码、格式化、调试
能力与跨平台验证仍需推进。

## 构建证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release CLI：`49e790aaf8e14cb54af9d40fe7f618c6f03a304b0a7a3aaf489cf9740af925f6`。
- AST probe：`d58fd4ff7ba101fdb36ba1da6dbe98c214e4bfade7d92b57e3772e5723934ae2`。
- lint probe：`7bb31d88a8a59bc9c59a12dedc312faef80177b8c678d0acc5c58ae56c9385c1`。
- Go AST helper：`63b1d8d52799ee3cd047113b2cd5ed7a4109588ef7fbb92b0b741cbea173e4b2`；
  adapter：`01f79904eb4c24ee37dd214071a7c883e125a07db209e145e3ee76428ab6ed63`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- Go helper 使用 Go 1.24.0、GOWORK=off、GOPROXY=off，固定参考干净状态校验通过。
- `_build/{ast,lint,go-differential,differential}/report.json` 均绑定本实现提交及
  source_dirty=false；上游语言报告也绑定本提交。批次前原始报告以 source-before.json 保留。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.27797.bb5e49eb`。
  跟踪源码及工具链使用隔离副本，exitcode=99，关闭 leak detection。完整 Go lint
  410 项 API 差分由 release 二进制验证，不声称全部在 sanitizer 下执行。

仅本地提交，没有推送或发布。
