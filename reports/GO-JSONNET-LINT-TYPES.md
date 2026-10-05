# lint 类型推断与调用检查验收

2026-10-05，实现提交 `f90a0b8ba54108e2ab1b88179dc32db8d7384e8d`。
Go 参考验收运行于干净工作区，固定 v0.21.0 提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**本批消除此前 35 项 lint 类型差分；整体功能对齐仍未完成。**

## 实现与边界

- 独立 MoonBit 类型图，不执行 Jsonnet。预分配递归绑定/导入根，分离容器元素
  与函数结果，用迭代强连通分量传播类型上界。分析步骤和索引展开深度受 Limits
  限制；资源失败中止分析，不返回部分成功结果。
- 覆盖函数调用、必需/重复/未知参数和数量、索引对象及索引类型、缺失字段、一元
  运算。传播联合、递归数组/对象/函数返回和跨文件导入类型。
- 数组前 5 项分别跟踪；其余元素合并。函数参数、self/super、动态字段及推导式
  保守处理。固定 Go 的函数最小参数估计也按实际实现保留。
- 142 项 lint 标准库声明从固定源码提取，验证参考提交、干净状态及源码 SHA-256。
  保留参考近似，包括 `base64DecodeBytes` 推断为数字、`stringChars` 推断为字符串，
  不据此改变解释器的运行时行为。
- 缺失字段消息采用 Go 1.24.0 的字符串转义和固定 Unicode 可打印字符表，覆盖
  控制字符、Unicode 范围边界；来源与 Apache/BSD 许可记录于 NOTICE。

对基础报告作一项明确更正：Go lint 的导入、循环和类型遍历**跳过对象断言**，
仅词法引用分析单独遍历断言。此前本地“断言内缺失导入应报告”的测试不符合参考，
本批通过实际 Go 输入验证后修正，新增差分输入保留。

## 差分与回归

全部原 81 项输入保留，再加入 33 项：联合函数签名/默认值、重复参数、递归结果、
元组跟踪边界、动态字段与合并、self/super、标准库近似、对象断言和 Unicode 引号。
最终 **114/114**：上游全部 62/62，原定向 19/19，新输入 33/33。

扩展过程曾为 108/111：对象断言调用、一元运算和 NUL 字段转义三项失败。
原始输出保留于 `_build/lint/types-expanded-before.json`；原 35 项失败保留于
`_build/lint/types-before.json` 及历史报告。输入没有删除，比较规则没有放宽。

API runner 比较有序完整消息数组及 found 标志，保留完整诊断与进程输出。
诊断位置/范围、源码保真和所有语法降级边界不属于这次通过结论。标准库 lint
声明也不是标准库运行时正确性的证明。

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，无公开接口变化 |
| native debug / release | 各 199/199 |
| 固定 Go lint API | 114/114，source_dirty=false |
| lint CLI | 两边各 23 项通过，新增调用/索引/一元/参数错误 |
| 独立归档消费者 | 21/21，验证公开 lint 类型诊断 |
| 隔离 ASan | 199 测试 + 183 宿主集成 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 20 AST fixture + 23 lint CLI 检查通过 |

本批未改求值器，也没有重跑旧 Go/C++ CLI 全量语料，其最新版本绑定证据仍是
[AST 验收](GO-JSONNET-AST.md) 的 fba845d。旧 CLI 18 项和 Evaluator 1 项差异独立
保留，不能用 lint 114/114 抹去。格式化器、调试器/EvalHook、AST 元数据、完整
诊断与跨平台能力继续列为未完成。

## 版本与证据

- macOS arm64，Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- lint CLI SHA-256：`3a493a5c215d12f2d2a0965abf15a7615e4eadca371acbb58638a6628bacce45`。
- API probe：`a0e7309f1c89071934666764b9b67fcc1ed296e78dfe576fd3806baf1c8472bf`。
- Go helper：`b7c3c3fd8d4cdac565166b678500417895d192e1ce97e96c3f736a5bdf069333`。
- Go adapter：`8dcf5c0ddbbff44a80394568f68384a6a756293d2d820d348500b6200ccba41a`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；helper 的版本绑定来自 checkout 校验。
- `_build/lint/report.json` 记录实现提交、干净状态及全部 114 项原始结果。
- API 临时证据：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.75764.b42d0340`。
- CLI：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.76199.17b069a8`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.76293.4ea64444`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.71346.74a3c90c`。
  副本来自上述提交的跟踪文件，隔离工具链，exitcode=99，关闭 leak detection。
  全量 Go lint API 是独立 release 二进制差分；没有声称全部 114 项在 ASan 下运行。

仅本地提交，未推送、发布或声称整体完成。
