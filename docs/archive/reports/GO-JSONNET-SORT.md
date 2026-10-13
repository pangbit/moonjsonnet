# go-jsonnet 对齐进展：稳定排序

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`f694261c4694f8a3c55c83b865661ea098253bd6`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前结果见 [序列组合函数记录](GO-JSONNET-COMBINATORS.md)。

## 本批实现

新增 `std.sort(arr,keyF=function(x)x)`。支持位置/命名参数及省略键函数，
`std.length(std.sort)` 为 1。显式键函数每项调用一次，结果缓存后再比较；
返回数组保留原始元素 thunk，不修改输入，也不强制无关字段或常量键忽略的元素。

采用迭代稳定归并：相等键保留输入顺序，键支持数值、Unicode 字符串及
字典序数组比较。比较错误正常传播，比较涉及的数组键元素仍按需求值。
空数组检查显式键函数的类型，但不调用它；单项数组仍求键，但无需比较，
因此单项对象可通过而两个对象不可排序。这些边界均以 Go 契约核对。

键求值和归并移动计入步数预算，归并本身不增加递归深度。
2,000 项逆序输入和 100 项等键稳定性测试通过，受限步数会返回 `Limit`。
新增 4 组本地测试，修复前全部失败，修复后全部通过。

新增 28 条 Go 对照用例全部通过。共享语料原 `unsupported-sort` 用例保留
`std.sort([2,1])` 输入，改名为 `sort-default` 并改用成功断言，在 Go 和 C++
对照中均通过；这是真实消除一项未支持功能，未删除原始输入。

## 验证结果

| 验证 | 兼容通过 | 失败 | 已声明 C++ 差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（246 项） | 243 | 2 | 0 | 1 | 0 |
| 其中 Go 专用语料（138 项） | 137 | 1 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 98 | 0 | 9 | 1 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

新增 28 条详细排序用例属于 Go 专用语料，C++ 计数不包含它们。
既有 9 项 C++ 差异继续精确断言、单列且 `passed=false`。
完整 Go 差分仍返回非零，保留 `tailstrict` 上游内部错误和正 `2^63` 转换边界
两项差异。共享差分中剩余未支持项为 `sha256`；上游语言语料的两项未支持
依赖仍为 `setInter` 和 `mergePatch`。

零警告检查、debug/release 各 50 项测试、格式检查、文档生成和 release 构建通过；
`moon info` 未改变公开 MoonBit 接口。宿主/CLI 集成 27 项、打包消费者 3 项通过。
提交后 ASan 下 50 项测试和 27 项集成通过；泄漏检测关闭。
仅实测本机 macOS arm64，不代表完整标准库或其他平台已验证。

## 可追溯证据

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`；
  契约核对 `builtins.go` 的 `builtinSort`、`sortData` 和默认参数声明。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`82c21e0f2536c47beeab132769737d377a3ca597dde83dba6eafd33629b20cb8`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。生成物不提交，复现命令见
  [验证说明](../../development/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
