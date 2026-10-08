# 二元续行与块注释续作验收

日期：2026-10-08。已进入当前仓库，起点工作区干净，HEAD 为
`1c75ed8e20a6b5ba5bc7f4f8bc3b840a8be004e1`。历史四阶段补丁已合入，未重复应用。
本报告记录本批提交前工作区验收；本地提交包含实现、测试与本报告，未推送、
部署或发布。两个最终差分报告均明确记录该基准提交和 `source_dirty=true`，
不能把它们当成干净提交验收。提交前仅修订文档中的提交状态，代码未再改变。

## 修改与边界

- 二元表达式从重写、导入移动后的 token 重新解析，按 AST 源码范围建立操作符及
  右操作数的续行锚点，以完整左表达式的输出起始列对齐。遍历使用显式栈，包含
  对象断言。开头行内块注释属于表达式前缀，其宽度不计入锚点；UTF-8 列继续按
  字节计算。括号、优先级及 `Indent=0` 保持各自规则。
- 词法 trivia 增加私有原始 margin。导入条目的前后材料保留 trivia 对象，序列化
  时按精确偏移记录每个块注释的 margin，重新词法化后恢复；相同原文的注释也能
  保留各自 margin，公开源码范围不被篡改。
- 多行块注释按段落打印，逐行裁剪原始 margin 和末尾横向空白，归一化 CRLF，
  保留空行；关闭分隔符前的注释使用内部缩进，导入操作数段落使用续行缩进。
  `Indent=0` 的隐式段落换行取后继物理行缩进或零。

没有改变 AST 深度准入、默认 200 预算或 512 硬上限，也没有新增公开 API。
此次锚点修复不等于完整表达式布局已经完成：函数/局部绑定的 base 与 line-up、
条件分支、嵌套容器、切片等仍需进一步实现。

## 验证

| 检查 | 本次结果 |
| --- | --- |
| native `check --deny-warn` | 通过 |
| native 普通测试 | 243/243 |
| native release 测试 | 243/243 |
| release build、`moon info`、`moon fmt`、`fmt --check`、`moon doc`、`git diff --check` | 通过 |
| 生成 `.mbti` 差异 | 无 |
| 固定 Go 冻结格式化语料 | 504/504，原 402 项内容完全未变，新增 102 项 |
| 固定 Go 上游真实输入 | 151/178，27 项失败继续保留；Go 错误 0，本地错误 2 |

新增 17 种输入分别覆盖默认选项、`Indent=4`、`Indent=0`、`SortImports=false`、
`StripComments=true` 和 `StripAllButComments=true`。预期与幂等标记由本次固定 Go
实际运行生成，完整 runner 再次独立构建并核验双方输出、重新解析和幂等性；未放宽
比较或删除历史用例。三项新增本地测试还验证源码保留、重复格式化、求值结果及
惰性导入请求顺序。

本次先重新运行冻结基线得到 402/402。上游 148/178 基线使用历史干净实现
`30548ae8953ed85ef027d3bd1dfd23eaca67a6c0` 的完整报告；通道中断期间的基线
重跑未确认完成，不计为新验收。修改后两个最终 runner 均实际重新构建和运行
固定 Go。逐项比较全部 178 个输入及完整 Go 结果，与历史基线相同；原 148 项
通过集合零回归，新增通过：

```text
examples/arith.jsonnet
test_suite/comments.jsonnet
test_suite/import_sorting_multiple_binds_and_comments.jsonnet
```

固定 Go 为 v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，
`GOWORK=off`、`GOPROXY=off`；固定 C++ 输入 checkout 为
`bbb38f1020be1f5aed560928fb839b2c448cefb4`。两个参考 checkout 均由 runner
核验为干净。C++ 仅提供输入，不提供格式化预期。

冻结 runner 退出 0；上游 runner 因 27 项保留失败退出 1。本批未重跑完整
CLI、AST、lint、ASan、独立消费者或跨平台验收，历史结果仍绑定其原提交。

## 证据身份

| 文件 | SHA-256 |
| --- | --- |
| 本地 release 格式化探针 | `fc7298185d85a4c0a6047b55b993ca4056a467505ecfbaf267d8df0ab7364935` |
| 本次固定 Go 格式化探针 | `8f4bff3fdf649d3ef024fcfe3fb008990bd896d31f651e99db310c8b202cf7fd` |
| Go 适配器 | `fbce4353eaeed424d9bb061e8d87b5eefdb628fa9a1b6a606e35d1e30c4d5533` |
| tests/go-formatter.json | `fea13352a46ebb78120ec13eaab5f43c67208e5f9a27bab0e418ce9f4a0c0a0e` |
| _build/formatter/report.json | `3d6bd4e8cf5da70eab9b712b775572ef3dc9e97aac439342ff024f37ac6785a4` |
| _build/upstream-formatter/report.json | `eb330c4960ef2a6737e568cbcc85239230c8b2cbdc5aec1def9713d54166ebad` |

原始报告另保存为 `${LOCAL_PATH_005}{frozen,upstream}.json`。
核验脚本 `${LOCAL_PATH_004}` 确认原 402 项 fixture
逐项完全相同且仍通过；`${LOCAL_PATH_003}` 确认上游
输入、Go 完整结果不变，且无通过项回归。复现命令见 [验证说明](../docs/VALIDATION.md)。

本轮执行通道曾断连，最小 `pwd` 重试实际成功后继续工作。MoonBit 临时脚本曾因
`~/.moon/cache/deps` 锁报 `Operation not permitted (os error 1)`，通过工具的
权限审批通道获准后成功运行，没有绕过权限控制。向父会话发送中间状态的工具
两次返回 `Transport closed`，未确认消息送达；最终报告由任务结束通知回传。

## 剩余 27 项

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
test_suite/dos_line_endings.jsonnet
test_suite/error.invariant.option.jsonnet
test_suite/error.recursive_function_nonterm.jsonnet
test_suite/format.jsonnet
test_suite/formatter.jsonnet
test_suite/formatting_braces.jsonnet
test_suite/formatting_braces3.jsonnet
test_suite/invariant.jsonnet
test_suite/invariant_manifest.jsonnet
test_suite/merge.jsonnet
test_suite/object.jsonnet
test_suite/oop.jsonnet
test_suite/oop_extra.jsonnet
test_suite/recursive_function.jsonnet
test_suite/slice.sugar.jsonnet
test_suite/stdlib.jsonnet
test_suite/text_block.jsonnet
test_suite/tla.simple.jsonnet
```

其中 `format.jsonnet`、`stdlib.jsonnet` 仍分别在 72:47、157:20 报
`syntax tree depth limit exceeded`。其余 25 项为格式或参考幂等性差异。
下一批优先统一函数/局部绑定、条件分支及容器的 base/line-up 传播，再处理切片、
断言字段分类、方法字段名、隐式对象相加和文本块。深树仍按前批设计要求先证明
迭代解析后处理/导出与独立格式化准入，不能仅提高预算来计为通过。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
