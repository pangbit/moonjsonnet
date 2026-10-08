# 迭代 AST 导出验收

日期：2026-10-08；干净实现提交 `1681c77da4e95102ccfe9c77f1d2d844c91a59e2`。
AST 导出使用显式进入/完成帧按构造器顺序处理所有子节点，包含对象断言、
可选参数/切片、局部绑定及推导式。每次出现独立构造可编辑容器，不做共享
副本缓存。范围、原始数字、形参/绑定元数据保持原合同。

未改变公共接口、解析/求值准入、默认 200 或 512 硬上限。私有 10,000 层
树是生命周期压力测试，不能作为绕过公共预算的产品入口。另验证同一个输入
数组子树出现两次时，修改一侧导出副本不会污染另一侧或输入。

| 验证 | 结果 |
| --- | --- |
| native check / release build --deny-warn | 通过 |
| native 普通 / release | 均为 251/251，包括深树与复制隔离 |
| info / fmt / fmt --check / doc / diff --check | 通过，无 .mbti 差异 |
| 干净提交固定 Go AST 对照 | 173/173，source_dirty=false |
| 隔离 ASan | 251 项 native 与整套既有宿主集成全部通过，leak 检查禁用 |

AST 参考为固定 Go v0.21.0 / `67968688d9952f50662e979fab1bef889d0d3e57`，
Go 1.24.0、GOWORK=off/GOPROXY=off，干净 checkout。复现见
[VALIDATION](../docs/VALIDATION.md)。没有推送、发布或部署。

| 证据 | SHA-256 |
| --- | --- |
| ast_convert.mbt | `676df8f751beb5b0c203a94d4ac5ea534a6a22b6a6bb99d50dc74334c7ec56bf` |
| _build/ast/report.json | `751b0b8317e884defb09f0f4a15f6c397ad63e05d2dee576eb48f77f6a1fa535` |
| 本地 release AST probe | `af02c64cfa9e3e89a91aa4f2489c9978f202706052e421604cc993a2149491f9` |

ASan 副本路径为 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.23030.ed6159ed`，
其 ast_convert.mbt 与实现哈希相同。该 runner 使用本地冻结 API 合同，不能
转作新的 Go Evaluator/lint 对齐证明。完整 CLI/格式化报告仍绑定此前各自提交。

下一步为独立格式化深树契约：保留完整树准入及解析递归保护，单独限制语法树
深度/节点、规划步骤与输出。旧 ParsedSource/Program/Limits 行为不自动放宽。
当前两项上游深度错误仍计失败；不能以本导出重构单独宣称其已通过。
