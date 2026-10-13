# 参数源码范围与重名形参验收

2026-10-05，实现提交 `0375bfdd1964a5eefeb8f7a822e6dd7b31842491`。
固定 Go v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后参考回归均在干净工作区完成。**AST 145/145，lint 401/402，
Go CLI 1132/1150；整体对齐未完成。**

## 实现与行为

`Func` 的参数由元组改为 `AstParameter`，包含 `name`、可选 `default_value`
和可选 `range`。范围从名字开始至默认表达式末尾；无默认值时仅覆盖名字。
解析、克隆、Program 转换保留坐标；手工参数允许无范围，非法范围按节点规则
拒绝。此 pre-1.0 API 变化及记录字段迁移方式见 docs/API.md。

固定 Go 接受重名形参，原解析及手工 AST 校验中的重复拒绝已经移除。调用按
名称建立槽位：重复位置实参最后一个生效；同名可选参数使用第一个默认值。
先按显式实参检查全部必需参数，再补默认值，防止默认值掩盖同名必需参数缺失。
命名实参仍不可重复提供，未知名、过多位置实参和必需参数缺失仍报错。
被覆盖的位置实参及后续同名默认值不求值，`tailstrict` 只强制最终槽位。

例如 `std.length(function(x,x) x)` 返回 2，`(function(x,x) x)(1,42)` 返回
42，`(function(x=42,x=error 'unused') x)()` 返回 42，
`(function(x=1,x) x)()` 报缺少参数。普通函数、局部函数和对象方法均有覆盖。

## 差分

新增 16 项参数范围和 15 项成功调用 AST 用例，20 项 lint 消息/起点及 20 项
CLI 调用用例。预期由固定 Go API/CLI 提取，错误调用保留在 lint 和 CLI 语料中。
旧 release 基线为 AST **114/145**、lint **381/402**、Go CLI **1117/1150**，
保存在各 `_build` 报告目录的 `parameters-before.json`。CLI 旧版本的 5 项
错误输入仅因同样失败而通过，不能据此认定旧错误阶段或消息一致。

新实现新增用例全部通过：AST **145/145**、lint **401/402**，带位置的用例
**182/182**；Go CLI **1132/1150**。18 项 CLI 失败名称集合与之前完全相同，
lint 唯一失败仍是 `distinct-entry-cross-import` 的 Go 类型图 panic。未删除
输入、跳过失败或接受新的兼容例外。

C++ v0.21.0 对 `std.length(function(x,x) x)` 退出 1：
`STATIC ERROR: <cmdline>:1:12-27: Duplicate function parameter: x`；Go 退出 0
并输出 2。本项目以 Go 为目标，不复制 C++ 的拒绝规则。既有 303 项上游语言
检查只比较成功值/失败结果；其中裸重复形参函数仍因缺少顶层参数而失败，
该检查通过不证明两者解析行为或错误文本等价。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过；公开接口增加 AstParameter 并迁移 Func |
| native debug / release | 各 219/219 |
| Go AST / lint | 145/145；401/402，source_dirty=false |
| Go CLI / C++ CLI / 上游语言 | 1132/1150；98 通过 + 10 声明差异且 0 失败；303/303 |
| lint CLI / 独立归档消费者 | 两边各 23 项；22/22 |
| 隔离 ASan | 219 测试 + 183 宿主检查 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 145 AST fixture + 23 lint CLI 检查通过 |

Go CLI/lint runner 保留原失败并退出 1。旧 Evaluator 重复失败 ImportAST 的
1 项差异依据原 20/21 Go API 证据继续保留，本批未重跑该 Go API。开始坐标、
错误片段和失败结果不代替完整消息/帧等价。源码保真、注释、格式化器、调试
能力和跨平台验证仍有缺口。

## 构建证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release CLI：`e0bd845220dfbf1ab6c93c0e72d4fa21b816169ac37fea3046cb22ff06c52c40`。
- AST probe：`f3f99743a54669ed470e33c8b836961a00f953d2addc5b0e84547358f064a7ac`。
- lint probe：`9412a589f5e90cd6187739238a3fef294c415a5f6a39b81593c401ff147a2fd9`。
- Go AST helper：`32217350ea5c72b77fd308d2697f21ebc81466a1f2c0ceb013f60cb5243bde0d`；
  adapter：`48b673b1203f5a41c71e0310a48a425e1cc3d2ea4dab465eaa07ec27678b44fa`。
- Go lint helper：`8a74e07f9ed75f04a153b49ef9af2683bcee50b31106ec3f4f8732b7aedba753`；
  adapter：`1432ca8542218f1a9d4f930e3f927b1984df6aaec455ed66b990c5c12c457ba1`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交：`bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- helper 使用 Go 1.24.0、GOWORK=off、GOPROXY=off，固定参考干净状态校验通过。
- `_build/{ast,lint,go-differential,differential}/report.json` 绑定本实现提交及
  source_dirty=false；上游语言报告也绑定本提交。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.4283.607159b9`。
  跟踪源码和工具链使用隔离副本，exitcode=99，关闭 leak detection；完整 Go lint
  402 项 API 差分由 release 二进制验证，不声称全部在 sanitizer 下执行。

仅本地提交，没有推送或发布。
