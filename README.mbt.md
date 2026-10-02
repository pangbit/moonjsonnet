# MoonJsonnet

An embeddable Jsonnet interpreter written in MoonBit. It parses and evaluates
source directly; no Jsonnet executable or shared library is required at runtime.

MoonBit 原生 Jsonnet 解释器，可作为库嵌入，也提供 CLI。支持惰性求值、词法闭包、
对象继承、受控导入和 JSON 输出。首期为 Jsonnet v0.21.0 的明确子集，不宣称完整兼容。

## Status and installation

Version 0.1.0 targets **native on macOS and Linux**. File access uses POSIX libc;
the evaluator itself has no third-party runtime dependency. See
[compatibility](docs/COMPATIBILITY.md) before adopting existing Jsonnet programs.

After this version is published to Mooncakes:

```sh
moon add pangbit/moonjsonnet@0.1.0
```

Import `"pangbit/moonjsonnet"` in your `moon.pkg`, and use the native target.

```mbt check
///|
test "readme embedded evaluation" {
  let value = @moonjsonnet.evaluate(
    "local template(n=1) = { replicas: n, port: 8080 }; template(3)",
  )
  assert_eq(value, { "replicas": 3, "port": 8080 })
}
```

The root library takes source text, JSON external variables, an optional host
import resolver and per-evaluation limits. It returns `Json` or `JsonnetError`.
The separate `pangbit/moonjsonnet/fs` package loads files within a configured
root. See [API and host contract](docs/API.md).

## Run from source

Validated toolchain: Moon 0.1.20260920 / MoonBit v0.10.14+7d59c7ec9.

```sh
moon check --target native --deny-warn
moon test --target native --deny-warn
moon run cmd/main -- examples/environments/main.jsonnet
moon run cmd/main -- examples/dashboards/main.jsonnet
moon run examples/embedded
```

The examples generate development/production configuration, monitoring panels,
and an embedded application with import and assertion error handling. Their
inputs and expected outputs are checked into the repository. See
[examples](https://github.com/pangbit/moonjsonnet/tree/main/examples).

```sh
moon run cmd/main -- --root examples/embedded/config --ext-code replicas=3 main.jsonnet
moon run cmd/main -- --root examples/environments -o result.json main.jsonnet
```

CLI success writes valid JSON; errors go to stderr and return a nonzero status.
`--ext-code` accepts **JSON values only** in this release. See [CLI](docs/CLI.md).

## Validation and contribution

The project includes semantic tests, executable documentation, example tests,
a pinned official-reference differential suite, host/CLI integration tests and
package-consumer checks. All development and acceptance commands run locally;
CI repeats them when a commit is pushed. See [validation](docs/VALIDATION.md),
[release procedure](docs/RELEASING.md) and [contribution guide](CONTRIBUTING.md).

资源限制不等于通用安全沙箱。宿主决定导入权限；请阅读
[安全边界](SECURITY.md)。本项目采用 [Apache-2.0](LICENSE)，参考资料和测试来源见
[NOTICE](NOTICE)。
