# MoonJsonnet

[英文介绍](README.mbt.md) · [文档索引](docs/README.zh-CN.md)

使用 MoonBit 编写的可嵌入 Jsonnet 解释器，直接解析和执行源代码；运行时不需要
Jsonnet 可执行文件或共享库。

库和 CLI 支持惰性求值、词法闭包、对象继承、受控导入及 JSON 输出。语言目标是
Jsonnet v0.21.0，不主动裁剪语言结构。固定参考清单中的 163 个标准库成员均已注册；
兼容范围由有限差分验收和明确记录的差异限定，不保证所有输入均与上游等价。

[google/go-jsonnet](https://github.com/google/go-jsonnet) 是语言语义、标准库行为、
嵌入 API 和 CLI 行为的功能参考。差分工具分别记录固定 Go/C++ Jsonnet v0.21.0
的结果。参考契约和已验证范围见[兼容性说明](docs/reference/COMPATIBILITY.md)。

## 状态与安装

0.2.2 面向 **macOS 和 Linux 的 native 后端**。文件访问使用 POSIX libc；求值器本身
没有第三方运行时依赖。迁移已有 Jsonnet 程序前，请阅读[兼容性说明](docs/reference/COMPATIBILITY.md)。

历史兼容记录保留原始差异：

| 参考语料 | 原始结果 |
| --- | --- |
| C++ | 108 项：98 项兼容＋10 项声明差异 |
| Go 整体 CLI | ARM64 1132/1150；AMD64 1131/1150 |
| Go 可复用求值器／静态检查 | 20/21／409/410 |

历史验收契约保留 18 项 CLI 和 1 项静态检查的参考崩溃例外、独立的可选
`import_ast` API，以及与同架构参考一致的 NaN 行为。原始失败没有重新标记为通过。
后续规范整改已拒绝非有限数和小数索引、保持数组不可变，并传播 YAML 错误。
这些更改尚未重跑上述 Go 语料；当前 C++ 复验与明确的差异声明迁移记录在
[CI 验收说明](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/CI-VALIDATION.md)。
历史计数不代表当前完整规范符合性。

0.2.2 修正了解码字段名检查、继承标准库依赖、原生严格调用和求值钩子检查，
并为 `removeAt` 增加兼容的索引参数别名。公开 MoonBit API 签名未变。
版本改动与可用状态见[变更记录](CHANGELOG.md)及
[注册库记录](https://mooncakes.io/docs/pangbit/moonjsonnet@0.2.2)。旧版本保留各自记录的历史行为。
完整规范符合性仍未达成。

安装指定版本的原生库：

```sh
moon add pangbit/moonjsonnet@0.2.2
```

在 `moon.pkg` 中导入 `"pangbit/moonjsonnet"`，并使用 native 后端。

添加依赖后，最小可执行程序使用以下文件：

```text
# moon.pkg
import { "pangbit/moonjsonnet" }
supported_targets = "native"
pkgtype(kind: "executable")
```

```mbt nocheck
///|
fn main raise {
  let value = @moonjsonnet.evaluate("{ answer: 6 * 7 }")
  println(value.stringify())
}
```

将 MoonBit 源代码保存为 `main.mbt`，运行 `moon run --target native .`，输出为
`{"answer":42}`。在本地评估归档时，同一示例可把解包后的归档作为工作区成员；依赖名称不变。

```mbt check
///|
test "readme embedded evaluation" {
  let value = @moonjsonnet.evaluate(
    "local template(n=1) = { replicas: n, port: 8080 }; template(3)",
  )
  assert_eq(value, { "replicas": 3, "port": 8080 })
  assert_eq(
    @moonjsonnet.evaluate("std.thisFile", filename="<cmdline>", anonymous=true),
    Json::string(""),
  )
  assert_eq(
    @moonjsonnet.evaluate_text("'hello'", string_output=true),
    "hello\n",
  )
  assert_eq(@moonjsonnet.evaluate_stream("[42,'hello']"), [
    "42\n", "\"hello\"\n",
  ])
  assert_eq(@moonjsonnet.evaluate_multi("{a:42}")["a"], "42\n")
}
```

根库接收源代码、JSON/Jsonnet 外部变量和顶层参数，以及可选的宿主导入解析器和
单次求值限制，返回 `Json` 或 `JsonnetError`。
`evaluate_text` 返回格式化 JSON 或纯字符串；`evaluate_stream` 把顶层数组转换成
JSON 文档序列；`evaluate_multi` 返回文件名与内容的映射，不写入文件。
独立的 `pangbit/moonjsonnet/fs` 包在配置的根目录内读取文件，详见
[API 与宿主契约](docs/reference/API.md)。

```mbt check
///|
test "readme code and top-level arguments" {
  let result = @moonjsonnet.evaluate(
    "function(replicas, port=8080) {replicas:replicas,port:port}",
    ext_code=Map([("base", "1+2")]),
    tla_code=Map([("replicas", "std.extVar('base')")]),
  )
  assert_eq(result, { "replicas": 3, "port": 8080 })
}
```

宿主回调按参数顺序接收 JSON 实参。跟踪输出默认写入标准错误；可选回调接收调用位置和消息。

```mbt check
///|
test "readme native callback and trace" {
  let identity : @moonjsonnet.NativeFunction = {
    params: ["value"],
    callback: args => args[0],
  }
  let messages : Array[String] = []
  let result = @moonjsonnet.evaluate(
    "std.trace('calling host', std.native('identity')(value=42))",
    native_functions=Map([("identity", identity)]),
    trace=fn(_, message) { messages.push(message) },
  )
  assert_eq(result, 42)
  assert_eq(messages, ["calling host"])
}
```

## 求值过程检查

诊断保留源码范围和具名或合成跟踪帧。可配置的 `DiagnosticFormatter` 渲染 Go 风格错误，
原有 `Diagnostic::format` 仍可使用。提供源代码后，可以渲染静态错误片段并选择着色。
详见[诊断 API](docs/reference/API.md)。

```mbt check
///|
test "readme structured diagnostic trace" {
  let formatter = @moonjsonnet.DiagnosticFormatter::new()
  try @moonjsonnet.evaluate("error 'failed'", filename="entry") catch {
    @moonjsonnet.Error(d) => {
      assert_eq(d.trace.length(), 2)
      assert_eq(
        formatter.format(d),
        "RUNTIME ERROR: failed\n\tentry:1:1-15\t$\n\tDuring evaluation\t\n",
      )
    }
  } noraise {
    _ => fail("runtime diagnostic expected")
  }
}
```

求值钩子观察实际被求值的表达式。请在回调内检查值；若需保留结果，应复制返回的节点、
文本或 JSON。同步调试器另提供断点、单步、执行到返回和终止功能，详见
[API 文档](docs/reference/API.md)。

```mbt check
///|
test "readme evaluation hook" {
  let evaluator = @moonjsonnet.Evaluator::new()
  let values : Array[Json] = []
  evaluator.set_eval_hook(hook={
    before: ctx => {
      if ctx.node().kind is Var("x") {
        values.push(ctx.lookup("x").json())
      }
    },
    after: (_, _) => (),
  })
  assert_eq(
    evaluator.evaluate(@moonjsonnet.Program::parse("local x=21;x*2")),
    42,
  )
  assert_eq(values, [21])
  evaluator.set_eval_hook()
}
```

## 源码格式化

`format_source` 和 `ParsedSource::format` 格式化源码，不执行表达式或解析导入。
格式化器、可编辑原始语法树和格式化 CLI 均已提供；测试覆盖及剩余边界见
[兼容性说明](docs/reference/COMPATIBILITY.md)。
`format_syntax_source` 和 `SyntaxDocument` 为深树提供独立的源码工具预算；
求值准入和原有 `Limits` 不变。
`RawAst` 暴露有序词法单元、空白注释和子节点，以便进行无损编辑。
`format_node` 格式化编辑后的表达式，并单独接收文件末尾附属文本；`clone`
隔离可变容器，详见[原始语法契约](docs/reference/API.md)。

```mbt check
///|
test "readme source formatting" {
  assert_eq(@moonjsonnet.format_source("{\"a\":[1,2]}"), "{ a: [1, 2] }\n")
  let source = "0" + "+1".repeat(299)
  let syntax = @moonjsonnet.SyntaxDocument::parse(source)
  assert_eq(syntax.format(), "0" + " + 1".repeat(299) + "\n")
}
```

```mbt check
///|
test "readme raw syntax editing" {
  let raw = @moonjsonnet.RawAst::parse("/*head*/ 1 //tail\n")
  let original = raw.clone()
  for i, part in raw.root.parts {
    if part is Text(text) && text.kind is TokenText {
      raw.root.parts[i] = Text({ ..text, text: "42", })
    }
  }
  assert_eq(original.text(), "/*head*/ 1 //tail\n")
  assert_eq(raw.text(), "/*head*/ 42 //tail\n")
  assert_eq(raw.format(), "/*head*/ 42  //tail\n")
}
```

## 从源码运行

开发工具链：Moon 0.1.20261028／MoonBit v0.10.18+6c83a7f62。
[版本基线](docs/reference/VERSIONS.md)区分本次迁移与已发布 0.2.2 在旧编译器上的验证结果。

```sh
moon check --target native --deny-warn
moon test --target native --deny-warn
moon run cmd/main -- examples/environments/main.jsonnet
moon run cmd/main -- examples/dashboards/main.jsonnet
moon run examples/embedded
```

示例生成开发和生产配置、监控面板，以及包含导入和断言错误处理的嵌入式应用。
输入和预期输出均保存在仓库中，详见[示例教程与开发驱动索引](https://github.com/pangbit/moonjsonnet/blob/main/examples/README.zh-CN.md)。

```sh
moon run cmd/main -- --root examples/embedded/config --ext-code replicas=3 main.jsonnet
moon run cmd/main -- --root examples/environments -o result.json main.jsonnet
```

CLI 成功时写入求值后的输出；错误写入标准错误并返回非零退出状态。
聚合运算溢出返回运行时错误，详见[兼容性说明](docs/reference/COMPATIBILITY.md)。
`--ext-code` 接受 Jsonnet 表达式，并在使用时惰性求值，详见[CLI 文档](docs/reference/CLI.md)。

## 验收与贡献

项目包含语义测试、可执行文档、示例测试、固定官方参考版本的差分测试、宿主和 CLI
集成测试，以及归档消费者检查。CI 在 macOS 和 Linux 上运行仓库规定的固定检查；
完整 Go 差分和内存检测证据来自另外记录的运行。
开发命令和测试输入需要源码检出，不进入发布归档。请参阅仓库中的
[验收说明](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/VALIDATION.md)、
[发布流程](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/RELEASING.md)
和[贡献指南](https://github.com/pangbit/moonjsonnet/blob/main/CONTRIBUTING.md)。

资源限制不等于通用安全沙箱。宿主决定导入权限，请阅读[安全边界](SECURITY.md)。
本项目采用 [Apache-2.0](LICENSE)，参考资料和测试来源记录在 [NOTICE](NOTICE) 中。
