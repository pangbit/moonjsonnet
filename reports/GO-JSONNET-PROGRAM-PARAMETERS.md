# 已解析 ext/TLA 参数验收

2026-10-05，在实现提交 `3d287e604b4c05506f2869499a0a519ab3913d60` 和干净工作区
执行验收。参考 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**整体对齐未完成；本批提供 ExtNode/TLANode 对应的已解析参数能力。**

## 实现与契约

- 四种字符串求值入口、四种 Program 执行方法及 `fs.evaluate_file` 接收
  `ext_programs` / `tla_programs: Map[String, Program]`。同名参数按 Program、
  代码、JSON 的优先级选择；没有改变未使用新参数时的既有调用方式。
- 每个绑定每次执行只求值一次，结果和错误记忆化，未使用的绑定不执行。
  多个绑定使用同一个 Program 仍拥有各自 thunk；下一次执行重新创建状态。
  可访问当前 ext/native/trace/import 配置，不能捕获调用处局部变量。
- `std.thisFile` 为 `<extvar:NAME>` / `<top-level-arg:NAME>`；诊断和 trace
  保留 AST 源位置，导入使用解析时的 filename。匿名 Program 使用空导入起点。
  此行为依据 Go `prepareExtVars`、`nodeToPV` 及 import 节点的 FileName。
- Program 创建时即完成语法/静态检查；运行时源字节数和 AST 深度按当前 Limits
  在首次强制参数时检查。未使用参数不触发这些检查，失败不污染下一次执行。
  AST 私有且不可编辑，本批没有加入可重用 VM 配置或跨次共享求值缓存。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过 |
| debug / release 测试 | 各 163/163；新增 5 项参数回归 |
| 固定 Go 参数 API 对照 | 30/30；26 成功、4 错误 |
| 既有 Go CLI 差分 | 1112/1130；原 18 项失败保留，0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 183 项通过 |
| 依赖工具 | 33/33 fixture + 13/13 本地 CLI 检查 |
| 独立归档消费者 | 17/17；包含 Program 参数和文件宿主调用 |
| 隔离 ASan | 163 测试 + 183 宿主集成 + 33 依赖 fixture + 13 CLI 检查 + 30 参数 API fixture 通过 |

30 项 API 对照覆盖混合/重名参数、惰性、记忆化、ext 交叉引用、合成 thisFile、
三种导入的请求起点、trace 源行、运行时/静态错误、循环参数、四种输出、
Unicode/NUL、干净作用域、对象继承和空参数名。两边分别对固定预期验证；保留
完整 stdout/stderr/退出码。错误位置/消息仅检查固定片段，不声明全部诊断文本
或帧集合相同。循环参数都报错，本项目提前发现 thunk 循环，Go 达到栈限制；
本批没有把错误机制声明为相同。

Go API 对照采用开发期适配器调用真实 SnippetToAST、ExtNode/TLANode 和
Evaluate 系列，运行时没有依赖 Go。参考 checkout 必须是固定提交且干净，构建
使用 Go 1.24.0、GOWORK=off、GOPROXY=off；报告记录 helper 构建元数据和源码
哈希。该 helper 的 Go 模块标为 `(devel)`，参考提交由构建前 checkout 校验绑定，
不是根据 helper 中不存在的 vcs.revision 推断。

首轮 26/30 暴露了适配器遗漏：本地未接 binary resolver，两边未完整格式化
结构化诊断。修正适配器后同一 30 项预期全部通过，没有删除或放宽输入。
首轮原始报告保留在 `_build/parameters/initial-adapter-failures.json`。

ASan 使用独立工具链副本，测试及集成均设置 `exitcode=99`，避免 sanitizer
故障被预期应用错误掩盖。关闭 leak detection，未声明泄漏检测或性能结论。
隔离源码不包含 .git，参数本地报告将 Git 元数据记为 null，未伪造提交绑定；
本次隔离副本从上述已提交源码复制。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- 本地 release 解释器 SHA-256：
  `27558e2015a3e778913bf2be948897276a37279800d175fe158b5a681fefb724`。
- 本地 release 依赖工具：
  `7d4afe5c821a3406331f1711536e7bd2df87fa18239ed64775b6a8f6d47fb669`。
- 本地 release 参数 API probe：
  `7011451bc25da907ea549d0969a05f8d7f9051eb32668c58b3cebed398f3a73a`。
- Go 参数 API adapter：
  `4ac1de4843c9b5ca5551a717cc4a0275a5ac7c86a1abcf27088903a15328b80d`；源码
  `74ba1db916029a8c178b1d7ba11e0bd747b464454b5155f011ed9dc7f96eb32f`。
- Go CLI：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；CLI
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- `_build/parameters/report.json`、Go/C++ 差分、依赖工具和标准库表面报告
  均绑定上述实现提交及 source_dirty=false；上游语言报告也绑定该实现提交。
- 参数对照目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-parameters-.98667.f3e17de9`。
- 消费者目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.99809.fff8f7bb`。
- ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.99042.1e8f3124`。

API 对照与 CLI/工具结果独立计数，没有用合并总数掩盖 18 项历史失败。
只作本地提交；可编辑 AST、VM 共享缓存/配置重置、导入查询、格式化器、lint、
完整诊断模型及平台差距仍在推进范围内。
