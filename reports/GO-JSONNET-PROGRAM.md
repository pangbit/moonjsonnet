# 已解析 Program 接口验收

2026-10-05，在实现提交 `83970a95b9d2b124c64d1d85e132863fc50654e2` 和干净工作区
执行验收。参考 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**整体功能对齐未完成；本批支持入口 AST 重复执行，每次执行状态独立。**

## 实现范围

- `Program::parse(source, filename?, anonymous?, limits?)` 完成解析及静态检查，
  不执行源码、读取导入或调用宿主回调。公开类型的字段私有，保存入口 AST、
  固定源码身份和 UTF-8 字节数，不额外保留整份源码字符串。
- `Program::evaluate`、`evaluate_text`、`evaluate_stream`、`evaluate_multi`
  提供四种既有输出。每次可传不同 ext/TLA 参数、回调、trace sink、导入器及预算；
  filename/anonymous 固定于解析时。现有字符串入口签名不变，统一先解析再执行。
- 每次执行重新创建求值状态、thunk/对象缓存、导入缓存和资源计数。导入源码及
  代码参数仍在本次执行中按需解析；标准库初始化保持既有行为。调用者复用
  FileHost 时，它自身的文件字节缓存仍遵循已有宿主契约。
- 创建时检查源字节数及解析器/AST 深度，执行时按新 Limits 重新检查源字节数
  和 AST 深度。执行不重放词法/解析过程，因此不重新计数已消去的冗余括号深度。
  运行时 steps/stack/output/import 等预算各次独立，失败后可再次执行。
- ASan 工具固定 `exitcode=99`，防止 sanitizer 错误被预期应用退出码 1 掩盖。
  此配置用于隔离测试和两个 CLI 集成入口，不修改用户安装的工具链。

参考依据为固定 Go `vm.go` 的 SnippetToAST、Evaluate、EvaluateStream 和
EvaluateMulti。本项目只复用不透明入口 AST，没有公开 AST 编辑、ExtNode/TLANode、
可重用 VM 配置/reset 或跨次共享求值缓存，不宣称 Go VM 生命周期等价。

## 验证

新增 7 项 API 回归和 1 项可执行文档测试，覆盖解析/运行时错误分离、重复传参、
四种输出、Unicode/NUL、固定输出预算、导入缓存及内容变化、匿名身份、导入错误
恢复、回调替换、二进制导入、各类资源失败后的恢复，以及继承对象、数组操作和
tailstrict 递归的重复求值。独立归档消费者新增公共 Program 四种执行方法检查。

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；生成接口只增加 Program 及其方法 |
| debug / release 测试 | 各 158/158 |
| Go 解释器差分 | 1112/1130；原有 18 项失败保留，0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 183 项通过 |
| 依赖工具差分及本地 CLI | 33/33 fixture + 13/13 CLI 检查 |
| 隔离 ASan | 158 测试 + 183 宿主集成 + 33 依赖 fixture + 13 CLI 检查通过 |
| 独立归档消费者 | 17/17 |

本批没有增加 Go CLI 或 Go VM 生命周期差分输入。既有 CLI 语料验证改用
Program 执行路径后无新增差异；重复执行及状态隔离由本地 API 测试证明，不能
将其计作新增 Go 行为通过数。Go runner 仍因原有 18 项失败退出 1，完整输入
保留；依赖工具结果独立统计，标准库注册数也不代表行为完成对齐。

ASan 使用隔离工具链及已跟踪源码，关闭 leak detection；仅作为地址错误检查，
不构成泄漏检测证明。本次未作性能测量。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- 本地 release 解释器 SHA-256：
  `96ad5569b3982610032d0f873ef2fcc15f0dd16ceac163388e5ecfb053810428`。
- 本地 release 依赖工具：
  `6340b095203b19e844decc5dd45cdd31c8b44828b5cac32b06bb92cc91bd4047`。
- Go 解释器：Go 1.24.0、vcs.modified=false；
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- 同一 Go 提交的依赖工具：
  `872157324f19a9c43d448fb2db5ebc7ed322be5234d788f635ec5ba2b75c6f3c`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/dependencies/report.json`、`_build/parity/report.json` 均绑定上述
  实现提交及 source_dirty=false；`_build/upstream-language/report.json`
  也绑定该实现提交。
- 消费者目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.86401.212383ee`。
- 依赖工具证据目录：`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-dependencies-.86690.2b08997c`。
- ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.87126.b07f2d69`。

只作本地提交，没有推送或发布。AST 参数/编辑、共享 VM 生命周期、导入查询、
格式化器、lint、完整诊断模型和平台差距仍待推进。
