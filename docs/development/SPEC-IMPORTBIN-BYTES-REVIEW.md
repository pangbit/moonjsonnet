# Importbin byte substitution: bounded acceptance criteria

Starting source: `a7dd10355ead13672e5ec7910a458ca25cb2fe1f`. The fixed
Google Jsonnet specification is
`bbb38f1020be1f5aed560928fb839b2c448cefb4`, retained spec.html SHA-256
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
[Core Syntax](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax),
lines 911-924, defines three distinct substitutions and their loading boundary.
No network source is fetched in this batch.

## Selected actual loading contract

The selected sentence at line 916 requires importbin to substitute file contents
as an array of integer numbers from 0 through 255 inclusive. For a successfully
provided finite byte sequence, within the configured resource bounds, the result
must preserve its length, order, repetitions and unsigned byte values. Empty
input produces an empty array. Binary bytes are data, so malformed UTF-8 and
bytes that happen to spell Jsonnet code must not be decoded, parsed, checked as
variables or evaluated as that code.

This is one value-substitution contract inside the existing CORE-IMPORT matrix
row. It does not add duplicate inventory rows or close the full import system.
The exact-request cache and loading/error timing below are boundary controls;
their complete host and canonical-identity contracts remain outside this scope.

| Necessary condition | Independent oracle and evidence plan |
| --- | --- |
| Every possible byte | Use all 256 byte values in a nonmonotone permutation; compare exact JSON integers calculated from the declared permutation, not against another implementation or an AST copy |
| Empty/order/repetition | Exact empty and repeated/high-bit/NUL arrays; inspect the one-append-per-byte loop as the generalization beyond finite input lengths |
| Opaque input | Exact arrays for malformed UTF-8 and an executable-looking error expression; no parser or UTF-8 decoder belongs on the binary substitution path |
| Independent entry paths | Program::parse source and a typed ImportBinary handmade AST must each produce the same independently specified array; source/exported-copy equality is insufficient |
| Static/grammar boundary | Nonliteral source operands fail Syntax; an undefined sibling fails Static in source and handmade AST before a resolver can be used |
| Demand boundary | Unused source and handmade imports return 42 without resolver calls; demanding a disabled or failing virtual resolver raises public Import during evaluation, not during Program creation |
| Cache boundary | Reuse the existing exact-byte/single-request language test; add an explicit handmade repeated-import result and request count. Do not infer canonical alias, cross-mode or failure-cache correctness |

The success contract has no rejecting byte value. Its negative-byte case is
therefore N/A, rather than an unexecuted error counted as passing. Resource-limit
and host failures are separate boundaries. Public Import is a runtime-phase
diagnostic category; it is not the category Runtime. No CLI exit-code claim can
be made from a library exception test.

Completion requires executed exact-array controls plus structural inspection of
the binary conversion loop and its entry dispatch. This is an engineering review,
not a machine-checked proof. Tests will use only self-made Bytes values and virtual
resolver callbacks. No actual imported file or private document will be read.

## Adjacent static judgments reuse the same argument

At fixed lines 1706-1726, chk-import, chk-importstr and chk-importbin all have
empty premises. Their only distinction is the constructor accepted. The reviewed
validate.mbt arm accepts both wildcard ImportFile(_, _) modes and ImportBinary(_)
unconditionally, without consulting names, object context, target data or a
resolver. ast_convert.mbt preserves both typed leaves; ast_validate.mbt adds no
import-specific scope or payload constraint. Shared host shape/metadata limits
are outside these premise-free core judgments.

The existing ast_test semantic round-trip group creates source and exported-AST
Programs containing all three constructors. Only that creation acceptance is
reused, not its equality assertion as a value oracle. Existing I1-I3 and IR1-IR4
remain their respective independently reviewed boundary controls. These adjacent
static judgments do not need duplicate execution groups solely to raise a rule
count; record their common constructor argument and exact evidence instead.

## Explicit exclusions

- Full lexing/quoting, enclosing static rules, malformed public-AST metadata,
  and all parser diagnostics.
- UTF-8 decoding for importstr/import, code-import scope/evaluation, cycles,
  path canonicalization and filename aliases.
- Complete cross-mode/source/value/failure cache identity and lifetime rules;
  the probe covers repeated identical requests only.
- Host file access, permissions, resolver replacement/reentry, I/O failure
  retry policy and resource accounting.
- CLI error status, Go/C++ compatibility, release/full-regression/platform and
  remote verification. All remain unexecuted for the new cases.
