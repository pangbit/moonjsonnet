# 外部代码与顶层参数验收

2026-10-04 在实现提交 `9ae08372d23d62cf1dd5b20cad5531b8c77a207e`
及干净工作区完成验收。目标仍为 google/go-jsonnet v0.21.0，整体对齐未完成。

## 实现与边界

- `evaluate` 和 `fs.evaluate_file` 新增 `ext_code`、`tla_vars`、`tla_code`。
  保留 JSON 参数接口；同名代码覆盖 JSON。每次调用独立注册与缓存。
- 外部值和代码为记忆化 thunk。代码在只有 `std` 的独立作用域解析、求值，
  可以读取外部变量、调用 native/trace、导入文件，不能读取入口局部变量或其他 TLA。
  未使用的错误代码和文件不触发；循环外部变量返回受控 Runtime。
- 顶层函数自动调用一次，支持命名、默认和惰性参数，包含 builtin/native 函数。
  普通顶层值忽略 TLA；返回另一个函数时保留普通 manifestation 错误。
- 参数诊断、trace 和 `std.thisFile` 使用 `<extvar:NAME>` / `<top-level-arg:NAME>`；
  导入 resolver 的 `from` 为空，文件宿主从 root 解析。参数文件导入后使用自身路径。
- CLI 支持 8 个 string/code/file 长选项、`-V`、`-A` 及不含 `=` 时的环境变量读取。
  保留第一个 `=` 后的全部内容、空名称/值、同名最后赋值覆盖。
  文件参数由 `import`/`importstr` 惰性读取，遵守既有根目录和 symlink 限制。
- 代码参数首次使用时检查源字节和解析深度，求值共享步骤、深度、输出与导入预算。
  宿主提供的参数映射/JSON 容器不得在求值期间修改；保留 synthetic 文件名给参数使用。

参考源码为 `vm.go` 的 ExtCode/TLACode、`interpreter.go` 的
prepareExtVars/evaluateAux、`imports.go` 的 codeToPV/nodeToPV，以及
`cmd/jsonnet/cmd.go` 的参数处理。实现为 MoonBit，参考解释器仅用于验证。
可重用 VM 的 reset/缓存、AST 参数和完整 CLI 输入/输出/缩写能力仍未完成。
文件根目录政策比 Go 默认文件导入器严格；错误全文和全部输入等价未声明。

## 验证

| 检查 | 结果 |
| --- | --- |
| `moon check --deny-warn`、info、fmt/check、doc、release build | 通过 |
| debug / release 测试 | 各 108/108 |
| Go 新增参数差分 `tests/go-parameters.json` | 50/50 |
| 完整 Go 差分 | 824/842；18 失败；0 跳过/未支持 |
| C++ 原始共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库反射清单 | 163/163，0 缺失/签名差异/额外成员 |
| ASan | 108 测试 + 45 集成通过；leak detection 关闭 |
| 独立归档消费者 | 9/9 |

本地回归覆盖 JSON/代码覆盖规则、JSON 原样注入、作用域、默认依赖、隐藏字段与
未使用错误、缓存/新求值状态、函数参数、builtin/native 顶层调用、Unicode、诊断、
导入来源/缓存共享、binary、native/trace 共享和资源限制。
CLI 集成另验证参数文件逃逸、非法代码/源字节限制、缺失环境变量、file 参数格式、
参数失败时不覆盖已有输出文件。

差分工具新增 `args`、`files`、`env` fixture 字段，并记录在逐项结果中。
新增成功用例同时固定 JSON 结果，错误用例验证参考诊断特征和 MoonBit 类别，
trace 按字节比较。环境变量值全部为提交的测试常量。
完整 Go 的 345 个 expected-error case 和 3 个 raw-output case 为重叠计数。
18 项历史失败保留，详情见 [整体对齐](../../development/zh-CN/GO-PARITY.md)；Go runner 因这些
失败返回非零，仍不是通过的 CI 兼容门槛。

## 构建与证据

- macOS arm64，Moon 0.1.20260920，MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0 构建，
  `vcs.modified=false`；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`，本轮恢复并重建；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- MoonJsonnet CLI SHA-256
  `396143bbd9668f282b5fc87ab27d801cc8076a21f90420ab4e6f33bd98a58720`。
- Go/C++/parity 报告的 source_commit 均为实现提交，source_dirty=false。
  `_build/upstream-language/report.json` 同样绑定实现提交。
- ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.89373.b4698557`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.89386.32932271`。

原始报告留在 `_build`，未推送、未发布，其他平台和远端 CI 未在本轮验证。
