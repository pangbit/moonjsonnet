# 静态依赖扫描验收

2026-10-05，在实现提交 `f898691a6a98c779f920bf16fce4cddfaa4cb42b` 和干净工作区
执行验收。参考 google/go-jsonnet v0.21.0，提交
`67968688d9952f50662e979fab1bef889d0d3e57`。
**整体功能对齐未完成；本批提供独立依赖扫描，不包含可重用 VM/AST 生命周期。**

## 实现范围

- `find_dependencies(imported_from, imported_paths, resolver~, limits?)` 返回
  已解析身份的排序去重数组，排除所有入口。先加载、解析全部入口，再扫描
  三种 import；不执行条件、函数、断言或原生回调。函数默认值、未使用局部、
  未执行分支、字段名/字段值、推导式等静态依赖纳入本批语料。
- 单一 BinarySource resolver 处理所有请求，仅对代码解码 UTF-8 和解析。
  原始文本/二进制依赖可以包含非法 UTF-8 与 NUL；代码仍须通过语法和静态
  检查。按 `(from,path)` 缓存请求、按 id 缓存 AST；每次扫描状态独立。
- `FileHost::find_dependencies` 使用现有宿主的搜索路径、规范路径与字节缓存。
  库路径可以用于 API 入口查找，CLI 则先检查入口本身，禁止入口库路径回退。
  只返回限定 root 内的 canonical 绝对路径；此政策比 Go 默认文件宿主严格。
- `cmd/deps` 接收多个文件，支持 `-J`/`JSONNET_PATH`、`-o`、`--`、短选项
  展开、help/version，以及项目的 `--root`。`-` 是普通文件名。成功输出每个
  依赖加一个换行；空列表不输出。仅成功扫描后打开输出文件，错误退出 1，
  保留既有输出；成功空列表会清空指定文件。
- 图遍历使用显式工作栈。601 文件的循环图在 depth=16、stack=1 下完成，
  计入 602 个不同请求（包含最后返回入口的请求）；不存在按图深度的原生递归。
  source/import/step/output 预算仍执行，运行时 stack 不参与扫描计数。
  Limits 的共同有效性检查从求值入口提取复用，既有求值语义不变。

参考依据为固定 Go `vm.go` 的 FindDependencies/findDependencies，
`internal/parser/context.go` 的 Children 和 `cmd/jsonnet-deps/cmd.go`。
参考工具由未修改源码、Go 1.24.0 构建；运行时不依赖 Go/C++ 二进制。

## 固定参考的扫描边界

参考源码和实际二进制均确认以下行为，本地显式保留并有回归：

1. `{assert import 'missing', a:1}` 不扫描对象断言中的 import；普通
   `assert ...; ...` 的条件、消息和主体仍扫描。
2. `[importstr 'a', import 'a']` 先登记 a 的身份，后续代码仍解析，但不会
   递归进入 a 的依赖；交换顺序则会进入。即使身份已登记，a 的代码语法错误
   仍然报错。局部表达式按主体优先的顺序遍历，也覆盖了这种组合。

不能因此把结果宣称为每种运行时执行的完整依赖集合。外部/TLA 参数代码不在
此扫描接口的输入中。完整反糖化遍历顺序、错误优先级和诊断文本尚未证明等价；
这些限制不属于用户已批准的最终兼容例外。

## 验证

| 检查 | 结果 |
| --- | --- |
| check/deny-warn、info、fmt/check、doc、release 构建 | 通过 |
| debug / release 测试 | 各 150/150 |
| 依赖工具差分 | 33/33；26 成功、7 错误，每项验证 stdout 和独立输出文件 |
| 本地依赖 CLI 检查 | 13/13；参数、help/version、root 越界与输出 I/O |
| 既有 Go 解释器差分 | 1112/1130；保留原有 18 项失败，0 跳过/未支持 |
| C++ 共享差分 | 98 通过、10 声明差异、0 失败，共 108 |
| 上游语言语料 | 303/303 |
| 标准库表面 | 163/163；behavioral_parity_proven=false |
| 既有宿主集成 | 183 项通过 |
| 隔离 ASan | 150 测试 + 183 既有集成 + 33 依赖 fixture + 13 CLI 检查通过 |
| 独立归档消费者 | 16/16，实际调用公共扫描及 FileHost 方法 |

依赖工具结果单独存放 `_build/dependencies/report.json`，不并入解释器表达式
差分通过数。报告保留 fixture、工作目录、两个程序完整 stdout/stderr/退出码、
`-o` 后文件内容、二进制哈希和 source_commit/source_dirty。Go 解释器 runner
仍因 18 项历史差异退出 1，完整输入保留。表面注册数不代表行为对齐。

ASan 使用隔离的工具链和已跟踪源码，关闭 leak detection。另对同一隔离
依赖 CLI 以 `ASAN_OPTIONS=detect_leaks=0:fast_unwind_on_malloc=0:exitcode=99`
重复运行 33+13 项检查，确保 sanitizer 故障不能被预期的程序退出码 1 掩盖；
此复核不增加唯一用例数。

## 构建与证据

- macOS arm64；Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9。
- Go 依赖工具：Go 1.24.0、vcs.modified=false；SHA-256
  `872157324f19a9c43d448fb2db5ebc7ed322be5234d788f635ec5ba2b75c6f3c`。
- 本地 release 依赖工具：
  `0bafec29d10e36f912f9879afaa0eaa549daa253e75028adc0afdb5678005667`。
- 本地 release 解释器：
  `04ed4751f2690fc1f706f69e87f561f84cfafb94196b8664dc19ea65bf57ee09`。
- Go 解释器：`adb17765d091d0a774b7efe68604a44eaed827d40041042d48e7d7b524d5a629`。
- C++ 提交 `bbb38f1020be1f5aed560928fb839b2c448cefb4`；二进制
  `7e13d194526c54eb02dd083c590445f75f274ee9885dea6cbc9b2156afcb5eee`。
- 依赖工具、Go/C++ 和 parity 报告均记录上述实现提交和 source_dirty=false；
  上游语言报告也绑定该实现提交。
- 依赖证据目录：`/private/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-dependencies-.74672.a3ecd47d`。
- 消费者目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-consumer-.75490.8a54430d`。
- ASan 目录：`/var/folders/w_/yh63r6057x3c43hj3bjr24tw0000gn/T/moonjsonnet-asan-.75606.30cae904`。

只作本地提交，没有推送或发布。可重用 VM/AST 与共享缓存、导入查询、格式化器、
lint、完整诊断模型及其余语言/平台差距仍待推进，未以本机结果代替其他平台或 CI。
