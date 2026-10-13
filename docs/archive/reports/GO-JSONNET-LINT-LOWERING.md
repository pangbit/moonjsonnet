# lint 多入口与语法降级验收

2026-10-05，实现提交 `62b5fb2edf59d52f123226041033ced42226de71`。
固定 go-jsonnet v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
提交后在干净工作区验证。**差分为 162/164，仍有两项失败，整体对齐未完成。**

## 改动

重复文件名的早期入口此前错误复用了最后入口的类型树，例如 `42()`、`true()`
两个同名入口均报告 bool。固定 Go 只为最后成功解析的同名入口保留推断根，
早期入口仍检查自己的语法但采用空类型。因此本批改为按每个入口保留检查树，
上述输入依次报告 void、bool，unused/循环检查仍按各自入口执行。

取模、普通 `in`、切片、数组和对象推导式在分析阶段降级到隐藏标准库调用，
不受用户 `std` 遮蔽影响。函数/条件及隐式调用按照参考顺序参与类型检查；
对象推导式的 local 放入字段体。修复重复入口中隐式调用漏诊，以及多个有错
子表达式的诊断顺序。分析树独立于运行时求值，不执行 Jsonnet。

合成表达式深度受 Limits 限制，推导式展开计入分析步骤。40 层平面 `for` 输入
在 depth=30 下返回 Limit，避免源码解析深度较浅却产生无界分析递归。
公开接口保持不变，来源与 Apache-2.0 归属记录于 NOTICE。

## 差分证据

在原 114 项上新增 **50** 项，覆盖运算符、切片、推导式、断言、标准库遮蔽、
多错误顺序、重复入口及入口/导入身份碰撞。原 114 项全部继续通过，新输入
48/50，通过总数 **162/164**；无输入删除，仍比较有序完整消息数组及 found。

初次新增 33 项为 144/147，重复入口两项错误和参考崩溃的原始结果保留在
`_build/lint/lowering-before.json`。随后补充混合语法和隐式调用交叉输入，修复
可实现的多入口与类型检查差异。最终 `_build/lint/report.json` 保留全部 164 项。

剩余两项均计入 failed，runner 退出 1：

1. `distinct-entry-cross-import`：入口 A 导入 B，同时 B 作为显式入口。
   Go 类型图 panic：`Bug - placeholder for a dependent node cannot be noType`。
   本地以显式入口根进行有界分析并返回诊断，不复制崩溃。本项未经用户接受为例外。
2. `duplicate-entry-syntax-final`：末尾同名入口为不完整的 `local`。有效入口的
   类型检查已一致，但解析诊断本地为 `expected identifier`，Go 为
   `Expected token IDENTIFIER but got end of file`。没有屏蔽或归一化掉该差异。

本批比较未证明完整位置/范围格式等价。隐式节点的本地位置沿用原表达式，
Go 部分隐式节点没有源码位置，后续源码元数据与诊断工作仍须处理。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，无公开接口变化 |
| native debug / release | 各 202/202 |
| Go lint API | 162/164，2 项失败含 1 项 reference_crashes；source_dirty=false |
| lint CLI | 两边各 23 项通过 |
| 独立归档消费者 | 21/21 |
| 隔离 ASan | 202 测试 + 183 宿主集成 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 20 AST fixture + 23 lint CLI 检查通过 |

本批没有改解释器求值，也未重跑旧 Go/C++ CLI 全量输入，其最新版本绑定证据
仍是 [AST 验收](GO-JSONNET-AST.md) 的 fba845d。旧 CLI 18 项、Evaluator 1 项差异
及本批 lint 2 项分别保留；格式化、调试器、AST 元数据和跨平台未完成。

## 构建与复核

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- lint CLI SHA-256：`64f9fad683a96fdcee63fa70afbe53bbe33710a3ae44feca106032947d35d337`。
- API probe：`4c1efe11e563d6685f911284d10726ad8017a0531ae3a3d7949b3fc698072b48`。
- Go helper：`b7c3c3fd8d4cdac565166b678500417895d192e1ce97e96c3f736a5bdf069333`。
- adapter：`8dcf5c0ddbbff44a80394568f68384a6a756293d2d820d348500b6200ccba41a`。
- Go 1.24.0，GOWORK=off、GOPROXY=off；构建前校验 checkout 提交和干净状态。
- API：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.85095.fb77ead5`。
- CLI：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.84485.38edb05f`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.89153.facf3621`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.84471.1021a6ff`。
  跟踪源码和工具链均使用临时副本，exitcode=99，关闭 leak detection。Go API 全量
  差分使用独立 release 二进制，本报告没有把 164 项全部描述为 ASan 覆盖。

仅本地提交，无推送/发布。下一步继续处理解析诊断和源码位置，不能把新增失败
留在历史记录后移出整体完成标准。
