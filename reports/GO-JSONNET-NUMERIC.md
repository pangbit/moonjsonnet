# go-jsonnet 对齐进展：索引与位运算

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`e6e90b597ed83dfdcab6dbb3f59b213f06fa6602`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前结果见 [函数契约记录](GO-JSONNET-CONTRACTS.md)。

## 本批修复

- 数组和字符串索引按 Go 行为向零截断，再检查边界；包括 `-0.9` 选取首项。
  字符串仍按 Unicode 码点索引，巨大数值在转换为机器整数前即被拒绝。
- 切片保留小数起点、终点和步长的推进过程，逐项截断实际索引；
  未使用元素保持惰性，极小正步长仍受求值步数限额约束。
- 二元位运算接受 `[-2^63,2^63)` 范围的操作数，截断后使用有符号 64 位运算；
  左移按 64 位回绕，右移保留符号，位数取模 64，负位数在截断前报错。
- C++ 差异断言支持静态/运行时错误类别，继续精确核对本项目的 JSON 结果。

新增 6 组本地测试：修改前 5 组失败，修改后全部通过。新增 21 条 Go 用例中
20 条对齐，1 条记录新发现的边界差异。原有 `noninteger-index`、`slice-fraction`、
`bitwise-range-error`、`bitwise-overflow-error` 四处 Go 差异已消除，输入全部保留。

## 验证结果

| 验证 | 兼容通过 | 失败 | 已声明 C++ 差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（176 项） | 170 | 4 | 0 | 2 | 0 |
| 其中 Go 专用语料 | 67 | 1 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 99 | 0 | 7 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

Go 失败数从 7 变为 4：消除原有 4 项，新增发现 1 项。完整 Go 差分仍返回非零，
没有将该边界输入改记为通过、跳过或未支持。C++ 的 7 项差异单列且
`passed=false`；其余输出或错误类别变化仍使检查失败。

零警告检查、debug/release 各 34 项测试、格式检查、文档生成、release 构建通过；
`moon info` 未改变公开接口。宿主/CLI 集成 27 项、打包消费者 3 项通过。
提交后 ASan 下 34 项测试和 27 项宿主集成通过；泄漏检测关闭。
仅实测本机 macOS arm64，不代表已完成其他平台或远端 CI 验证。

## 新发现的边界与剩余差异

`9223372036854775808 & 1` 的操作数是正 `2^63`，超出 `Int64` 可表示范围。
固定 Go 实现的浮点范围判断允许该值，本机返回 `1`。超出可表示范围的浮点到
整数转换结果在 [Go 规范](https://go.dev/ref/spec#Conversions_between_numeric_types)
中属于实现相关行为。本项目明确返回 `Runtime`，避免对越界值执行原生转换。
该输入以 `bitwise-int64-upper-boundary` 保留在 Go 失败列表中。

当前语料中剩余 4 项：

- `format-dynamic-fractional`：小数精度格式化的末尾数字不同。
- `numeric-string-rendering`：`manifestJson({x:0.1})` 的数字文本不同。
- `tailstrict`：固定 Go 版本发生内部错误，本项目保留正常结果。
- `bitwise-int64-upper-boundary`：上述有意保留的确定性范围错误。

下一批处理数值文本和格式化差异。新增的 C++ 差异中，范围字面量用例
`bitwise-range-error` 在 C++ 中为 `STATIC ERROR`；另外三项为 `RUNTIME ERROR`。
断言按实际错误类别及本项目结果核验，不笼统接受任意非零退出。

## 可追溯证据

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`0aee2e9a1b515da37a120f593fa52f01df3726a5f2616d30e45c33356d7c55f1`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。生成物不提交，复现命令见
  [验证说明](../docs/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
