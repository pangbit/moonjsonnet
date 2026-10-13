# 字符串与文档流输出验收

2026-10-04 在实现提交 `2e2d00fae9a42c66b5d32321f2c68fc012b0fed7`
及干净工作区完成验收。目标仍为 google/go-jsonnet v0.21.0，整体对齐未完成。

## 实现与边界

- CLI `-S`/`--string` 要求字符串，保留原始内容并追加一个换行；其他类型直接
  返回 Type，不深遍历其对象字段/数组元素。Unicode、NUL、已有换行不被转义。
- `-y`/`--yaml-stream` 先深度 manifestation，再要求顶层数组。每个元素是
  JSON 文档，前置 `---\n`，非空流以 `...\n` 结束；空数组输出零字节。
  同时指定 `-S` 时仍按 JSON 文档输出，符合 Go 的 stream 行为。
- `evaluate_text` 返回上述 JSON/原始字符串文本；`evaluate_stream` 返回带
  换行的 JSON 文档数组。两者与 `evaluate` 共用初始环境、TLA 调用、参数、
  resolver、native/trace 与错误转换流程，每次调用有独立状态。stream 文档
  共享参数/导入缓存，全部求值后才返回。`evaluate` 的 Json 返回契约不变。
- 默认 CLI JSON 替代旧紧凑布局：三空格缩进、排序字段、`[ ]`/`{ }` 空容器，
  整数用固定十进制，非整数用 17 位有效数字，保留负零和非有限聚合值。
  CLI 引号转义 C0/C1，保留 HTML、U+2028/U+2029；不复用 `std.manifestJson`
  的四空格/最短固定数字/JavaScript 行分隔符转义契约。
- stdout 宿主按显式字节长度写入并检查 flush，保留 NUL，不关闭进程 stdout。
  文件模式复用既有写入接口；失败求值不会打开或截断已有输出文件。
- 文本预算按实际 UTF-8 payload 检查，末尾单换行不计入；stream 文档共享
  payload 预算，CLI 进一步计入文档换行与全部 YAML 标记。JSON/stream 仍保留
  紧凑 JSON manifestation 预算，属于保守执行限制。写出前检查完整结果；
  输出 I/O 失败可能留部分内容，不声明事务性。

参考源码为 `interpreter.go` 的 evaluate/evaluateStream、manifestString、
manifestJSON、serializeJSON、unparseNumber，以及 `cmd/jsonnet/cmd.go` 的
选项与 writeOutputStream。没有调用参考解释器提供运行时功能。
multi、输出目录创建、导入搜索路径、stack/trace 选项、VM/AST 与工具接口仍待实现。

## 验证

| 检查 | 结果 |
| --- | --- |
| `moon check --deny-warn`、info、fmt/check、doc、release build | 通过 |
| debug / release 测试 | 各 121/121 |
| 新增 Go 输出差分 `tests/go-cli-output.json` | 45/45 |
| 完整 Go 差分 | 907/925；18 失败；0 跳过/未支持 |
| C++ 原始共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库反射清单 | 163/163；0 缺失/签名差异/额外成员 |
| CLI/文件宿主集成 | 97 项通过 |
| ASan | 121 测试 + 97 集成通过；leak detection 关闭 |
| 独立归档消费者 | 11/11 |

新增 31 项成功输出 fixture 按字节固定 stdout，14 项错误 fixture 核对参考
诊断特征与本地类别。覆盖默认 JSON、整数/非整数、空容器、可见性/断言、
Unicode/NUL/C0/C1、字符串类型/追加换行、短选项组合、stdin、ext/TLA、导入、
空流、嵌套文档、忽略 -S、trace 顺序与后续文档失败。错误差分同时要求两边
stdout 为空；没有通过裁剪输出或解析 JSON 忽略新增格式差异。

本地测试补充宿主 resolver/native/trace、匿名起点、缓存共享、实际 payload
及共享文档预算。集成另覆盖文件/stdin/内联输入、精确预算与少一字节、流标记
预算、输出文件包含 NUL、空流截断、错误保留已有文件及输出 I/O 失败。
README 文档测试与真实 Mooncakes 归档消费者调用两个新增公开接口。

首轮差分为 906/925，包含原有 18 项及新增整数格式失败。输入
`[1e21,1e-8,1000000000000000100]` 的 Go 输出分别为
`1000000000000000000000`、`1e-08`、`1000000000000000128`；初版误将整数也
按科学计数法输出。随后核对 unparseNumber，复用既有固定整数/17 位格式实现，
修正固定预期并保持逐字节断言。首轮原始结果保留在
`_build/go-cli-output-first-report.json`，不作为最终干净提交验收。

完整 Go 的 374 个 expected-error、3 个 raw-output、31 个 text-output 为重叠
计数。18 项历史失败原样保留，详情见 [整体对齐](../../development/zh-CN/GO-PARITY.md)；
Go runner 因此退出 1，尚不是通过的兼容 CI 门槛。C++ 声明差异不算兼容通过。
标准库反射注册清单不证明全部行为等价。

## 构建与证据

- macOS arm64，Moon 0.1.20260920，MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0 构建，
  `vcs.modified=false`；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
  共享差分记录哈希；提交由本地 checkout 和上游语言工具另行核验。
- MoonJsonnet release CLI SHA-256
  `c361102e6dd233ac8c9aa5a583cb8c3ead7ad42b6819b408f7a4ce1e7ebab7ab`。
- `_build/go-differential/report.json`、`_build/differential/report.json` 和
  `_build/parity/report.json` 均绑定上述实现提交，source_dirty=false；
  `_build/upstream-language/report.json` 同样绑定实现提交。
- ASan 副本：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.59550.13f56d92`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.59590.5268b98`。

原始报告保留在 `_build`；只作本地提交，未推送或发布。
其他平台与远端 CI 未在本轮验证。
