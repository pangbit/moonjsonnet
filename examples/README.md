# Examples and validation drivers

[Chinese guide](README.zh-CN.md) · [Library quick start](../README.mbt.md#status-and-installation)

Three application examples show configuration generation and embedding. The other
eight directories contain development validation drivers. All require a source
checkout: `examples/`, its inputs and its tests are intentionally excluded from
the Mooncakes archive. A registry consumer can follow the library quick start
without any of these files.

## Prerequisites and working directory

Use macOS or Linux, a native C compiler and the
[validated MoonBit toolchain](../README.mbt.md#run-from-source). The
[CI workflow](../.github/workflows/ci.yml) shows the pinned installer command;
`moon version --all` should report Moon 0.1.20260920 and MoonBit
v0.10.14+7d59c7ec9. A separately installed Jsonnet interpreter is not needed.

```sh
git clone https://github.com/pangbit/moonjsonnet.git
cd moonjsonnet
moon version --all
moon check --target native --frozen --deny-warn -j 1
```

Run every command below from this repository root. The examples use the checked-in
files, not files from the shell's current subdirectory. `--frozen` uses the installed
SDK and existing dependencies; it does not install a toolchain. Native compilation
needs the platform's C build tools. `main` may advance; record `git rev-parse HEAD`
when reproducing an issue.

## Multiple environments

[environments/main.jsonnet](environments/main.jsonnet) imports
[template.libsonnet](environments/template.libsonnet). The function shares the app
and region, defaults to one replica, and derives an endpoint from `self.environment`.
The entry overrides production replicas and adds each environment's debug setting.
Keep both files together; a copied entry alone cannot resolve its import.

```sh
moon run --target native --frozen cmd/main -- examples/environments/main.jsonnet
```

The JSON value is the complete [expected.json](environments/expected.json):

```json
{
  "development": {
    "app": "checkout", "region": "local", "environment": "dev",
    "replicas": 1, "endpoint": "https://dev.example.test", "debug": true
  },
  "production": {
    "app": "checkout", "region": "local", "environment": "prod",
    "replicas": 3, "endpoint": "https://prod.example.test", "debug": false
  }
}
```

Change the calls in the entry to add an environment or override `replicas`.
This generates local JSON; the example endpoints are data and no deployment or
network request occurs. The template does not validate a deployment platform's
schema. To write the result to a new file instead of stdout:

```sh
moon run --target native --frozen cmd/main -- --root examples/environments -o result.json main.jsonnet
```

Choose an unused output filename. The restricted import root contains the entry
and template; see the [CLI file/output rules](../docs/reference/CLI.md).

## Batch dashboards

[dashboards/main.jsonnet](dashboards/main.jsonnet) reads
[services.json](dashboards/services.json) with `importstr` and `std.parseJson`.
A function and array/object comprehensions produce panels and a name-to-port map.
Keep these two files together. Run:

```sh
moon run --target native --frozen cmd/main -- examples/dashboards/main.jsonnet
```

The complete [expected.json](dashboards/expected.json) is:

```json
{
  "title": "Services",
  "panels": [
    {"id": 1, "title": "checkout requests", "target": "checkout:8080", "tags": ["http", "local"]},
    {"id": 2, "title": "catalog requests", "target": "catalog:8081", "tags": ["http", "local"]}
  ],
  "byName": {"checkout": 8080, "catalog": 8081}
}
```

Edit the service array to change the generated panels. The fixture contains objects
with a string `name` and numeric `port`; names must be unique for the `byName`
object. Panel IDs follow input order. This is an illustrative JSON structure, not
an exporter for a particular dashboard product. It does not connect to services,
listen on ports or check whether the named services exist.

## Embedded application

[embedded/main.mbt](embedded/main.mbt) imports the public `pangbit/moonjsonnet`
and `pangbit/moonjsonnet/fs` packages. It loads
[config/main.jsonnet](embedded/config/main.jsonnet), which imports
[defaults.libsonnet](embedded/config/defaults.libsonnet), through the relative root
`examples/embedded/config`. Keep the package and both configuration files in place.

```sh
moon run --target native --frozen examples/embedded
```

The first output line is this JSON value (field order is not significant):

```json
{"app":"checkout","port":8080,"retries":3,"replicas":3}
```

The program then deliberately catches and prints three diagnostics to **stdout**:

1. An `Assertion` containing `replicas must be numeric` for the string `"bad"`.
2. An `Assertion` containing `replicas out of range` for numeric `0`.
3. An `Import` error when resolving `../../../moon.mod` outside the configured root.

These are expected demonstrations. The example exits successfully only after the
valid evaluation and all three error checks succeed. Diagnostic locations/traces
may span multiple lines. An unexpected result raises an uncaught error. This
program's intentionally printed diagnostics differ from the CLI error channel:
the CLI writes its errors to stderr and exits nonzero.

The valid call supplies `replicas` as a JSON number using `ext_vars`; the Jsonnet
configuration requires a number from 1 through 10. A missing external variable
also fails. The equivalent valid CLI call is:

```sh
moon run --target native --frozen cmd/main -- --root examples/embedded/config --ext-code replicas=3 main.jsonnet
```

Change `Json::number(3)` in the MoonBit entry or the CLI expression to try another
valid value. The filesystem host provides controlled imports; resource limits and
root checks are not a general security sandbox. See [embedding](../docs/reference/API.md)
and the [security boundary](../SECURITY.md).

## Check the example outputs

```sh
moon test --target native --frozen --deny-warn -j 1 --no-parallelize -p pangbit/moonjsonnet/examples
```

[examples_test.mbt](examples_test.mbt) compares the first two programs with their
committed expected JSON and the embedded result with an independent literal. It
also checks missing/invalid parameters, limits and root escape. Comparison ignores
JSON object order and formatting. Deliberately changing a fixture can require
reviewing its expected output; do not update expectations merely to hide a failure.

## Development validation drivers

These eight runnable packages accept a JSON fixture on stdin and emit a JSON
observation. They are internal test adapters, not additional application tutorials
or stable public protocols. Their matching tools construct the inputs and verify
results; invoking a driver without its fixture is not a meaningful smoke test.
Optional Go comparisons require the separately pinned reference checkout described
in [validation](../docs/development/VALIDATION.md).

| Directory | Purpose | Fixture runner |
| --- | --- | --- |
| [ast-probe](ast-probe/main.mbt) | AST import, transformation and evaluation | [ast-integration.mbtx](../tools/ast-integration.mbtx) |
| [debugger-probe](debugger-probe/main.mbt) | Breakpoints, stepping, inspection and termination | [debugger-integration.mbtx](../tools/debugger-integration.mbtx) |
| [diagnostic-probe](diagnostic-probe/main.mbt) | Diagnostic formatting, traces and output modes | [diagnostic-api.mbtx](../tools/diagnostic-api.mbtx) |
| [evaluator-probe](evaluator-probe/main.mbt) | Reusable evaluator settings, imports and cached state | [evaluator-integration.mbtx](../tools/evaluator-integration.mbtx) |
| [formatter-node-probe](formatter-node-probe/main.mbt) | Formatting and raw-tree node/range operations | [formatter-node.mbtx](../tools/formatter-node.mbtx) |
| [formatter-probe](formatter-probe/main.mbt) | Source formatting and raw-tree reconstruction | [formatter-integration.mbtx](../tools/formatter-integration.mbtx) |
| [lint-probe](lint-probe/main.mbt) | Static-analysis and lint diagnostics | [lint-integration.mbtx](../tools/lint-integration.mbtx) |
| [parameter-probe](parameter-probe/main.mbt) | External/top-level arguments and embedding output modes | [parameter-integration.mbtx](../tools/parameter-integration.mbtx) |

Example execution and differential results cover the committed inputs only. They
do not establish complete Jsonnet conformance; consult the current
[compatibility boundary](../docs/reference/COMPATIBILITY.md).
