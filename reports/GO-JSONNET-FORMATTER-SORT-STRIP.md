# 排序排列、注释删除与广语料检查

日期：2026-10-05。实现提交 `3cfaa54368f2c3bf0bc718a3fda14f37c6b885d8`；
上游语料检查工具提交 `970b7f8`。两个检查均在对应干净提交执行。
冻结差分 **359/359**；上游真实输入差分 **126/178，保留 52 项失败**。
这些结果不表示整体格式化或项目功能对齐。

## 实现与证据

导入排序移植 Go 1.24.0 `sort.Slice` 使用的 pdqsort，包括小数组插入排序、
枢轴选择、重复键分区、局部插入排序、模式打散与堆排序回退，使同路径绑定的
排列与固定参考一致。保留 BSD 许可和 NOTICE 归属。白盒测试验证 13 项重复键
的参考排列，并覆盖 12 个规模、5 种分布及强制堆排序回退的有序性和元素完整性。

删除注释按 LineEnd、Paragraph、Interstitial 分类处理，保留 Go 在删除前
已插入的行尾及空行缩进，修复上一批三项注释差异。原 177 项输入未移除，新增
98 项排序及 84 项注释边界，共 359 项（353 个有效输入、6 个错误输入）。
41 项参考非幂等行为按冻结标记核验，没有要求参考自身必须幂等。

固定 go-jsonnet v0.21.0 提交 `67968688d9952f50662e979fab1bef889d0d3e57`；
Go 1.24.0，`GOWORK=off`、`GOPROXY=off`。macOS arm64，Moon 0.1.20260920，
MoonBit v0.10.14+7d59c7ec9。

| 文件 | SHA-256 |
| --- | --- |
| 本地格式化探针 | `e05fefd7af1ef37de16ae91ceabeb866437a2a18d42e12b69718d6739ec5863a` |
| Go 格式化探针 | `e266569cc32bb7ddc8766dacf49e5a92e684d2c8ef67e900b586dd69bfdc67e4` |
| Go 适配器 | `fbce4353eaeed424d9bb061e8d87b5eefdb628fa9a1b6a606e35d1e30c4d5533` |
| 冻结语料 | `31549ff36643ae891791b69057d24f0d6510916d9fa642f141284761766e5d63` |

## 验证

`moon info`、`fmt`、native `check --deny-warn`、`fmt --check`、`doc`、release build
均通过，无接口签名变化。native 调试及发布测试各 **235/235**；独立归档消费者
**23/23**。ASan 通过 235 项测试、183 项宿主检查、33 项依赖 fixture、13 项依赖
CLI、30 项参数、21 项本地 Evaluator 序列、173 项本地 AST/源码检查和 23 项 lint CLI。
ASan 隔离工具链并禁用 mimalloc，`detect_leaks=0`、错误退出码 99；不构成泄漏证明。
完整 Go 格式化差分使用发布探针，不宣称 359 项均运行于 ASan。

ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.78267.e2d60088`。
消费者目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.78341.109337da`。
冻结报告：`_build/formatter/report.json`（实现提交，`source_dirty=false`）。

## 广语料未通过项

新工具按固定 C++ v0.21.0 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4` 的
`test_suite/run_fmt_tests.sh` 输入范围，读取 test_suite、examples、examples/terraform、
benchmarks、gc_stress 直接子目录的 Jsonnet 文件，排除 error.parse.*，共 178 项。
只使用这些源码作为输入，预期输出来自固定 Go 格式化器，不使用 C++ 格式化结果。
报告保留全部输入、两端完整输出、错误、幂等性、提交及二进制身份。

工具提交干净运行结果：126 通过、52 失败；Go 错误 0，本地探针错误 3。
`examples/top-level-ext.jsonnet` 格式化后重新解析失败；`test_suite/format.jsonnet`
和 `test_suite/stdlib.jsonnet` 命中本地默认语法树深度限制。其余差异涉及布局、
注释和复杂导入分组，均保留为失败，没有归为兼容例外。
报告为 `_build/upstream-formatter/report.json`，临时目录
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-upstream-formatter-.87483.6f6c71a6`。

```sh
moon run tools/formatter-integration.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012}
moon run tools/upstream-formatter.mbtx _build/native/release/build/examples/formatter-probe/formatter-probe.exe ${LOCAL_PATH_012} ${LOCAL_PATH_006}
```

第二条因保留的 52 项差异返回非零。完整 Go CLI、C++ CLI、Go AST/lint 本批未重跑，
历史结果仍绑定此前提交。Go CLI 18 项、lint 参考崩溃、Evaluator 缓存差异、
FormatNode/jsonnetfmt 等整体缺口继续保留。仅本地提交，未推送或发布。

> Privacy redaction: This public copy replaces environment-specific host and filesystem identifiers with placeholders. Unredacted evidence and original recorded hashes are retained locally. Counts and outcomes describe the original execution; exact diagnostic and path bytes may be redacted. The privacy rewrite did not rerun the original validation. Any subsequent CI run is separate evidence.
