# go-jsonnet 对齐进展：flatMap 与 foldr

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`ae6b6c014b78f94d6352328830b12d975c2cf476`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前结果见 [小数精度格式化记录](GO-JSONNET-FORMAT.md)。

## 本批实现

- `std.flatMap(func,arr)` 支持数组和 Unicode 字符串。逐次调用回调并求值
  返回的数组/字符串，只拼接一层；数组输入元素和返回数组中的元素保持惰性。
  字符串按码点调用回调，返回值必须为字符串，`null` 不会被忽略。
- `std.foldr(func,arr,init)` 从右向左迭代，回调参数依次为元素、累加值。
  与现有 `foldl` 共用迭代框架，初值和每次回调结果均求值，元素及对象字段
  仍保持惰性。2,000 项求和通过默认深度限额。
- 展平数组逐项计入步数预算；字符串使用 builder 累积，并在追加前检查
  UTF-8 字节限额，避免通过最终只取长度来绕过中间结果限额。

新增 5 组本地测试，修改前全部失败，修改后全部通过；新增 30 条 Go 用例全部
通过。覆盖命名参数、默认参数、关联方向、Unicode、空输入、惰性、回调求值、
类型及参数错误、函数反射和输入保持不变。类型错误使用本项目 `Type` 类别，
参数/回调运行错误使用 `Runtime`；Go 差分核对成功值或双方失败，本地测试
进一步核对本项目结构化错误类别。

## 验证结果

| 验证 | 兼容通过 | 失败 | 已声明 C++ 差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（218 项） | 214 | 2 | 0 | 2 | 0 |
| 其中 Go 专用语料（110 项） | 109 | 1 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 97 | 0 | 9 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

新增 30 条用例属于 Go 专用语料，C++ 通过数不包含它们。
C++ 的 9 项既有参考差异继续以精确断言检查，单列且 `passed=false`。
Go 完整差分仍返回非零：保留 `tailstrict` 上游内部错误和正 `2^63` 转换边界
两项差异，没有将它们改记为通过、跳过或未支持。

零警告检查、debug/release 各 46 项测试、格式检查、文档生成和 release 构建通过；
`moon info` 未改变公开 MoonBit 接口，Jsonnet `std` 新增两个隐藏函数。
宿主/CLI 集成 27 项、打包消费者 3 项通过。提交后 ASan 下 46 项测试和
27 项集成通过；泄漏检测关闭。仅实测本机 macOS arm64。

## 可追溯证据

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`；
  契约核对该 checkout 的 `builtins.go` 中 `builtinFlatMap` 和 `builtinFoldr`。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`0c25f448a98ec8ae24c68487837a790892430d1767f1334d83bbd18eb2b68a17`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。生成物不提交，复现命令见
  [验证说明](../../development/VALIDATION.md)。

标准库仍为 [明确列出的子集](../../reference/COMPATIBILITY.md)，本批未实现 `sort` 或
`sha256`。本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
