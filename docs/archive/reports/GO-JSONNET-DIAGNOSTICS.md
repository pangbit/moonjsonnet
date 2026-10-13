# 错误上下文裁剪验收

2026-10-05 在实现提交 `c596d9dfbc30ced76fbbd061b41f01dcf8e8ef6d` 及
干净工作区执行验收。参考仍为 google/go-jsonnet v0.21.0。
**整体对齐未完成；本轮增加显示裁剪，完整诊断帧模型仍待对齐。**

## 实现范围

- CLI 增加 `-t`/`--max-trace`。默认 20，0 不裁剪；正数保留 context 的前
  `floor(N/2)` 个位置和后 `N-floor(N/2)` 个位置，中间省略时输出一行 `...`。
  未超过限制时不添加省略行。重复参数最后赋值有效。
- 参数匹配固定 64-bit Go 的非负十进制整数语法：接受符号、前置零和最大
  Int64；拒绝负值、空值、下划线、进制前缀、空白、Unicode 数字、非整数和
  Int64 溢出。大于 Int32 的有效限制按最大可存 context 数量处理，不作溢出
  窄化。短选项展开、`--` 和输入模式沿用既有 CLI 规则。
- 公开 `Diagnostic::format(max_trace?)`。默认 0；非正数不裁剪，与 Go 嵌入
  formatter 对非正限制的处理一致。原始 Diagnostic/context 不变，主错误行
  和其中的位置始终保留；`Show`/`to_string` 仍输出完整上下文。
- 格式化在 CLI 最终错误处理处执行，覆盖源文件、导入、参数和输出模式的
  JsonnetError。参数错误仍退出 1。`std.trace` 的消息与 sink 不受显示限制
  修改；现有求值、深度、源字节、导入及输出预算继续生效。

依据固定 Go `cmd/jsonnet/cmd.go` 的 processArgs、`cmd/internal/cmd/utils.go`
的 SafeStrToInt，以及 `error_formatter.go` 的 buildStackTrace 和 `vm.go` 的
默认值。实现由 MoonBit 完成；参考二进制只用于开发验证。

Go 对完整命名/合成帧集合裁剪，本项目目前对调用/导入 context 位置裁剪，
主错误位置单独保存在 header。该区别仍属于待对齐能力，未证明逐帧或逐字节
诊断等价。例如 `diagnostic-crop-26` 的本地 context 恰好 26 项，不裁剪；
Go 包含原始错误和 During evaluation 等帧，共 28 项，会裁剪。两个完整输出
分别固定在 fixture 中，验收通过表示符合各自明确预期，不能把该已知帧差距
解释为兼容完成。`-s`/`--max-stack` 仍缺失；Go 的调用帧预算不同于当前
AST/求值深度限制，需另行实现真实运行时计数。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release CLI 构建 | 通过 |
| debug / release 测试 | 各 138/138 |
| 新增 `tests/go-cli-diagnostics.json` | 41/41 符合固定预期；6 成功、35 错误 |
| 完整 Go runner | 1030/1048；18 原有失败；0 跳过/未支持用例 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 97 + multi 26 + import 20 + diagnostic 20，共 163 |
| ASan | 138 测试 + 163 集成通过；关闭 leak detection |
| 独立归档消费者 | 14/14 |

41 项包括 16 项默认/显式裁剪、6 项成功整数参数、13 项参数错误和 6 项其他
诊断（语法、无 context、代码参数、tailstrict、string、stream）。参考 stderr
由校验版本/提交/干净构建元数据的 Go 二进制生成；本地递归诊断预期由已核对
的位置和 25 个内部调用加入口的 context 固定，不从本地输出自动更新。
差分工具新增分别固定 reference_stderr/moonjsonnet_stderr 的字段，完整保存
相应 fixture、实际参数、退出码和输出，不裁剪、trim 或删除诊断。

API 回归使用不同名称/位置的帧，固定奇偶保留顺序、空 context、精确长度、
超长限制、负限制、Unicode/NUL/换行消息以及格式化后的数据不变。CLI 参数
测试另外覆盖有效/非法十进制输入及 Int32/Int64 边界。20 项集成验证匿名、
文件、嵌套导入和多种输出模式的上下文数量、已有输出文件保护、错误前 trace
保留、重复选项、帮助文案及显示参数不绕过深度预算。

18 项原有参考崩溃/结果差异仍保留，Go runner 继续退出 1。该失败计数只对应
既有结果检查规则，不能证明所有未计入规则的帧、格式或宿主行为一致。
完整 Go 的 435 error、3 raw-output、58 text-output、45 file-output 和 11
io-error 为重叠计数。标准库表面与 C++ 声明差异不证明 Go 全量行为等价。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- Go 提交 `67968688d9952f50662e979fab1bef889d0d3e57`，Go 1.24.0，
  vcs.modified=false；SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- release CLI SHA-256
  `96c9a61726d0b07279e4a00834f5db181ce3c6972ee6df006495fa518a0f449c`。
- Go/C++/parity 报告均绑定上述实现提交，source_dirty=false；上游语言报告
  同样绑定该提交。原始报告留在 `_build`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.44968.475f1ca4`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.45021.d0ee1f88`。

只作本地提交；没有推送或发布。本轮未验证其他平台和远端 CI。
