# 格式化续批验收与深度分析

日期：2026-10-08。起点为干净 `main`，HEAD
`b973b669e705903afeaf44da3f24c0292c6e397f`。仅本地提交，未推送或发布。
最终实现提交 `30548ae8953ed85ef027d3bd1dfd23eaca67a6c0`；整体功能和格式化对齐仍未完成。

## 分阶段实现与验证

| 实现提交 | 修复范围 | native 普通/release（各） | 冻结 Go 用例 | 上游真实输入 |
| --- | --- | --- | --- | --- |
| `e4671b5f51bd36b957bebf6b88c54b5eb0edd759` | 多行计算字段名不再作为数组展开或添加尾逗号 | 237/237 | 360/360 | 127/178 |
| `bea7a83940e3e587501f4dc922c1a033b60899c2` | 注释前空行、MaxBlankLines、Indent=0 原始注释列 | 238/238 | 385/385 | 146/178 |
| `517944f07cd5a7372031b9c7791724181549f876` | 相邻行内块注释间距、换行后 token 间距、导入组的 clean newline | 239/239 | 392/392 | 147/178 |
| `30548ae8953ed85ef027d3bd1dfd23eaca67a6c0` | 首行/末尾换行时保留参数行，单独成行的逗号对齐 | 240/240 | 402/402 | 148/178 |

首阶段补丁 `${LOCAL_PATH_024}` 的 SHA-256 为
`681f169f95573bc4e2217f780496ca7f4cc29b9a2d505d3b1e8ab41c759d8b29`。
应用前核验存在、内容和 `git apply --check`，范围确为四文件、61 行新增、2 行删除；
应用后只暂存这四文件提交。之后各阶段同样只暂存对应实现和回归语料。

每阶段均执行 `moon info`、`moon fmt`、native `check --deny-warn`、普通/release
测试、release build、`fmt --check`、`moon doc` 和 `git diff --check`，全部通过。
没有公开接口变化。新增测试覆盖重新解析、稳定用例幂等性、求值结果及惰性导入请求
顺序；冻结语料继续核验 Go 自身的非幂等标记，没有删除原用例或放宽比较。

历史材料 `${LOCAL_PATH_023}`、`.py` 已核验。原上游报告哈希为
`f32611f80a5777582a10a0f1266bde320a9edd20192c13fd4feb27aa0ebc9eab`，与历史重放记录
一致。使用原脚本对本次发布探针重放，得到 360/360、127/178、零回归，保存在
`${LOCAL_PATH_022}`；该步骤仅重放保存的 Go 输出。
随后本次四阶段均重新构建并运行固定 Go 参考，结果见上表；不能混淆两类证据。
各阶段的完整 Go 报告另保存为 `${LOCAL_PATH_025}{frozen,upstream}.json`
（N 为 1 至 4）。前三阶段证据在对应提交前生成，记录父提交及 `source_dirty=true`；
第四阶段另在干净实现提交上重新运行，两个最终报告均为 `source_dirty=false`。
逐阶段比较全部 178 项输入、Go 结果和通过集合，新增回归均为 0。

固定 Go：v0.21.0，`67968688d9952f50662e979fab1bef889d0d3e57`；Go 1.24.0，
`GOWORK=off`、`GOPROXY=off`。固定 C++ checkout
`bbb38f1020be1f5aed560928fb839b2c448cefb4` 只提供输入，不提供格式化预期。
两个参考 checkout 均核验为干净。环境为 macOS arm64，Moon 0.1.20260920、
MoonBit v0.10.14+7d59c7ec9。

## 最终证据身份

| 文件 | SHA-256 |
| --- | --- |
| 本地 release 格式化探针 | `4fd4cb3052d1dca0a25afae012161822bb205db7c5b69cb83824b09767cb024b` |
| 固定 Go 格式化探针 | `e266569cc32bb7ddc8766dacf49e5a92e684d2c8ef67e900b586dd69bfdc67e4` |
| Go 适配器 | `fbce4353eaeed424d9bb061e8d87b5eefdb628fa9a1b6a606e35d1e30c4d5533` |
| 冻结语料 tests/go-formatter.json | `83c7a2d1f5d0c2c07e67ab826f256ce3a36b57bf3b931311b1623bb3fe0e9778` |
| 最终 _build/formatter/report.json | `688506e4f64f64c1f5d8bbff22aa63b1ba32ae34e87c3eec798cebcbf21b0b7f` |
| 最终 _build/upstream-formatter/report.json | `54c404a30c5918868e1dbcce1377c75a83d53e7b8fb0d5459f0a852b6b95732a` |

复现命令见 [验证说明](../docs/VALIDATION.md)。冻结 runner 返回 0；上游 runner 因
30 项保留失败返回 1。Go 错误为 0，本地错误为 2。本批未重跑完整 Go/C++ CLI、
AST、lint、ASan、消费者或跨平台验收；旧结果仍绑定原提交。

## 两项深度失败

审计完整路径：`format_source` → `ParsedSource::parse` → `parse_tokens` →
`Parser::expr` → `check_ast_depth`。错误出现在格式化布局前的完整 AST 准入检查。
Pratt 的左结合运算构造在循环内，AST 左支可以远深于解析器调用栈。

临时白盒诊断保持解析器递归预算 200，在最终 AST 深度检查之前取得树，再用显式
栈遍历所有子节点，包括 lint 子节点遍历省略的对象断言，测量最大深度与链结构。
这是测量手段，不是绕过准入的产品实现，也不计为上游通过。

| 输入 | 节点数 | 最大 AST 边深度（根为 0） | 最小解析递归预算 | 最长左支 && 链 |
| --- | --- | --- | --- | --- |
| test_suite/format.jsonnet | 3203 | 244 | 6 | 241 |
| test_suite/stdlib.jsonnet | 7569 | 300 | 21 | 295 |

stdlib 最深路径含 296 个 && 节点和 1 个 local 节点。当前 `Limits.depth` 默认 200，
`check_ast_depth` 在任意节点深度达到预算时拒绝；两项分别保持 72:47、157:20 的
`syntax tree depth limit exceeded`。未改变默认值、512 硬上限、AST 深度语义或准入。
首阶段的平坦表达式边界回归仍保留，并验证显式预算与默认预算的区别。

后续实现也已检查：格式化的结构重写和深度检查采用显式栈，但 `ParsedSource::ast`
调用的 `export_ast`、作用域 `validate` 及求值仍有递归路径。共享解析及缓存复用入口
也调用完整 AST 深度检查。仅提高预算或跳过这道检查不能证明整个生命周期支持深树。
后续应先设计并验证迭代解析后处理/导出及独立的格式化准入契约，保持求值预算，
再处理这两项差异；本次没有将它们归为用户接受的兼容例外。

诊断材料保留于 `${LOCAL_PATH_007}` 和
`${LOCAL_PATH_008}`，后者也在 `_build/formatter-depth-audit.json`。
SHA-256 分别为 `bc4cfb74a4b79ec3da73de84196b9fa507f6b3db4fd495028e60e564e9f10243` 和
`cf32651ddbca51df35c41b0d9a2cbbb124204a69fa17a2d5d2fcedad31e9dff0`。
仓库中的临时审计文件已移出，原测试和新增正式回归均保留。

## 剩余 30 项与下一步

完整失败集合保留在最终上游报告，未跳过任何输入：

```text
benchmarks/bench.01.jsonnet
benchmarks/bench.03.jsonnet
benchmarks/bench.08.jsonnet
benchmarks/gen_big_object.jsonnet
examples/arith.jsonnet
examples/error-examples.jsonnet
examples/functions.jsonnet
examples/mixins.jsonnet
gc_stress/long_chains.jsonnet
test_suite/comments.jsonnet
test_suite/condition.jsonnet
test_suite/dos_line_endings.jsonnet
test_suite/error.invariant.option.jsonnet
test_suite/error.recursive_function_nonterm.jsonnet
test_suite/format.jsonnet
test_suite/formatter.jsonnet
test_suite/formatting_braces.jsonnet
test_suite/formatting_braces3.jsonnet
test_suite/import_sorting_multiple_binds_and_comments.jsonnet
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

其余 28 项没有本地错误，但输出或参考幂等性仍不同。下一步优先按完整表达式的
起始列处理二元表达式续行、local/条件分支、切片和字段函数布局，再处理多行块注释
的原始 margin 及归属。导入重排后重新词法化会丢失原始块注释列，仅在最终打印时
按新列裁剪不足以对齐，应在移动前保留注释语义。复杂导入分组、文本块、
FormatNode/jsonnetfmt 接口等继续属于未完成范围。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. The privacy rewrite did not rerun the original validation. Any subsequent CI run is separate evidence.
