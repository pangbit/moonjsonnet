# Completed static constructor transfer: chk-error

**Decision: chk-error is reviewed complete relative to its operand's static
judgment.** Its sole task is to check that operand in the unchanged Gamma/object
context; it does not evaluate it, introduce a binder or require a string type.
The [pre-execution criteria](SPEC-ERROR-STATIC-REVIEW.md) fix the independent
expectations and exclusions. This does not complete its child rules, error
runtime semantics or whole-language conformance.

The fixed [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#static_checking)
is bbb38f1020be1f5aed560928fb839b2c448cefb4. chk-error at lines 1730-1734 has
one same-Gamma operand premise. Execution lines 1764-1766 and 2844-2851 model
errors as stuck execution and describe operand demand; there is no named error
evaluation rule. Exact public categories, locations and marker presentation
below are host boundary controls rather than standardized diagnostics.

## New evidence and reused child controls

The [two new groups](../../spec_error_static_test.mbt) separately exercise source
parsing and independently handmade AST conversion; no exported source AST or
reference implementation supplies the tree or expected output.

| Obligation | Actual result through both entry paths |
| --- | --- |
| An operand must check even when error is unused | error missing rejects Static at Program creation directly, inside an unused local initializer and inside an unselected branch |
| Object permission is forwarded | self/super operands reject Static outside an object; unused self and inherited-super object operands create successfully and the enclosing expression returns the independent 42 |
| Gamma is forwarded | The error operand accepts an outer message binding; unused error evaluation returns outer 42 |
| There is no static string predicate | An unused numeric operand creates successfully and the outer expression returns 42; no general runtime conversion acceptance is claimed |
| Error stays unevaluated when unused | Callback counts remain zero after creation and after unused-local/unselected-branch evaluation, both of which return 42 |
| Actual demand crosses a runtime boundary | A valid string callback operand creates successfully, then runs exactly once and raises Runtime with its predefined marker |
| Runtime error inside this static rule | N/A: chk-error has no evaluation premise; the Runtime observations above remain adjacent phase controls |

Existing A3 already creates a string-operand error in a skipped handmade
comprehension body and produces an empty object. Existing AP4 already creates
source/handmade error callees, then observes their Runtime string marker before
any argument callbacks. Their
[form](SPEC-LANGUAGE-FORMS-EVIDENCE-2026-10-22.md) and
[application](SPEC-LANGUAGE-CALL-EVIDENCE-2026-10-22.md) evidence remains attached
to its original source. Those assertions are reused without new execution or
addition to this batch's test count. Variable/local/object and other operand
judgments retain their existing partial/completed status.

The structural argument is validate.mbt's unconditional
Unary(_, a) | Fail(a) delegation to validate(a, names, in_object).
ast_convert.mbt preserves Fail and its sole child; ast_validate.mbt adds no
Fail-specific type/scope restriction. These cases cover the constructor
relative to child checking beyond the finite probes. This is an engineering
review, not a machine-checked proof of the children or interpreter. No product
defect was observed, and no interpreter/dependency implementation changed.

## Execution identity

Base source: 6b4aa005764aff338611d617e536e641b0b886e1, tree
b703af4a49f8d6d14001468035b4937ab78916ff, plus the new test file identified below.
The retained pre-run manifests pin the criteria, exact test bytes and inspected
implementation/reused-test hashes. Existing tools on Darwin arm64:
moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9.
All fixtures are self-made with virtual callbacks; no actual imported file,
private document or network service is read.

The first invocation exited 1 before executing tests: the new helper's generic
raise effect made its exception catch non-exhaustive under --deny-warn.
Narrowing that helper to public JsonnetError corrected the test adapter without
changing criteria, oracles or product code. That compile failure and initial
source are retained; they are not counted as passing tests.

The corrected, single affected native debug command passed **2/2, exit 0**:

```sh
nice -n 10 env RUST_LOG=error moon test spec_error_static_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

The new groups include both entry paths; neither the reused A3/AP4 groups nor
earlier 27/27 conditional results are added to this count. No semantic rerun
followed mapping/documentation edits.
Root moon check also exited 0 with --target native --frozen --deny-warn -j 1.

## Matrix and final checks

The [matrix](SPEC-LANGUAGE-MATRIX.md) now records **7 completed named rules
(5 static, 2 evaluation), 42 partial rows and 45 unreviewed rows**. It still
enumerates 70 named rules plus 24 initial prose/grammar rows. Only chk-error
changes completion status; public stdlib coverage remains 35/153 partial reviews
and whole-language acceptance remains false.

The generator restricts the new transfer record to chk-error, checks its exact
pinned statement/operand role, child assumptions, necessary evidence, N/A reason
and inspected source/test hashes. Three temporary negative records each exit 1
at the expected guard before output: changed statement, wrong operand role and
transplantation to chk-unary. Repository outputs remain byte-identical during
those controls. Unchanged conditional/import records retain their own validation
paths. No source/name match infers execution.

One matrix invocation lost its process result during an execution-transport
outage. Its complete log and output hashes were recovered before any retry.
A final local validation supplies the explicit exit status below.

| Final check | Result |
| --- | --- |
| Matrix validation and regeneration | Exit 0; 7/42/45 counts and complete output hashes confirmed |
| Tracked/staged-only documentation checker | Exit 0; 141 files and 1069 local/current-source links passed |
| Root info then formatting; matrix script formatting | All exited 0; frozen native root info precedes root fmt; the script passes fmt --check |
| Public interface and whitespace checks | No .mbti changed; git diff --check passed |

| Retained artifact | SHA-256 |
| --- | --- |
| Pre-execution criteria | ae1acb7f5b5e3c1c8f39b27d2a9a2593cae1251402b14561eecc5a2faab83804 |
| Initial helper source | 7944057ca8b42aa0343f763b4dcab165911f919843055a79a3b1a991f01fa679 |
| Initial compile-failure log | efe87d97e81224e4f43bd2ae48df4f2b39f6a38a02da10b220ba50d04afb41a1 |
| Corrected test source | b931793ba7ad955b4a83f30600f6eeaca66c2ff0e99640004c059254866e9610 |
| Passing 2/2 log | ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120 |
| Negative-control records | 44afee405c07f37f562205dee1848b85cf45c7f2e76fa9bd147bd8eb504e8190 |
| Confirmed final matrix log | 771b6858ece63ee7f5cce845896de30f801823c3f953c76a19bd462382430fae |

Raw evidence: /tmp/moonjsonnet-chk-error.Ish5It. Temporary artifacts are not an
archival delivery guarantee. Committed criteria/tests and the
[machine-readable matrix](spec-language-matrix.json) retain the assertions,
source hashes, assumptions and excluded obligations.

Full error-value conversion, all child/binder/object algebra, source grammar,
malformed host AST metadata, manifestation/diagnostic presentation and host
resource/stack/CLI behavior remain open. The
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains separate and
unknown for these new cases. Older macOS/Linux results retain their original
source identities. No full-suite, release, remote, additional-platform,
installation, push or tag campaign occurred.
