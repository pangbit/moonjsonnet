# Static error constructor: pre-execution criteria

Starting source: `6b4aa005764aff338611d617e536e641b0b886e1`. Fixed official
Jsonnet specification: `bbb38f1020be1f5aed560928fb839b2c448cefb4`; retained
spec.html SHA-256
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
Expected outcomes below are fixed before executing the new probes. No new
network source or Go/C++ execution selects their oracles.

## Exact judgment and scope

[chk-error](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
at lines 1730-1734 requires Gamma to check the operand e before accepting
error e in that same Gamma. It introduces no binder, string-type constraint or
evaluation premise. Its completion is limited to forwarding the operand to its
own checker with unchanged scope/object context, assuming that child judgment.
It does not complete all operand forms or their enclosing constructs.

The [execution introduction and error prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at lines 1764-1766 and 2844-2851 model explicit errors as stuck execution and
require the operand's value when error is demanded. There is no named error
execution rule. Conversion of non-string operands and presentation/stack traces
are outside this static review; public ErrorKind and exact marker strings below
are embedding boundary controls, not standardized diagnostics.

## Necessary new probes and independent expectations

| Condition | Expected result through source and independently handmade AST |
| --- | --- |
| Missing operand name | error missing rejects Static at Program creation; so do an unused local initializer and an unselected branch containing that error |
| Object permission is unchanged | error self.message and error super.message reject Static outside objects; unused error operands using self in an object or super in a derived object create successfully and return outer 42 |
| Gamma is retained | An outer message binding remains visible to an unused error operand; the enclosing expression returns the explicit 42 |
| No static string requirement | An unused numeric operand creates successfully and returns outer 42; this does not review every type's runtime conversion |
| No operand evaluation when unused | A native operand callback runs zero times during Program creation and unused-local/unselected-branch evaluation, which returns 42 |
| Actual demand is a runtime boundary | The same native string operand creates successfully, then runs once and raises public Runtime with its fixed marker when error is demanded |

Invalid cases isolate one error operand. No priority among simultaneous static
failures is specified. The new tests must not derive expected values from AST
export, another implementation or the interpreter's actual output.

## Existing evidence and exclusions

A3 already creates a handmade error-with-string-operand inside a skipped
comprehension body and returns the explicit empty object. AP4 already creates
source/handmade string-valued error callees and observes Runtime without argument
callbacks. Reuse these exact assertion meanings rather than duplicating their
literal/error controls or counting them as new tests. Existing conditional and
local/object child reviews retain their own completion/partial status.

Inspect validate.mbt's single Fail-child delegation, ast_convert.mbt's preserved
Fail child and ast_validate.mbt's absence of an error-specific type restriction.
Finite tests support that structural argument; completion is an engineering
review relative to child judgments, not a whole-interpreter proof.

Full error runtime conversion, child/binder/object algebra, full source grammar,
malformed host AST metadata, diagnostic presentation, resource/stack limits and
CLI exits remain outside this review. All new fixtures are self-made and use
virtual callbacks without imported-file, private-document or network I/O.
No full-suite, remote, additional-platform, installation or reference-compatibility
campaign is included. Earlier macOS/Linux counts keep their original source
identities. No push, tag or release is authorized.
