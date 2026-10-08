# 表达式缩进传播与整体回归

日期：2026-10-08。实现提交 `6f63a09692c4724dea86cac68f69930cf06d8779`。
最终两个格式化 runner 与完整 Go CLI runner 均在该干净提交实际重新运行，
报告记录 `source_dirty=false`。本地 archive/消费者和隔离 ASan 随后通过。
没有推送、发布或部署；整体功能对齐仍未完成。

## 修改与边界

AST 传播独立的 base 与 line-up 引用，输出时解析到实际 UTF-8 字节列。
覆盖函数体、局部绑定/对象方法、条件分支、断言消息、容器与推导式、调用、
点/括号索引、切片和二元式。原始分组括号从 token 恢复，区分参数/调用/
分组，避免将括号内部换行误判成外部二元续行。规划和括号处理计入步骤预算，
缩进解析检查输出上限。旧的计层及单独二元覆盖算法由统一计划取代。

声明名材料换行会整体展开后续局部绑定。末尾逗号材料迁移到关闭分隔符，
合并换行并保留注释原始归属。Indent=0 对插入换行使用零缩进；只保留注释
时仍区分原行末注释。调用前的行内注释间距遵循目标/左括号规则。固定 Go
未重设切片关闭材料缩进，保留其行为。无公开 API 变化，AST 默认 200、
硬上限 512 与求值预算均未改变。

## 干净实现验证

| 检查 | 结果 |
| --- | --- |
| native check / release build --deny-warn | 通过 |
| native 普通 / release 测试 | 均为 249/249 |
| moon info、fmt、fmt --check、doc、git diff --check | 通过，无 .mbti 差异 |
| 冻结 Go 格式化对照 | 736/736；既有 608 项完整保留，新增 128 项 |
| 上游 Go 格式化对照 | 176/178；Go 错误 0、本地深度错误 2，失败保留 |
| 完整 Go CLI/语言/标准库对照 | 1132/1150；18 项既有参考崩溃差异计失败 |
| 本地 archive 独立消费者 | 23/23 |
| 隔离 ASan native 测试与宿主集成 | 全部通过 |

新增 16 种小型输入 × 8 组选项，预期由固定 Go 实跑生成。正式 runner 又独立
构建参考，核验输出、重解析和 Go 自身幂等标记。新增单元测试同时核验求值
保持、原文隔离、幂等性与步骤预算。原 178 项输入与 Go 完整结果逐行相同，
原 157 项通过集合零回退，19 项布局输入新增通过。仅 format.jsonnet / stdlib.jsonnet
保留 72:47 / 157:20 的深度拒绝。冻结 runner 退出 0，上游 runner 退出 1。

CLI 成功 1132、失败 18、跳过 0、明确未支持 0、已声明参考例外 0、预期错误 483，
因保留失败退出 1。既有崩溃差异未获例外接受，没有删除或放宽比较。

ASan 使用 tools/asan.mbtx 隔离工具链和源码副本：native 249、CLI 宿主 97、
多文件输出 26、导入搜索 20、诊断 20、栈预算 20、依赖 33 / 本地 CLI 13、
参数 30、Evaluator 21 个序列（88 个观察）、AST 173、lint CLI 23，均通过。
API 部分是本地冻结合同检查，不是重新消除固定 Go Evaluator 20/21 或 lint
409/410 的既有差异。exitcode=99，禁用 leak 检查，不声明 LeakSanitizer 证明。
ASan 路径 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.15870.5ab19ff0`；
副本及实现 formatter_indent.mbt SHA-256 均为
`934bd27c5332db3ed8c9656ffa101d3f04a9b064e0bbe60006a1cbe6e96fb9d1`。

固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，
GOWORK=off/GOPROXY=off；C++ 输入：`bbb38f1020be1f5aed560928fb839b2c448cefb4`。
参考 checkout 核验干净。复现命令见 [VALIDATION](../docs/VALIDATION.md)。

## 证据身份

| 文件 | SHA-256 |
| --- | --- |
| tests/go-formatter.json | `c062f59ef8ec74f101cda68711884bd0339031b4c0fed7cd3519212c2c59f95d` |
| _build/formatter/report.json | `76a8e895a1aa0d2e491b8003c1424e610c5dd20635a4a8474e1d9d0d023046ff` |
| _build/upstream-formatter/report.json | `1ac60d48fad646b2374751ed172bd40dc52b62bd2d6c22cb625d58aa01685cc3` |
| 本地 release formatter probe | `a323fa6c58b8ef745821bb3399c3ae4c6d4c410c7fe5af10b656783d9352f7c3` |
| _build/go-differential/report.json | `bfd626dad382d47f3743a8f11cb2b3d88b1bc35ce06f6975f4cf6e077c3a82e8` |
| _build/publish/pangbit-moonjsonnet-0.1.0.zip | `8bd851b088715c76134f602e7c11f333c75a8927b486b0272f29c5812e808c3b` |

继续实现并证明迭代 AST 导出与独立格式化深树契约，保留求值深度预算。
FormatNode/jsonnetfmt、可编辑原始树、完整诊断/hook/调试与 Linux 验收仍按
[完成清单](../docs/COMPLETION-CHECKLIST.md) 推进。本机 Linux arm64 Docker 可用，
现有隔离镜像缺 gcc/git/curl；尚未计 Linux 构建或行为验收通过。
