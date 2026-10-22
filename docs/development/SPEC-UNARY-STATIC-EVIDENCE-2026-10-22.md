# Completed static constructor transfer: chk-unary

**Decision: chk-unary is reviewed complete for the four well-formed grammar
symbols, relative to its operand's static judgment.** This closes unchanged
scope/object-context delegation, not unary evaluation or every child rule.
The [pre-execution criteria](SPEC-UNARY-STATIC-REVIEW.md) fix the domain,
independent expectations and exclusions before the new probes.

The fixed [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
is bbb38f1020be1f5aed560928fb839b2c448cefb4. Grammar lines 774-778 enumerate
the four symbols (-, +, ! and ~). chk-unary at lines 1684-1688 requires only
the same-Gamma operand judgment; it has no Boolean/numeric-type or evaluation
premise. Runtime failure
is modeled as stuck execution. Public Syntax/Static/Type categories below
identify embedding phases rather than standardized diagnostic presentation.

## Independent entry paths and phase boundaries

The [new probes](../../spec_unary_static_test.mbt) construct their ASTs by hand,
independently of the source parser, AST export and reference implementations.

| Obligation | Observed evidence |
| --- | --- |
| Check every unary operand | US1 rejects a missing name directly and under unused-local/unselected-branch wrappers for all four symbols, through source and handmade AST, at Program creation with Static |
| Preserve Gamma | Bound n=0 remains accessible under every symbol; unused enclosing expressions return the explicit 42, including ! over numeric n without a premature Boolean requirement |
| Preserve object permission | US1 rejects self.n/super.n outside objects; unused own-self and inherited-super operands create successfully through both entry paths and return outer 42 |
| Do not demand unused operands | US2 creates Programs with zero operand callbacks; unused-local/unselected-branch evaluation returns 42 and leaves that count at zero for all symbols and both entry paths |
| Separate actual Type failure | Demanding each unary operation calls the independently defined null-valued operand once, then raises host Type after Program creation. This boundary does not complete valid-value unary behavior |
| Source-only Syntax | US3's four bare legal prefixes reject Syntax before a Program exists. An absent child cannot be represented by the typed Unary constructor |
| Host AST shape | Reused US0 rejects Unary("bad", one) as Static during handmade AST creation. Invalid symbol metadata lies outside the well-formed named judgment; it is not source Syntax or runtime Type |
| Reused normal control | UP0's independent finite source array protects prefix minus/logical-not/bitwise-not combinations, without establishing all unary semantics |
| Runtime-error dimension within chk-unary | N/A: the static judgment has no evaluation premise. The observed Type failures remain adjacent boundaries |

US0 and UP0 are existing assertions in
[ast_test.mbt](../../ast_test.mbt) and
[parser_diagnostic_test.mbt](../../parser_diagnostic_test.mbt). Their exact
meaning and current file hashes are mapped without rerunning them or adding
their earlier execution to this batch's count. No parser round-trip equality
is used as an independent value oracle.

The structural argument is validate.mbt's unconditional single-child
Unary(_, a) delegation to validate(a, names, in_object). ast_convert.mbt
preserves both operator and child. ast_validate.mbt admits exactly the four
grammar symbols and adds no operand numeric/Boolean predicate. These inspected
cases generalize beyond the finite probes relative to the operand checker;
they do not establish correctness of all operand forms or arbitrary host inputs.
This is an engineering review rather than a machine-checked interpreter proof.
No product defect was observed within this scope.

## Execution identity

Base source: d3938ffa7e799832c8d9b42b7e6d0bc10bfcbcb7, tree
892029c11eff227988a4cba99d385327184052a9, plus the new test file below.
Pre-run snapshots pin the criteria, exact executed test and inspected/reused
source hashes; those bytes remain unchanged after formatting and matrix work.
Existing Darwin arm64 tools: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9. No interpreter implementation, dependency or public
interface changed. Fixtures are self-made virtual callbacks without imported
files, private documents or network I/O.

One focused native debug invocation passed **3/3, exit 0**, on its first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_unary_static_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

The three groups contain both entry paths and the source-only Syntax controls;
they are counted once. Reused groups and previous conditional/error/full-suite
counts are not added. No second semantic run followed documentation/mapping
changes. Typecheck, info/format and matrix commands ran sequentially with frozen
dependencies and reduced priority, one worker where supported. Installed
info/fmt have no worker-count option.

## Matrix and final verification

The [matrix](SPEC-LANGUAGE-MATRIX.md) now records **8 completed named rules
(6 static, 2 evaluation), 42 partial rows and 44 unreviewed rows**, still
70 named rules plus 24 initial prose/grammar rows. Only chk-unary changes
completion state. STATIC-TRAVERSAL adds the new static control while remaining
partial. Unary execution/desugaring and all child-rule completion states remain
unchanged. Public stdlib remains 35/153 partial reviews; whole-language
acceptance and execution inference remain false.

The new metadata form is restricted to chk-unary and pins the exact statement,
operand role, four-symbol domain, child assumptions and inspected source/test
hashes. Four temporary records each exit 1 at the expected guard before output:
changed statement, wrong operand role, extended symbol domain and transplantation
to chk-error. The real matrix files remain byte-identical during those controls.
Source/name matches do not infer execution or semantic correctness.

| Final check | Result |
| --- | --- |
| Focused native debug tests | 3/3; exit 0; no snapshot updates |
| Root native check | Exit 0 with --frozen --deny-warn -j 1 |
| Root info then fmt; matrix script fmt --check | All exited 0; no .mbti changes |
| Matrix validation/regeneration | Exit 0; counts and inspected hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 143 files and 1083 local/current-source links passed |
| Whitespace and final file scope | Working/staged diffs pass git diff --check; exactly seven scoped files, with no existing implementation/interface changes |

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-execution criteria | 234ec029dd3af8240765a1228ee50fb3e08d0d13298be1675ec7052ef40e5551 |
| Executed test file | 4595a91bb4d5bcf2521048626ba09e08fef98882d28fe2b66642e5110fa5d14d |
| Passing 3/3 log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| Negative-control records | 43e8729527f30feb64aa9947e8c12e29aab86e249b4f552884df1d2d1651a766 |
| Matrix log | ccb92980603243b253ddde1ca38468f5b9446732d2f87824bb9ce2ab9a559161 |

Raw evidence: /tmp/moonjsonnet-chk-unary.iRoEgh. Temporary artifacts are not an
archival delivery guarantee; committed tests, criteria and the
[machine-readable matrix](spec-language-matrix.json) retain assertions, source
hashes, child assumptions and exclusions.

All unary execution rules, complete valid-value semantics, IEEE/overflow and
signed-64-bit behavior, full source grammar/desugaring, remaining host metadata,
child/binder/object algebra, diagnostics and host resource/stack/CLI behavior
remain outside this completion. [Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md)
stays separate and unknown for new cases. Older macOS/Linux counts remain bound
to their own sources. No full-suite, release, remote, additional-platform,
installation, push or tag campaign occurred.
