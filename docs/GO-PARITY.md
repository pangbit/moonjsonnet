# go-jsonnet 整体功能对齐

目标参考：google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。2026-10-02 用户将目标由首期子集
扩展为功能对齐；[首期需求](../MoonJsonnet_REQUIREMENTS.md) 中的子集限制是历史范围，
不能作为当前整体目标已经完成的依据。当前状态：**未完成整体对齐**。

核心解析、求值和运行时仍由 MoonBit 原生实现，不能通过运行 Go/C++ 解释器提供功能。
参考解释器只用于开发验证。MoonBit 嵌入接口按功能提供等价能力，不要求复制 Go 类型。

## 全量标准库清单

通过固定 Go 二进制实际运行 `std.objectFieldsAll(std)`，记录每个成员的名字、类型
和必需参数数目。冻结参考快照为 [go-stdlib-surface.json](../tests/go-stdlib-surface.json)，
包含 163 个成员（包括可反射的内部辅助成员和常量）。本次扩展前注册 42 个，缺少
121 个；加入摘要、集合、对象、数组组合、查找与极值后注册 85 个，缺少 78 个。

[逐项状态表](GO-STDLIB-SURFACE.md) 保留全部成员，缺失项不会因为没有差分用例而消失。
`registered` 仅表示名字、类型和必需参数数目相同，不表示默认值、惰性、错误、边界
或结果已经完全一致。复现命令：

```sh
moon run tools/parity.mbtx ${LOCAL_PATH_012}/jsonnet _build/native/release/build/cmd/main/main.exe
```

工具校验 Go 二进制提交及干净构建元数据、核对冻结快照，输出
`_build/parity/report.json` 和 `stdlib.md`，记录源码提交、工作区状态和二进制哈希。
报告明确 `behavioral_parity_proven=false`；清单生成成功不是兼容验收通过。

## 功能差距与推进顺序

下表来自本地固定参考的 `--help`、`vm.go`、标准库反射，以及本项目实际 API/CLI。
“部分”也属于未完成；完成一项必须同时补充行为测试和差分证据。

| 范围 | 当前状态 | 后续实现与验收 |
| --- | --- | --- |
| 语言核心 | 已实现主要语法和求值，完整语言等价尚未证明 | 扩大 Go 上游语言/错误/惰性语料覆盖；保留已知差异 |
| 数值、布尔标准函数 | 部分 | 补齐数学、比较、聚合、谓词及边界 |
| 数组、集合、对象 | 部分；集合、对象、组合、查找、极值和比较辅助已加入 | 删除、聚合与内部对象合并 |
| 字符串、编码、摘要 | 部分 | UTF-8/Base64、解析整数、转义、大小写、拆分、其余摘要函数 |
| 输出标准函数 | 仅基础 JSON | `manifestJsonEx`/minified、YAML、TOML、INI、Python、XML JSONML |
| 扩展参数 | JSON 值和字符串 | `ExtCode` 真正求值 Jsonnet；文件/环境变量参数、重置语义 |
| 顶层参数 TLA | 缺失 | 字符串/代码参数及顶层函数调用、默认值、错误传播 |
| 原生回调与 trace | 缺失 | 宿主函数注册、`std.native`、可配置 trace 输出 |
| 导入器 | 有定制文本/二进制解析及限定目录文件宿主 | `-J`、`JSONNET_PATH` 搜索顺序、依赖发现、导入查询接口 |
| 输入模式 | 文件和库内源码求值 | CLI `-e`、stdin、`--`、选项缩写；诊断文件名行为 |
| 输出模式 | 单个 JSON/文件 | 字符串输出、multi、stream、目录创建及对应嵌入方法 |
| CLI 参数兼容 | 部分 | 与参考完整 help 逐项核对，包括 `--output-file`、stack/trace 选项 |
| VM/AST 接口 | 一次性 evaluate | 可重用 VM、AST 解析/执行、缓存生命周期、依赖扫描的 MoonBit 等价接口 |
| 格式化器、静态分析工具 | 缺失 | 单独建立格式化/lint/工具接口语料，纳入整体覆盖状态 |
| 平台与交付 | native；实测 macOS arm64 | Linux 持续验证；其余参考平台和分发能力逐项核验，不凭本机结果推断 |

推进顺序：先标准库基础/集合对象能力，再参数、导入、输入输出及宿主接口，随后
格式化和分析工具，持续补齐语言边界与平台验证。`sha256` 消除现有差分中的最后一项
未支持函数，但远非完成标准库；全量清单仍有 78 个缺失成员。

待处理的数值边界：固定 Go 的 `sum`/`avg` 使用未检查溢出的累加，可产生 Infinity，
`std.sum([1e308,1e308])` 实际直接输出 `+Inf`。实现聚合时需同时验证非有限值传播、
比较、转换及输出，不能用现有有限数检查替代后便宣称对齐。

集合与合并使用固定 Go 参考内嵌的 Apache-2.0 Jsonnet 标准库源码，由本项目
MoonBit 求值器执行。每次 evaluate 解析一次，导入共享 AST，各文件的 `thisFile`
独立绑定。仅启用已验证依赖的成员，原生函数覆盖对应字段；源码提取工具校验参考
提交和源文件状态，来源与许可保留在 NOTICE 和内嵌头部。

## 完成标准

1. 所有参考成员和 CLI/嵌入/工具能力均有实现与对应测试，或有用户明确接受的例外。
2. 对照运行保留成功、错误、未支持、行为差异的独立计数；不能移除失败输入来达标。
3. 测试覆盖默认/命名参数、惰性、Unicode、继承、资源预算和异常边界。
4. 实现提交与验收记录绑定；本地、跨平台、远端 CI、发布分别记录，不相互替代。
5. 四个已知差异（Go `tailstrict` 内部错误、不可表示的正 `2^63` 转换、
   `objectRemoveKey` 处理继承对象与对象局部绑定时的两项内部崩溃）继续作为差异，
   不为追求数字相同而复制崩溃或实现相关的越界转换；是否作为最终兼容例外另行明确。

最新证据见 [验证说明](VALIDATION.md)。整体功能完成前，README/版本输出继续标明子集状态。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. No tests were rerun on the privacy-rewritten commit.
