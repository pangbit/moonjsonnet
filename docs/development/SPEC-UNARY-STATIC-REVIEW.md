# Unary static constructor: pre-execution criteria

Starting source: d3938ffa7e799832c8d9b42b7e6d0bc10bfcbcb7. The fixed official
Jsonnet specification is bbb38f1020be1f5aed560928fb839b2c448cefb4; retained
spec.html SHA-256
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a.
The following oracles precede new execution and do not come from Go/C++ or the
implementation's output.

## Exact judgment and domain

[chk-unary](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
at lines 1684-1688 checks the operand e in the same Gamma before accepting
sym e. The fixed grammar at lines 774-778 supplies exactly - + ! ~.
The judgment has no Boolean/numeric-type or evaluation premise and introduces
no binding. Completion concerns only delegation to the operand's checker with
unchanged names/object context, assuming that child's own static judgment.

The [execution reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
models failures as stuck execution at lines 1764-1766; numeric unary operations
are described at lines 2796-2815. Operand type rejection on actual demand is
an adjacent runtime boundary, not a new static premise or completion of unary
evaluation. Public Syntax/Static/Type tags and source identities are host phase
controls; exact diagnostics and traces are not normative oracles here.

## Independent necessary outcomes

| Condition | Expected result |
| --- | --- |
| All four valid symbols | Source and independently handmade unary nodes create successfully with statically valid operands; unused enclosing expressions return the explicit 42 |
| Missing operand name | All four reject Static at Program creation, directly and inside unused-local/unselected-branch wrappers |
| Gamma and object context | Bound n remains visible. self.n/super.n reject outside objects; unused own-self and inherited-super operand contexts accept through both entry paths |
| No static type predicate | The same numeric binding is accepted even beneath ! when the unary expression is unused; checking does not perform the later Boolean requirement |
| Laziness and Type boundary | A virtual operand callback returns null. Creation and unused-local/unselected-branch evaluation invoke it zero times and return 42; actually demanded unary operations invoke it once then reject Type, for each symbol and both entry paths |
| Missing source operand | Each bare legal prefix rejects Syntax before a Program exists. The typed Unary constructor cannot represent an absent child |
| Invalid host operator metadata | Reuse the existing handmade Unary("bad", one) rejection as Static during AST creation; this is outside the well-formed symbol domain, not a source Syntax or runtime Type result |

Expected values, categories and zero/one callback counts are supplied directly.
Handmade trees must not be obtained from parser/export round trips. Each static
negative has one invalid operand; no precedence among simultaneous failures is
invented.

## Existing controls and explicit exclusions

Reuse the exact invalid-operator assertion in ast_test.mbt and the independent
finite array result in parser_diagnostic_test.mbt's unary-prefix control.
Do not duplicate these groups or count their old execution as new. Earlier
conditional/error and variable/local/object reviews retain their own status;
their coverage does not complete every possible operand or enclosing judgment.

Inspect validate.mbt's single-child Unary delegation, ast_convert.mbt's
operator/child preservation and ast_validate.mbt's exact four-symbol predicate.
This structural argument, supported by finite probes, is an engineering review
relative to child judgments rather than a proof of the whole interpreter.

All unary evaluation rules, complete valid-value behavior, IEEE details,
signed-64-bit conversion, overflow, source precedence/lexing/desugaring,
malformed host metadata beyond the reused operator control, child/binder/object
algebra, diagnostics, resource/stack limits and CLI behavior remain outside this
completion. Fixtures are self-made virtual callbacks without imported-file,
private-document or network I/O. No full-suite, remote, additional-platform,
installation or compatibility campaign is included. No push, tag or release.
