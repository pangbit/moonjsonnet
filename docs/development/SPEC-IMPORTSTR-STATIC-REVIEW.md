# Completion criteria for chk-importstr

Starting source: `b47c148`. The selected row is the previously unreviewed
`chk-importstr` at lines 1714-1718 of the retained fixed specification, Google
Jsonnet `bbb38f1020be1f5aed560928fb839b2c448cefb4`.
[Fixed source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking).
Its retained SHA-256 is
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
No network source is fetched in this batch.

## Exact rule and acceptance boundary

The rule has no premises and concludes `Gamma |- importstr s`. Its universe is
a well-formed core importstr constructor with a canonical string payload, in
any static environment. Completion of this rule means that static validation
accepts this constructor without looking up names, resolving a file, parsing
its contents or demanding a runtime value.

| Required condition | Independent expected behavior / evidence plan |
| --- | --- |
| Positive, all environments and payloads | Source and handmade AST leaves accept representative empty/keyword-like/NUL/Unicode/newline path strings and enclosing local/function/object contexts |
| Generalization beyond finite tests | Inspect the exact validator constructor arm: wildcard payload and raw flag, unconditional Unit result, no reference to names/in_object/resolver; inspect AST conversion for payload preservation |
| Negative within this rule | Not applicable: a well-formed importstr constructor has no rejecting premise; a missing/nonstring/computed source operand is a grammar failure before this judgment |
| Static laziness | Constructor validation does not resolve the target; unused runtime controls return 42 with zero virtual-resolver calls |
| Scope/phase boundary | Undefined variables elsewhere still reject Static; malformed source operands reject Syntax; opaque imported text containing undefined/self/super/root syntax remains literal data when separately demanded |
| Existing evidence reuse | ast_test's semantic round trip already creates source and exported-AST Programs containing importstr; creation acceptance is reused, not its equality comparison as a value oracle |

Completion requires both the structural case inspection and executed acceptance
controls. A finite test count alone does not establish universal acceptance. The
inspection covers every payload/environment for this leaf because those inputs
are not examined by the corresponding validator arm. This is an engineering
rule review, not a machine-checked proof of the whole interpreter.

The completion decision will be confined to this named static judgment. It does
not certify source lexing/quoting in general, enclosing checker rules, target
loading, canonical identity/caching, import permissions, UTF-8 decoding, errors,
resource limits or import/importbin. Runtime-error and value-type dimensions
are not applicable inside this static rule, rather than unknown passing cases.
Those surrounding language/host obligations remain separately open. Host
parse/shape/resource validation is outside the premise-free core judgment.

## Probe policy

This oracle is written before the first new execution. Fixtures are synthetic
strings and virtual resolver responses defined in test code. No actual imported
file, private file or network service is read. Source Program::parse and
handmade Program::from_ast are independent entry paths. Existing AST, anonymous
origin and syntax diagnostics are reused as focused regression controls.
There is no new CLI, full aggregate, release, upstream or remote run.
