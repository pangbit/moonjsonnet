# go-jsonnet 对齐进展：函数契约

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`88517f8a347ea279c06e5782b495070c26f02e74`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前的序列函数验收保留在 [首批记录](GO-JSONNET-PROGRESS.md)。

## 本批修复

- `std.length(function)` 只统计没有默认值的参数，不求值默认表达式。
- `std.foldl` 按 Go 行为求值函数、序列、初始值及每轮回调返回值；
  未使用的数组元素、累加器对象字段仍保持惰性。
- 将折叠改为迭代调用，避免先构造整条惰性调用链；2,000 次求和在默认
  深度限制下通过，同时保留步数限额检查。
- 新增 5 组本地测试、16 条 Go 差分用例。原有输入全部保留；
  `fold-lazy`、`fold-empty` 的 Go 预期改为运行时错误。

修改前，新测试中函数参数计数、强制求值和长折叠共 3 组失败；修复后全部通过。
Go 既有差异从 10 处降至 7 处，消除 `fold-lazy`、`fold-empty`、`length` 三项。

## 验证结果

| 验证 | 兼容通过 | 意外失败 | 已声明参考差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（155 项） | 146 | 7 | 0 | 2 | 0 |
| 其中 Go 专用语料（包含首批 31 项和本批 16 项） | 47 | 0 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 103 | 0 | 3 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

Go 完整差分仍退出非零，不宣称全面兼容。兼容通过、失败、参考差异和未支持
互斥计数；已声明差异不会被计入通过。

其他验证：零警告检查、debug/release 各 28 项测试、格式检查、文档生成和
release 构建通过；`moon info` 未产生公开接口变化。宿主/CLI 集成 27 项、
打包消费者 3 项通过。提交后 ASan 下 28 项测试及 27 项宿主集成全部通过；
泄漏检测关闭。

## C++ 契约迁移的验证

| 原有用例 | C++ v0.21.0 | MoonJsonnet（对齐 Go） |
| --- | --- | --- |
| `fold-lazy` | 返回 `2` | `Runtime` 错误 |
| `fold-empty` | 返回 `1` | `Runtime` 错误 |
| `length` | `[1,2,2]` | `[1,2,1]` |

共享语料的 `cpp_difference` 明确记录以上结果。工具逐项验证参考 JSON 与
MoonJsonnet JSON/错误类别，标记 `reference-difference`、`passed=false`。
只有结果精确符合记录时才接受；任何变化或意外趋同均使回归检查失败。
其余未声明差异沿用原失败规则。

用上一版 release 二进制进行反向验证时，这 3 条均被正确拒绝，退出非零；
新二进制则验证 3 条差异通过。原始反向验证报告保存在本地
`_build/differential/previous-binary-report.json`，不提交生成物。

## 剩余工作与证据

Go 仍有 7 条差异：`format-dynamic-fractional`、`numeric-string-rendering`、
`noninteger-index`、`slice-fraction`、`bitwise-range-error`、
`bitwise-overflow-error`、`tailstrict`。下一批核对索引及位运算边界；
数值文本差异继续保留。`tailstrict` 触发的是固定 Go 版本的内部错误，
本项目保留正常结果，不复制该崩溃。

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`d17e96007fd8407ce9741130e9d7a8d00e5ed01d740fa68ae9ff18dc70d489a6`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。复现命令见 [验证说明](../../development/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
