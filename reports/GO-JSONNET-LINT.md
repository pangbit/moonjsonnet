# lint 作用域与循环检查基线

2026-10-05，实现提交 `8d6ede9e1ba239314cd1e1cf52c116f1d571c782`，参考验收运行于
干净工作区。固定 go-jsonnet v0.21.0：`67968688d9952f50662e979fab1bef889d0d3e57`。
**lint 及整体功能对齐均未完成，类型推断差距明确保留。**

## 实现

- `lint(Array[Source], resolver?, limits?)` 返回结构化诊断，收集多个入口的解析/
  静态错误，检查词法绑定使用、未使用 local/object local，以及局部定义循环。
  死分支、默认参数、断言、动态字段名、遮蔽和推导式均按作用域遍历。
- 参数及推导式迭代变量不报告 unused；来自其他 unused 定义的引用仍算使用。
  循环检测遵循固定参考 desugared DirectChildren 的强制求值边，不强制数组元素、
  函数体、字段值、调用参数、嵌套 local 或降级为标准函数调用的模运算/切片。
  图遍历迭代执行，2,000 个平面相互引用绑定在本地测试中返回诊断。
- 递归检查所有导入，包括未执行分支和对象断言；代码解析、raw 字节不解码。
  身份去重终止循环；导入文件仅检查静态/导入错误，不报告其中的 unused/type
  警告，除非也显式作为入口。没有执行 Jsonnet 或触发 native/trace。
- 资源错误中止分析，不能将部分结果作为检查完成。分析步骤、源码/导入字节、
  深度和导入请求数有独立限额。
- `cmd/lint` 提供多文件、`-J`/`--jpath`、JSONNET_PATH、短选项、`--`、help/version
  及宿主 `--root`。0 表示未发现已实现类别的问题，2 表示诊断，1 表示输入/资源
  失败。固定 Go 实际把 `-` 当文件打开；本批按实现对照，未按其 help 声称实现 stdin。

声明位置范围尚未存于 AST，unused 诊断定位到初始化表达式；源码范围与 Go
完整诊断文本等价未证明。类型检查尚未实现，因此空诊断不是完整 Go lint 通过。
来源与 Apache-2.0 归属记录于 NOTICE；测试/参考适配器不进入发布归档。

## 差分基线

`tests/go-lint.json` 冻结固定参考 linter/testdata 全部 **62** 项源码及共享导入文件，
并新增 19 项词法/惰性/循环/导入/多入口输入。实际结果 **46/81**：

- 定向输入 19/19。
- 上游输入 27/62；35 项失败全部保留，runner 退出 1。
- 全部失败均为缺少参考类型诊断：非函数调用、索引目标/索引类型、缺失字段、
  一元运算类型、参数名称/重复/必需参数及数量；其中包含跨导入、闭包返回、
  递归数组和标准库返回类型的传播。`multiple_errors` 中 unused 已一致，两个类型
  诊断仍缺失。没有删输入或放宽比较来取得全绿。

适配器调用 Go 公共 LintSnippet，自定义 ErrorFormatter 捕获每次完整诊断，
仅从首行拆除位置前缀后比较**有序完整消息数组**及 found 标志；原始诊断和
进程输出保留。当前结果不是诊断位置/范围、所有语法降级边界或类型功能的证明。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过，公开接口新增 lint |
| debug / release 测试 | 各 194/194；新增 5 项回归和 1 项文档测试 |
| Go lint API | 46/81，35 项类型推断失败保留 |
| lint CLI | 本地/Go 各 19 项检查通过 |
| 独立归档消费者 | 21/21，调用公开 lint 方法 |
| 隔离 ASan | 194 测试 + 183 宿主集成 + 33 依赖 fixture + 13 依赖 CLI + 30 参数 fixture + 21 本地 Evaluator 序列 + 20 AST fixture + 19 lint CLI 检查通过 |

本批没有修改求值器语义，也未重跑旧 Go/C++ CLI 全量语料。其最新版本绑定证据
仍是 [AST 验收](GO-JSONNET-AST.md) 的 fba845d，不将旧 1112/1130 等结果冒充本次
lint 提交的新增对照。lint 的 35 项失败与旧 CLI 18 项、Evaluator 1 项独立计数。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- release lint CLI：`c76610b181aaf264a6e314a225435df3b00619b9a74ab5b735b224d78757aa48`。
- release lint API probe：`4bddf043c694561aaac364b229051777dd687a67be968924744149ce3702532f`。
- Go helper：`b7c3c3fd8d4cdac565166b678500417895d192e1ce97e96c3f736a5bdf069333`；
  适配器源码：`8dcf5c0ddbbff44a80394568f68384a6a756293d2d820d348500b6200ccba41a`。
- Go 构建前校验参考提交与干净状态；Go 1.24.0、GOWORK=off、GOPROXY=off。
  helper 为 `(devel)` 模块，版本绑定来自明确的 checkout 校验。
- `_build/lint/report.json` 绑定实现提交和 source_dirty=false，保留 81 项输出。
- API 证据：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-.58352.f9c81959`。
- CLI 证据：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-lint-cli-.58298.de57ca79`。
- 消费者：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.58688.92de469d`。
- ASan：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.58473.9ea5eab9`。
  副本来自上述实现提交的跟踪源码，使用隔离工具链及 exitcode=99，关闭 leak
  detection；没有改动安装工具链。新增 lint 的安全性覆盖来自本地 API 测试和
  19 项 CLI 检查，未把仍失败的完整 lint API 对照标为 sanitizer 下语义通过。

下一批需补齐表达式类型上界、递归/联合类型传播、标准库签名与类型诊断，再继续
核验当前未覆盖边界。未完成格式化器、调试器和其余整体差距。仅本地提交，无推送/发布。
