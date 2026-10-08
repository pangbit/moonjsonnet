# 可编辑原始语法树与节点格式化验收

日期：2026-10-08；干净实现提交 `aab2f4c09cc342ba3f8b421fd296dda3ab10b42f`。
新增 RawAst/RawNode/RawPart/RawNodeKind、SyntaxDocument::raw_ast、迭代复制和
format_node。固定 Go 的类型按功能对照，不要求复制其 Fodder 表示。

原始树保留表达式、括号、声明、参数、实参、对象成员和推导式子句的层次。
有序 parts 是编辑的权威来源：每个 token、空白、注释及其 UTF-8 范围恰好一次，
EOF fodder 独立保留。原始 range/kind 为解析时元数据，编辑后重解析刷新。
复制对每个共享子节点出现位置建立独立容器，不修改文档或缓存。构建、导出、
复制和序列化均采用迭代栈，检查完整树/节点/工作量预算；循环编辑有界失败。
深度 4000 的平坦二元树使用 parser_depth=8 通过，不放宽旧求值预算。

format_node 序列化编辑后的表达式，按独立 SyntaxLimits 重解析并格式化，
不执行表达式或导入，不修改传入数组。声明/参数片段需要先放入完整表达式。
新增 56 项实际 Go AST 编辑对照：数字、字符串、数组增删、变量声明/使用改名、
首尾注释编辑，各用八组格式选项。冻结结果来自固定 Go，保留其重解析/幂等标记。
既有冻结和上游探针也逐项检查 raw.text()==source、format_node==源码入口；
Go 适配器同样交叉检查 SnippetToRawAST/FormatNode 与 Format，没有改旧预期。

| 验证 | 结果 |
| --- | --- |
| info / fmt / check --deny-warn / build --release / fmt --check / doc / diff --check | 通过；公开接口新增原始树与节点格式化 |
| native 普通 / release | 各 269/269 |
| 干净提交实际 Go 节点编辑 | 56/56；0 错误/跳过/未支持/声明例外 |
| 干净提交冻结 / 上游格式化 | 736/736、178/178；上游 Go/本地错误均 0 |
| 干净提交语义 AST / jsonnetfmt | 173/173、255/255；另 4 项 branding/help 检查 |
| 独立 archive 消费者 | 25/25，调用所有新公开方法 |
| 干净提交整体 Go CLI | 1132/1150；483 个预期错误，原 18 项差异保留，0 跳过/未支持/声明例外 |
| 干净提交 lint | 409/410；190/190 位置检查，原 1 个参考 panic 保留 |
| 干净提交 Evaluator | 20/21；88 个观察、62 个求值、26 个查询、10 个预期错误，原失败解析缓存差异保留 |
| 隔离 ASan | 269 项 native、完整既有宿主/API、新 formatter 宿主及本地冻结节点编辑 56/56 全通过；leak 检查禁用 |

ASan 的本地 Evaluator 21/21 和 AST 173/173 是冻结预期验证，不能替代上表的
新鲜 Go 对照。副本为 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.86959.8127f331`，
复制完成后才开始下一阶段；下面三个实现文件与副本 SHA-256 一致。

固定 Go `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，GOWORK=off、
GOPROXY=off、checkout 干净。C++ `bbb38f1020be1f5aed560928fb839b2c448cefb4`
仅提供上游输入。macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
八份原始 Go 报告均绑定上述实现提交和 source_dirty=false。

| 证据 | SHA-256 |
| --- | --- |
| raw_ast.mbt | `69714469372b2bfd2d87b5aa1021b710556a1d487a7e43c5aa0035d651d5625d` |
| raw_ast_edit.mbt | `9867a682ae693be3206a4e2f5f8c032a48222d84373e5d7ac03529d01460dace` |
| parser.mbt | `6b6174c50c00dc6808533b16efa3e0a607dbcbe49797e5e9d8fe30686d83ab7b` |
| tests/go-formatter-node.json | `f18309fc56c6102667f28f4f53f3dff4b32fd5d0706d18deece54cdfa72d7bd6` |
| release formatter-probe | `51a8eaf4d923d7a934eb3d16a0a718bd7297a03dd8f5e0d97c65d2dda62a82ec` |
| release formatter-node-probe | `2f731d7631ab0913335024f3d29f31bc8b89b66a71e8b48c574ff867f80f75c3` |
| _build/formatter-node/report.json | `4d3d10b861a0c35b3dd04bbd062e59e1897f71afa6ce70f7ae02eaeb03253b4b` |
| _build/formatter/report.json | `48dac8eb0b5338da46f148531e3296c4b2cbf41f849e052a5358f52f4487ad21` |
| _build/upstream-formatter/report.json | `909ae167c800845c38c88003adbdf1acbfa0e3dad809b99accd5fa4b441150e0` |
| _build/ast/report.json | `03bb216c090410269b590ea78c86b401cf3c899eb70327aa72f582661e39e33c` |
| _build/formatter-cli/report.json | `652c0cc47ae07e916279dd59b870a41a335fd8ec81c9bebb4b2302d13312bb71` |
| _build/go-differential/report.json | `90349a09caa41a9680b511d43af5ae807f960dbdbe07a4b195767f9a8fe20df9` |
| _build/lint/report.json | `ef3458353f5c05f57717dd80e658c3841b7a77801ba6a9c134ed0ce685f4d53e` |
| _build/evaluators/report.json | `924c2465efaa6107e122981a557ba010d1e6d0a87f07bcef0b5bae5a66563df4` |

完整诊断/命名及合成帧、EvalHook/调试器、Linux 真实平台与最终交付核验继续推进。
参考自身崩溃、AST 缓存和 lint panic 尚未获得兼容例外确认，仍计为失败。
没有推送、部署或发布，未安装软件或创建额外平台环境。
