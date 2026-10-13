# 运行时帧预算验收

2026-10-05，实现在提交 `09a5e557dfa22fb38e1bd9015381831e17c68b55`。
固定参考仍为 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**整体功能对齐仍未完成；本批实现独立帧预算，不宣称完整诊断帧等价。**

## 实现与参考依据

- 新增 CLI `-s`/`--max-stack` 与公开 `Limits.stack`，默认 500，必须为正数。
  CLI 使用固定 64-bit Go 的十进制整数规则；接受符号、前置零和最大 Int64，
  拒绝零、负数、空值、非十进制写法、空白、非 ASCII 数字及溢出。
  超过 Int32 的有效值按数组最大可表示帧数处理，不作溢出窄化。
- 顶层与函数体、未求值的局部/参数/导入 thunk、对象字段/断言、`+:` 包装
  以及每次 JSON manifestation 占用运行时帧。缓存命中、已就绪字符串、
  注入的标准字段和 native builtin dispatch 不增加帧；函数参数是否求值
  仍遵循原有惰性语义。普通 AST 遍历不占运行时帧。
- 只有由 `tailstrict` 进入的函数帧可以在尾调用时移除；在实参强制求值前
  释放。严格函数继续使用循环，1000 次严格尾调用在 stack=2 下完成。
  普通入口帧不能被错误释放，严格/普通混用、非尾位置调用与失败退出均有
  回归。展开、字段及 thunk 在异常后恢复计数。
- 字符串 TLA/外部值作为 Ready 保存，`std.thisFile` 作为内部标准值注入；
  未改变其字符串内容、文件身份或 API 的非字符串 JSON 参数惰性转换。
- 栈预算耗尽返回 `Limit: max stack frames exceeded.`，CLI 退出 1，输出
  文件仍在求值成功后才打开。`max-trace` 只影响显示，独立的 depth、steps、
  源字节、导入及输出预算继续生效。全字段构造 `Limits` 的调用者需补 stack；
  推荐继续从 `Limits::default()` 做 record update。

参考依据为 Go `interpreter.go` 的 newCall、EvalInCleanEnv、tailCallTrimStack、
evaluateAux 与 manifestJSON，`thunks.go` 的 cachedThunk、codeUnboundField、
closure 与 plusSuperUnboundField，以及 `value.go` 的对象断言和
`cmd/jsonnet/cmd.go` 的参数处理。核心实现为 MoonBit；参考二进制仅供开发验证。

## 已保留的边界证据

初始探针对 33 组程序逐一运行 stack=1..12，共 396 对执行，发现三处边界：

| 输入 | 初始本地最小帧数 | Go 最小帧数 | 修复 |
| --- | ---: | ---: | --- |
| `({a:1}+{a+:2}).a` | 2 | 3 | additive wrapper 独立占帧 |
| `std.thisFile` | 2 | 1 | 注入标准值不创建代码字段帧 |
| `function(x) x`，`-A x=a` | 2 | 1 | 字符串参数已就绪，不强制新 thunk |

初始失败输出保存在 `_build/stack-probe-initial.json`，修复后的探针在
`_build/stack-probe.json`；后者 396 对的退出码及 stdout 一致。这些为开发期
证据；提交绑定验收采用已冻结的 `tests/go-cli-stack.json`，不从本地输出
刷新预期。该文件含 61 项最小帧数/前一失败边界和 21 项参数、输入模式检查，
共 82 项（39 成功，43 错误）。普通成功项固定参考 JSON，string/stream 固定
完整 stdout；耗尽项验证参考错误消息和本地 Limit 分类。双方完整 stderr
均保留，但不将不同的诊断文本视为逐字节相同。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过 |
| debug / release 测试 | 各 144/144 |
| 本批固定 Go 差分 | 82/82 |
| 完整 Go runner | 1112/1130；18 原有失败；0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 宿主集成 | 97 + multi 26 + import 20 + diagnostic 20 + stack 20，共 183 |
| 隔离 ASan | 144 测试 + 183 集成通过；关闭 leak detection |
| 独立归档消费者 | 15/15 |

Go runner 的 478 error、3 raw-output、60 text-output、45 file-output、11
io-error 为重叠计数。18 项历史失败保留，runner 继续退出 1。该计数不包含
所有未加入断言的帧/格式/宿主行为差距，不能当作全部待办数量。

## 构建与范围

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- Go 1.24.0，vcs.modified=false；参考 SHA-256
  `adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；SHA-256
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- release CLI SHA-256
  `b04e68f828e52ed4b2503dc502f4a32af73c3e9fcbb09ba4223a9809a0e91736`。
- Go/C++/parity/上游语言报告绑定上述实现提交及干净工作区，原始报告在 `_build`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.64343.af2de72e`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.64093.ce8803a0`。

完整 Go 命名/合成诊断帧模型、所有标准函数的精确帧阈值仍未证明等价。
项目保留深度和其他资源政策，可能比 Go 的 stack 上限先触发。
可重用 VM/AST 生命周期、依赖发现、格式化/分析工具及其余已记录差距仍待推进。
只作本地提交，没有推送或发布；未验证其他平台及远端 CI。
