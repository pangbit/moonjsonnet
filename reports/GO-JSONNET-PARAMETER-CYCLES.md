# 外部参数返回调用与循环诊断验收

日期：2026-10-08。实现提交 `d7888ff6acb81aefa6382f9368ccdd2b85057e61`。
本阶段修复独立于旧 18+1+1 项参考缺陷；只做本地开发、测试及提交。

## 行为与实现

更严格的 CLI 标题检查暴露 `parameters-ext-cycle`：自引用 ext-code 原先立即
报惰性忙状态错误，固定 Go 则执行参数代码、累积调用帧并耗尽栈预算。
现在，当求值器返回的调用是 `std.extVar` 时，在现有求值循环内进入参数代码，
每次执行真实代码并保留真实的独立作用域及调用帧。循环达到既有 `stack` 后
报告 `max stack frames exceeded.`，位置、帧、裁剪和 CLI 字节与固定 Go 对照。
没有通过改写忙状态消息来伪造栈耗尽，没有改变默认/硬上限或删除步骤/深度检查。

`RunningParameter` 保存已经准备好的表达式和独立环境；有限返回链仍实际执行
条件、local 与宿主回调，成功后记忆化。失败按已有重试合同恢复原始 Code/Program，
所有 EvalHook 前后事件与真实运行帧在失败时完整清理，可重用 Evaluator 可恢复。
`std.extVar` 的共同查找入口同时对齐未定义变量消息。公开 `.mbti` 未变。

本批仅新增七个固定 Go 输入，覆盖默认 500 帧、自引用/互引用、local/if 返回
及 1/2/3/8 帧预算，七种 trace 设置共 49 API 项；三种 CLI 输入对应 147 项。
与上一实现 `a744419` 的全部 1211 项输入身份及完整预期逐项核对，1211/1211
保留且未修改。新增本地测试还验证独立步骤/表达式深度限制、12 次真实宿主
回调后终止并缓存，以及循环失败后的 hook 平衡和 Evaluator 替换恢复。

## 干净实现验证

固定 Go：提交 `67968688d9952f50662e979fab1bef889d0d3e57` / Go 1.24.0。
固定 C++ 格式化输入：`bbb38f1020be1f5aed560928fb839b2c448cefb4`，没有构建 C++。
实际平台为 macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
以下十一份实际 Go 报告均核对 `source_dirty=false` 和同一实现提交：

| 验证 | 结果 |
| --- | --- |
| info / fmt / 普通及 release native check --deny-warn / release build / fmt --check / doc / diff --check | 通过；公开接口未变 |
| 普通 / release native 测试 | 各 297/297 |
| 实际 Go 诊断 API | 1260/1260；错误各 1225 |
| 实际 Go CLI 完整字节 | 3906/3906；Go 错误 3801 |
| 独立 archive 消费者 | 29/29 |
| 原有环境、服务面板与嵌入示例 | release 二进制实际执行通过；嵌入示例的断言和越界导入预期错误执行 |
| 调试器 / AST | 26/26、173/173 |
| 冻结 / 上游 / 编辑节点格式化 | 736/736、178/178、56/56 |
| jsonnetfmt / lint CLI | 255/255 加 4 项 branding；两解释器各 23 检查 |
| 整体 CLI | 1132/1150；483 预期错误；18 失败保留，parameters-ext-cycle 已通过 |
| Evaluator / lint | 20/21、409/410；原各 1 失败保留 |

完整报告副本及实现/工具/语料/二进制 manifest 保存在：

```text
/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-clean-evidence-.96316.6978a4b8
```

| 证据 | SHA-256 |
| --- | --- |
| manifest.json | 683f3ede861f3af51614e16affb5da4e84dc48c771df99c1afa86fc7b23cdb71 |
| API 完整报告（1.json） | 280f10687bc9b3005859c68b39b0277c330c2f34298df73b471b5eec5f932ef8 |
| CLI 字节完整报告（0.json） | 439cddce7e40bfd03524a5c8d8efb898ef46d6ef63633aab393ceded8340dde2 |
| 整体 CLI 完整报告（4.json） | d9dfd03e62e40eae45b0236dcf0fa7c103da885a4a0a714646c5249eaee79b25 |
| CLI release 二进制 | bf1e0482d69b2cb1ae0cdb5aa858fa5a1f7adef0d5eca499a060dfcf83e0bb7d |
| API release 二进制 | 5b3c21e859db21a826beb63185329fccc50d9df8bfd3a768f2832d1fc0bee9f8 |
| 冻结诊断语料 | a455364a34d22a8e3dee0579a792110fbc70fa77f60e16afc14e61dc87945c15 |

完整隔离 ASan 已通过：native 297，完整宿主检查（集成 97、multi 26、导入 20、
诊断 20、独立栈预算 20），实际 Go CLI 字节 3906，API 诊断 1260，以及依赖
33+13、Program 参数 30、冻结 Evaluator 21、AST 173、lint CLI 23、格式化宿主、
节点编辑 56 和调试器 26。没有内存错误；按既有合同禁用泄漏检测。本地冻结
Evaluator 21/21 不代替实际 Go 20/21。安装运行时未改，仅在临时工具链副本
启用 ASan 分配器/编译标志。14 个本批源码、测试、适配器及语料文件 SHA-256
已与提交内容核对相同。副本目录：
`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.73906.c8f3b30`。

## 剩余范围

整体仍未完成。旧 18 项 CLI 参考内部崩溃、失败解析后的 nil AST 缓存及 lint
入口/导入身份碰撞 panic 继续计为失败，未获用户接受为兼容例外。
本批只处理求值器返回的外部参数调用；一般非尾部循环惰性值仍走忙状态保护，
不据此宣称全部循环诊断一致。更广预算/标准库错误、原始降级断点、I/O/参数/
终端色彩覆盖继续推进。Linux 尚未运行，官方工具来源、已核实镜像和隔离位置
见 [Linux 验收方案](LINUX-ACCEPTANCE-PLAN.md)；等待安装授权，不推送或发布。
