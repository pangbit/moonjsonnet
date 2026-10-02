# go-jsonnet 对齐进展：序列函数

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`7c1fb62b21134fd4fc8c4babc45af989cf40964e`。
Go/C++ 差分均在该提交的干净工作区复跑，报告中 `source_dirty=false`。
本记录之后的文档提交不改变已验证的源码。

## 本批实现

- `std.makeArray(sz,func)`：惰性生成，按 Go 行为接受负整数长度为空数组，
  拒绝小数长度，使用元素时才检查回调参数个数。长度限制为 signed 32-bit。
- `std.mapWithIndex(func,arr)`：数组/字符串映射，索引按 Unicode 码点计算，
  输入元素和映射结果保持惰性。
- `std.reverse(arr)`：仅接受数组，不修改输入，保留元素 thunk。
- 分配逐项消耗步数预算；覆盖命名参数、隐藏字段反射、类型/参数错误与限额。
- 差分工具验证固定 Go 二进制的提交及未修改状态，记录二进制摘要、源码提交、
  工作区状态和逐例 stdout/stderr；Go/C++ 报告独立保存。

新增的 31 条用例全部通过 go-jsonnet 对照。它们位于
`tests/go-differential.json`；原有共享语料完整保留在 `tests/differential.json`。
Go/C++ 的 `makeArray` 和 `reverse` 契约确有差异，新增实现选择 Go 行为，
详见 [兼容说明](../docs/COMPATIBILITY.md)。C++ 通过数不包含新增 Go 专用语料。

## 验证结果

| 验证 | 通过 | 失败 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: |
| Go 差分：共享语料 + 新增语料 + 三个示例 | 127 | 10 | 2 | 0 |
| 其中新增 Go 序列语料 | 31 | 0 | 0 | 0 |
| C++ 差分：原有共享语料 + 三个示例 | 106 | 0 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 2 | 0 |

通过、失败和未支持为互斥计数。Go 完整差分仍返回非零退出码，
没有将差异改记为通过、跳过或未支持。

其他检查：`moon check --target native --deny-warn`、debug/release 各 23 项测试、
`moon info`、`moon fmt --check`、`moon doc`、release 构建均通过，公开 `.mbti`
无变化。宿主/CLI 集成 27 项通过，打包消费者 3 项通过。提交后 ASan 隔离工具链
测试 23 项、宿主集成 27 项通过；泄漏检测关闭，不构成泄漏检查结论。

## 保留的 Go 差异

以下 10 条均来自新增功能前的共享语料，原输入和失败结果全部保留：

| 用例 | 观察到的差异 |
| --- | --- |
| `format-dynamic-fractional` | 小数精度格式化的末尾数字不同 |
| `numeric-string-rendering` | `manifestJson({x:0.1})` 的数字文本不同 |
| `fold-lazy`, `fold-empty` | Go 强制求值函数/初始值，本项目沿用原惰性行为 |
| `length` | 含默认参数的函数参数计数不同 |
| `noninteger-index`, `slice-fraction` | Go 接受小数索引/切片，本项目拒绝 |
| `bitwise-range-error`, `bitwise-overflow-error` | Go 返回数值，本项目报越界/溢出错误 |
| `tailstrict` | 默认参数引用另一参数时 Go 发生内部错误，本项目返回 `[5,9]` |

下一批先处理函数反射和折叠求值契约，再处理索引/位运算及数值文本差异；
每项需同时记录对原 C++ 契约的影响。上游内部错误单独保留，不作为本项目
应复制的目标行为。本批不宣称完整 go-jsonnet 兼容。

## 可追溯证据

- Go：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`。
- C++：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- MoonJsonnet release CLI SHA-256：`45d7a8dd14a008367e7011ce3dada2795f5cd0adf17d42b6b731c617fd3af382`。
- Go 参考 CLI SHA-256：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- 本地原始报告：`_build/go-differential/report.json`、
  `_build/differential/report.json`、`_build/upstream-language/report.json`。
  这些生成物不提交，复现命令见 [验证说明](../docs/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
