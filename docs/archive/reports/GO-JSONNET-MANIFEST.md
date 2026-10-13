# go-jsonnet 对齐进展：数字序列化

日期：2026-10-02。环境：macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9，native 后端。

源码提交：`b6c22343dc0cf957cdf290cc4c98ce00c86e5449`。
Go/C++ 差分在该提交的干净工作区复跑，`source_dirty=false`。
此前结果见 [索引与位运算记录](GO-JSONNET-NUMERIC.md)。

## 本批修复

`std.manifestJson` 使用最短可往返还原原数值的十进制数字，并展开科学计数法，
匹配固定 Go 版本的 `strconv.FormatFloat(value, 'f', -1, 64)` 行为。
实现复用 MoonBit core 的最短浮点转换，展开指数并保留负零，不增加 C FFI。
例如 `0.1` 输出 `"0.1"`，`1e-8` 输出 `"0.00000001"`。

`std.toString`、字符串拼接及 `%s` 保持原来的数值转换契约；
排序、缩进、隐藏字段和输出字节限额仍受回归测试约束。
最小正次正规数 `5e-324` 展开为 326 字节，限额 326 时成功，325 时返回 `Limit`。

新增 4 组本地测试：修复前 3 组失败，修复后全部通过；新增 7 条 Go 差分用例
全部通过，涵盖负零、指数切换边界、最大有限数、次正规数、嵌套对象和数值往返。
共享 `numeric-string-rendering` 的输入保留，现对齐 Go；C++ 的原始字符串结果
及本项目结果均以精确断言记录，单列为参考差异，不计兼容通过。

## 验证结果

| 验证 | 兼容通过 | 失败 | 已声明 C++ 差异 | 未支持 | 跳过 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Go 完整差分（183 项） | 178 | 3 | 0 | 2 | 0 |
| 其中 Go 专用语料（75 项） | 74 | 1 | 0 | 0 | 0 |
| C++ 共享差分（108 项） | 98 | 0 | 8 | 2 | 0 |
| C++ 上游语言/格式化语料 | 301 | 0 | 0 | 2 | 0 |

零警告检查、debug/release 各 38 项测试、格式检查、文档生成、release 构建通过；
`moon info` 未改变公开接口。宿主/CLI 集成 27 项、打包消费者 3 项通过。
提交后 ASan 下 38 项测试和 27 项集成通过；泄漏检测关闭。
仅实测本机 macOS arm64，不代表其他平台或远端 CI 已验证。

## 剩余差异

- `format-dynamic-fractional`：仍为小数精度格式化的末尾数字不同。
  已定位到底层幂运算差异：MoonBit `@math.pow(10,1.5)` 为
  `31.622776601683793`，固定 Go 的 `std.pow(10,1.5)` 为
  `31.6227766016838`，按 binary64 位模式相差 2 ULP。
  本批不改动幂运算或格式化算法，保留原失败输入供后续处理。
- `tailstrict`：固定 Go 版本发生内部错误，本项目保留正常结果。
- `bitwise-int64-upper-boundary`：本项目拒绝不可表示的正 `2^63` 转换，
  原因见上一批记录。

完整 Go 差分仍返回非零；上述输入未被改记为通过、跳过或未支持。

## 可追溯证据

- Go 参考：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`，
  数字规则见该 checkout 的 `builtins.go` 中 `builtinManifestJSONEx`。
- C++ 参考：v0.21.0，`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
- 本批 release CLI SHA-256：`8dfcd3f6e6e4ad08a3117ab4a296b3ae0259aacb10517ff6974a5d2ce14386d8`。
- 本地报告：`_build/go-differential/report.json`、`_build/differential/report.json`、
  `_build/upstream-language/report.json`。生成物不提交，复现命令见
  [验证说明](../../development/VALIDATION.md)。

本批仅本地提交，未推送、未运行远端 CI、未发布 Mooncakes。
