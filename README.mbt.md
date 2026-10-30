# MoonJsonnet

[Chinese overview](README.zh-CN.md) · [Documentation](docs/README.md)

An embeddable Jsonnet interpreter written in MoonBit. It parses and evaluates
source directly; no Jsonnet executable or shared library is required at runtime.

The library and CLI support lazy evaluation, lexical closures, object inheritance,
controlled imports and JSON output. The language target is Jsonnet v0.21.0 with
no intentionally excluded language constructs. All 163 standard-library members
in the fixed reference inventory are registered; finite differential checks and
documented differences define the tested scope, not universal equivalence.

[google/go-jsonnet](https://github.com/google/go-jsonnet) is the functional reference
for language semantics, standard-library behavior, embedding APIs and CLI behavior.
The differential tools record pinned Go/C++ Jsonnet v0.21.0 results separately.
See [compatibility](docs/reference/COMPATIBILITY.md) for the reference contract and tested scope.

## Status and installation

Version 0.2.2 targets **native on macOS and Linux**. File access uses POSIX libc;
the evaluator itself has no third-party runtime dependency. See
[compatibility](docs/reference/COMPATIBILITY.md) before adopting existing Jsonnet programs.

The historical compatibility record retains its original differences:

| Reference corpus | Raw result |
| --- | --- |
| C++ | 108 cases: 98 compatible + 10 declared differences |
| Go whole CLI | ARM64 1132/1150; AMD64 1131/1150 |
| Go reusable evaluator / lint | 20/21 / 409/410 |

The historical acceptance contract retained 18 CLI and 1 lint reference-crash
exceptions, the separate optional `import_ast` API and same-architecture NaN
behavior. Those raw failures are not relabeled as passes. Subsequent normative
fixes reject non-finite numbers and fractional indices, preserve array
immutability and propagate YAML errors. The Go totals have not been rerun
for these changes. The current C++ recheck and explicit declaration migrations are
tracked in [CI validation](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/CI-VALIDATION.md);
historical totals do not establish current full specification conformance.

Version 0.2.2 corrects decoded field-name checks, inherited standard-library
dependencies, strict native calls and evaluation-hook inspection, and adds
compatible `removeAt` index aliases. Public MoonBit API signatures are unchanged.
See the [changelog](CHANGELOG.md) and the
[registry record](https://mooncakes.io/docs/pangbit/moonjsonnet@0.2.2) for the release
and version availability. Earlier versions retain their documented historical
behavior. Full specification conformance remains unestablished.

Install the versioned native library:

```sh
moon add pangbit/moonjsonnet@0.2.2
```

Import `"pangbit/moonjsonnet"` in your `moon.pkg`, and use the native target.

A minimal executable uses these files after adding the dependency:

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

Save the MoonBit source as `main.mbt`, then run `moon run --target native .`.
It prints `{"answer":42}`. For local archive evaluation, the same example can use
an unpacked archive as a workspace member; the dependency name stays the same.

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

The root library takes source text, JSON/Jsonnet external variables and top-level arguments, an optional host
import resolver and per-evaluation limits. It returns `Json` or `JsonnetError`.
`evaluate_text` returns formatted JSON or plain strings; `evaluate_stream`
returns JSON documents from a top-level array. `evaluate_multi` returns
filename/content pairs without writing files. The separate `pangbit/moonjsonnet/fs`
package loads files within a configured root. See [API and host contract](docs/reference/API.md).

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

Host callbacks receive JSON arguments in parameter order. Trace output defaults
to stderr; an optional callback receives the call location and message.

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

## Evaluation inspection

Diagnostics retain source ranges and named/synthetic trace frames. The configurable
`DiagnosticFormatter` renders Go-style errors; the original `Diagnostic::format`
remains available. Supply source text to render static error snippets and optional
color. See [diagnostics](docs/reference/API.md).

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

Evaluator hooks observe demanded expressions. Inspect values inside the callback;
copy returned nodes, text or JSON to retain them. The synchronous debugger adds
breakpoints, stepping, finish and termination. See [API](docs/reference/API.md).

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

## Source formatting

`format_source` and `ParsedSource::format` format source without evaluating it or
resolving imports. The formatter, editable raw tree and formatter CLI are available;
their tested scope and remaining compatibility boundaries are recorded in
[compatibility](docs/reference/COMPATIBILITY.md).
`format_syntax_source` and `SyntaxDocument` provide independent source-tooling
budgets for deep trees; evaluator admission and existing `Limits` stay unchanged.
`RawAst` exposes ordered tokens, trivia and child nodes for lossless edits.
`format_node` formats the edited expression with separate EOF fodder; `clone`
isolates mutable containers. See the [raw syntax contract](docs/reference/API.md).

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

## Run from source

Development toolchain: Moon 0.1.20261028 / MoonBit v0.10.18+6c83a7f62.
The [version baseline](docs/reference/VERSIONS.md) separates this migration from
the published 0.2.2 validation on the previous compiler.

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
[example walkthroughs and development-driver index](https://github.com/pangbit/moonjsonnet/blob/main/examples/README.md).

```sh
moon run cmd/main -- --root examples/embedded/config --ext-code replicas=3 main.jsonnet
moon run cmd/main -- --root examples/environments -o result.json main.jsonnet
```

CLI success writes manifested output; errors go to stderr and return a nonzero status.
Aggregate overflow returns a runtime error. See [compatibility](docs/reference/COMPATIBILITY.md).
`--ext-code` accepts Jsonnet expressions evaluated lazily when used. See [CLI](docs/reference/CLI.md).

## Validation and contribution

The project includes semantic tests, executable documentation, example tests,
a pinned official-reference differential suite, host/CLI integration tests and
package-consumer checks. CI runs the repository's pinned checks on macOS and Linux;
the full Go differential and sanitizer evidence comes from separate recorded runs.
Development commands and fixtures require a source checkout and are excluded from
the published archive. See repository [validation](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/VALIDATION.md),
[release procedure](https://github.com/pangbit/moonjsonnet/blob/main/docs/development/RELEASING.md)
and [contribution guide](https://github.com/pangbit/moonjsonnet/blob/main/CONTRIBUTING.md).

Resource limits do not provide a general security sandbox. The host controls import
permissions; read the [security boundary](SECURITY.md). The project uses
[Apache-2.0](LICENSE); reference material and test provenance are recorded in [NOTICE](NOTICE).
