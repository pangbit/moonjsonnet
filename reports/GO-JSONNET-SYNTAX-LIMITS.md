# 独立深树语法契约验收

日期：2026-10-08；实现提交 `824fd43f418b32340a4540b173eddacda5301c4c`。
新增 `SyntaxLimits`、`SyntaxDocument` 与 `format_syntax_source`，分别限制解析递归、
完整树深度、节点数、格式化步骤、源 UTF-8 字节和输出字节。默认解析递归仍为
200（硬上限 512），独立树深度为 4096（硬上限 16384）；节点与步骤各 1,000,000，
源 1 MiB、输出 4 MiB。旧 `Limits`、Program、ParsedSource、format_source 的
准入行为不变，导出语义 AST 后用于执行仍须经过 Program 的独立验证。

格式化规划显式携带父节点已覆盖的缩进上下文，避免长左二元链重复覆盖整个
子区间；每个不同区间和扫描仍计入步骤。没有提高步骤默认值或跳过完整树
准入。新黑盒测试在解析递归预算 8 下完成 4000 层平坦树的导出、格式化及
重新解析/幂等核验；同时证明旧解析和 Program::from_ast 仍拒绝这棵树。
边界测试包括全部子节点计数、对象断言、默认参数、推导子句、递归解析、UTF-8
字节、较窄预算重新准入、输出/步骤限制、语法错误及返回容器复制隔离。

格式化 probe 现明确调用 `format_syntax_source`；原始报告新增 `local_entrypoint`
字段。178/178 只证明这一显式入口在当前上游语料通过，不代表旧入口自动放宽。
原 736 项冻结 fixture 未改，固定 Go 自身非幂等标记仍原样核验。

| 验证 | 结果 |
| --- | --- |
| check / release build --deny-warn | 通过 |
| native 普通 / release | 各 256/256 |
| info / fmt / fmt --check / doc / diff --check | 通过；.mbti 仅新增语法工具公开接口 |
| 干净实现固定 Go 格式化 | 冻结 736/736；上游 178/178；Go/本地错误均 0 |
| 全部上游集合对比 | 原 176 项无回归；format.jsonnet 与 stdlib.jsonnet 新增通过 |
| 干净实现固定 Go AST | 173/173 |
| 干净实现完整 Go CLI | 1132/1150；18 项原失败、0 跳过/未支持/声明例外、483 项预期错误 |
| 独立 archive 消费者 | 24/24，包含新的公开类型与深树调用 |
| 隔离 ASan | 256 项 native 及整套既有宿主集成通过，leak 检查禁用 |

格式化/AST/CLI 原报告均记录实现提交及 `source_dirty=false`。固定 Go v0.21.0
提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0、GOWORK=off、
GOPROXY=off；C++ `bbb38f1020be1f5aed560928fb839b2c448cefb4` 仅提供输入，
两 checkout 干净。环境 macOS arm64，Moon 0.1.20260920 / MoonBit
v0.10.14+7d59c7ec9。复现命令见 [VALIDATION](../docs/VALIDATION.md)。

| 证据 | SHA-256 |
| --- | --- |
| syntax_document.mbt | `0ae9fd2abbf911a85308adde760f40874aaaadaaf116451b17d38d8907ffff62` |
| formatter_indent.mbt | `0a6843b094aa1746c4f3b9e9ecb852472ea858813cec0500f7a186b0b77edf8c` |
| tests/go-formatter.json | `c062f59ef8ec74f101cda68711884bd0339031b4c0fed7cd3519212c2c59f95d` |
| release formatter probe | `d6f2a432162c209689aa8854302a2ddca4ae5f3c9eaba88704685aeba6957272` |
| _build/formatter/report.json | `d080fc971f4d71418f0e2fc7f473abb7c766f7a1ff783a66f3d9ce90711d21c1` |
| _build/upstream-formatter/report.json | `e8fb4f83451dad5965a80f3b1c6acad2ee6ecd14975823be557a9233978df422` |
| _build/ast/report.json | `1d90231a9bdf2adff5a77fcd8da68e8cfbfda507c20099ea6cfd33a9b00b4303` |
| _build/go-differential/report.json | `6912078cd8939668f9dd6e9aa3b553c653bcde3fc1d883cd2ada84e16cefd807` |

ASan 副本为 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.43444.477be7c3`。
宿主流程里的 Evaluator 21/21 使用本地冻结合同，不能转作新的 Go 20/21 兼容通过。
目前无剩余上游格式化差异；更广语料、可编辑原始树、FormatNode/jsonnetfmt、
完整诊断/hook/debugger、Linux 实测及未接受兼容例外仍属于整体待办。
没有推送、部署或发布。
