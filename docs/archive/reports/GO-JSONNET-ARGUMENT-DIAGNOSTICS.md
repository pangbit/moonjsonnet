# 调用参数检查与完整诊断验收

日期：2026-10-08。实现提交 `a74441996822aa3b3eb921b2e0e2c08510b04408`。
仅本地开发、测试及提交，没有推送、安装新软件、部署或发布。

原生标准函数、闭包和宿主 NativeFunction 共用参数绑定检查。在强制实参前，
按固定 Go 的顺序检查多余位置参数、命名冲突/未知名称及声明顺序中的缺参。
保留可选默认值、重复形式参数和命名参数顺序；无效调用不会强制错误实参。
消除原生标准函数的旧 wrong-argument-count 文本及缺失命名槽访问风险。
私有实现没有公开 `.mbti` 变化。

只加入本缺口的十个输入，七种 trace 设置，共新增 70 API 项及其 210 CLI 项；
原冻结输入和预期完整保留，新增预期来自固定 Go 实跑。CLI 仍按 exec/stdin/
规范文件三种输入方式比较原始 stdout/stderr 字节及退出码，不规范化结果。

| 验证 | 干净实现结果 |
| --- | --- |
| info / fmt / 普通及 release native check --deny-warn / release build / fmt --check / doc / diff --check | 通过，公开接口未变 |
| 普通 / release native 测试 | 各 294/294 |
| 实际 Go 诊断 API | 1211/1211，错误各 1176 |
| 实际 Go CLI 完整字节 | 3759/3759，Go 错误 3654 |
| 独立 archive 消费者 | 29/29 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 编辑节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI | 255/255 加 4 项 branding；两解释器各 23 检查 |
| 整体 CLI | 1131/1150，483 预期错误；19 失败保留，没有新增 |
| Evaluator / lint | 20/21、409/410，原各 1 失败保留 |

十一份实际 Go 报告都核对 source_dirty=false 和同一实现提交，完整副本与
manifest 位于
`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.42351.c66a32bb`。
manifest 包含每份完整报告、实现、语料、工具和二进制 SHA-256；manifest SHA-256
为 `6d30366f656f7744b82dda24c3b208c089b7b3dc14c01efe04aa663d74813e4c`。
API 报告 SHA-256 为 `313e148078f9f2293552dedbaa73d131aa4afe0f57da57d589259708aec2904f`，
CLI 字节报告为 `61c8af8293af2752cff533487f933c661ead1b94c54633e631f20b39a0816df8`。
固定 Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57` / Go 1.24.0；
固定 C++ 输入提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`，未构建 C++ 解释器。

本实现的完整隔离 ASan 通过：native 294，完整宿主/API，实际 CLI 字节 3759，
API 诊断 1211，AST 173、节点编辑 56、调试器 26 及既有工具宿主检查。
副本 `/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.20915.496eb27f`，
没有内存错误；按既有合同禁用泄漏检测。本地冻结 Evaluator 21/21 不替代
实际 Go 20/21。临时工具链副本仅启用 ASan 分配器/标志，未改安装的运行时。

整体仍未完成。旧 18+1+1 项参考缺陷未获例外接受；循环 ext-code 消息差异
单独推进，不等待例外决定。循环修复不能仅将忙状态的错误文本替换成栈耗尽，
也不能删除或提高既有表达式深度/步骤预算。
Linux 的 socket 权限阻碍、官方来源、隔离位置和拟用验收方式见
[Linux 方案](LINUX-ACCEPTANCE-PLAN.md)，未安装或运行该方案。
