# 断言归属、方法名与文本块验收

日期：2026-10-08。实现提交 `ec27c1c23cc2a8537b9ca4c335c914b5cf419cc2`。
本报告中的两个最终差分均在该干净提交重新构建固定 Go 并实际运行，
`source_dirty=false`；工作区起点为 `0b97532`，已有修改未被覆盖。
只创建本地提交，未推送、发布或部署。整体目标仍未完成。

## 修改

- 关闭分隔符时结束同深度断言状态，防止先前对象断言污染后续字段冒号。
- 字符串方法名和所有 additive 可见性运算符应用 pretty-field-name 规则；
  非标识符和保留字仍保留引号。
- Go 的普通 Var 与 self/$ 节点具有不同隐式对象相加规则；MoonBit 根据名字
  分类，保留 self/$ 的显式加号，普通变量及索引继续遵循既有规则。
- 左括号紧接索引左中括号时不新增空格；数组括号尊重 PadArrays。
- 文本块按解码值重排正文和结束符缩进，保留 chomp 与空行，并按固定 Go
  行为输出 Unix 换行。Indent=0 保留原始缩进但去除 CR。强二元续行与普通
  行内二元式区分 base；正文缩进在写入前检查输出预算，避免整数溢出。

文本块 CR 转换遵循参考格式化行为，可能改变原始含 CR 的解码值；测试对此
单独核验格式化输出，不将其伪装成求值保持。其他正文测试同时核验求值、
幂等性及 ParsedSource 原文隔离。没有新增公开 API，也未改变深度预算。

## 验证与证据

| 检查 | 结果 |
| --- | --- |
| native check / release build --deny-warn | 通过 |
| native 普通 / release 测试 | 均为 246/246 |
| moon info、fmt、fmt --check、doc、git diff --check | 通过；无 .mbti 差异 |
| 固定 Go 冻结格式化语料 | 608/608；既有 504 项保留，新增 104 项 |
| 固定 Go 上游输入 | 157/178；21 项失败保留，Go 错误 0、本地错误 2 |

新增 13 种边界输入分别覆盖默认选项、Indent=4、Indent=0、PrettyFieldNames=false、
PadArrays=true/PadObjects=false、StripComments、StripAllButComments 和关闭隐式加号。
预期及参考幂等标记由固定 Go 实跑生成，正式 runner 又独立重新核验双方结果、
重新解析及幂等性。没有删除历史输入、放宽输出比较或把失败计为通过。

对前批全部 178 行逐项核验输入和 Go 结果不变，原 151 项通过集合零回退。
新增通过为 dos_line_endings、invariant、object、oop_extra、slice.sugar、text_block。
冻结 runner 退出 0，上游 runner 因保留失败退出 1。

固定 Go v0.21.0 为 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，
GOWORK=off/GOPROXY=off；C++ 输入提交为 `bbb38f1020be1f5aed560928fb839b2c448cefb4`。
参考 checkout 均由 runner 核验干净。复现命令见 [VALIDATION](../docs/VALIDATION.md)。

| 文件 | SHA-256 |
| --- | --- |
| tests/go-formatter.json | `1f1c627c0bda4c0e821d856ca607480a744e31b4665fc483c1e5049ab7cfe39e` |
| _build/formatter/report.json | `657cc74fd1727a6e442a94cca9992c4c4ebafd99d9c14d6bcccaee61c573f282` |
| _build/upstream-formatter/report.json | `4fba13a0a04e4cadb302f20262262b3ad45a50260eb4e296b713b470d6a0a79f` |
| 本地 release formatter probe | `f038e1aea1f4c60619dde84a11470c907ab809bf091ad074f1b8b5cdc615456a` |

最新独立 CLI 差分在本批实现前干净 `0b97532` 运行，为 1132/1150，保留 18 项
参考崩溃差异；不能转移为 ec27c1c 的整体验收。AST、lint、参数、Evaluator、
ASan、消费者及 Linux 验证尚未在本实现提交重新验收。

## 剩余 21 项与持续推进

```text
benchmarks/bench.01.jsonnet
benchmarks/bench.03.jsonnet
benchmarks/bench.08.jsonnet
benchmarks/gen_big_object.jsonnet
examples/error-examples.jsonnet
examples/functions.jsonnet
examples/mixins.jsonnet
gc_stress/long_chains.jsonnet
test_suite/condition.jsonnet
test_suite/error.invariant.option.jsonnet
test_suite/error.recursive_function_nonterm.jsonnet
test_suite/format.jsonnet
test_suite/formatter.jsonnet
test_suite/formatting_braces.jsonnet
test_suite/formatting_braces3.jsonnet
test_suite/invariant_manifest.jsonnet
test_suite/merge.jsonnet
test_suite/oop.jsonnet
test_suite/recursive_function.jsonnet
test_suite/stdlib.jsonnet
test_suite/tla.simple.jsonnet
```

format/stdlib 两项仍因 AST 深度 244/300 被默认准入拒绝。其余 19 项主要涉及
函数/局部绑定、条件分支、嵌套容器、断言消息和逗号材料的缩进传播。后续继续
依整体清单推进，不以本阶段提交代替完成整体对齐，也不抬高默认预算来计通过。
