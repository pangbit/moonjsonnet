# Operator rewriting and private standard-library binding

## Frozen criteria

Base b10a40fc3ece049d4b7a18c18991e9bd6d1696f2; official Jsonnet fixed at
bbb38f1020be1f5aed560928fb839b2c448cefb4. [Desugaring](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
(1111-1136, 1317-1345) supplies file-private $std and these equations:

```text
desugar(e) = desugar_expr(local $std = e_std; local std = $std; e, false)
e != e'   -> !(e == e') -> !($std.equals(e,e'))
e == e'   -> $std.equals(e,e')
e % e'    -> $std.mod(e,e')
e in e'   -> $std.objectHasEx(e',e,true)
e in super -> $std.objectHasEx(super,e,true)
```

The pinned [stdlib source](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet)
mod (256-262) and equals (1582-1616) independently determine the chosen normal
values and early unequal-Array result. Hidden membership follows the fixed
objectHasEx rule with true. Operator operands retain their lexical context.
A user local named std cannot replace the injected private binding.

There is no special rewrite for comparison, &&/|| or unary plus: the core
grammar retains them, and the desugaring preface recursively preserves
constructors without an equation. Reuse RS1-RS3, BS0-BS3, NB1, US1 and PI3 for
these already reviewed subsets. B0 and the greater-than printed conflict are
unchanged; no non-Boolean longcut or competing-error-order oracle is invented.
Reuse PG1/PG3 and EX1-EX3 for applicable equality/membership children.

The public Ast is documented semantic syntax, not a desugared Core export.
New original-source and handmade Binary trees are compared to independently
written reference Call/Unary trees using a captured standard-library alias.
Every form has its own literal expected result; one implementation output
does not supply another's oracle. The captured alias models $std without
attempting to spell a private identifier in public source/host AST input.

| Group | Independent required outcome |
| --- | --- |
| OR1 | Under std bound to an error, ==/!= over unequal Array prefixes ignore error tails, numeric and String % dispatch yield 1/[ok], and hidden/missing in yield true/false. Original and reference Call/Unary forms agree with literal results. Fresh native head gates record each demanded L/R once; ignoring the whole expression records none and returns 42. |
| OR2 | Core Boolean shortcut and Boolean longcut cases still preserve demanded/skipped sides under std shadowing, with no demanded non-Boolean RHS. Every rewritten operator propagates one isolated left/right error in original and reference forms, and unused whole expressions stay lazy. The other operand is harmless, so no competing-error order is asserted. |
| OR3 | A function defined in a middle object layer and extracted from the final object retains membership in its lexical super prefix. Hidden h and a exist there; same-layer b and later c do not. Four keyed probes run once each only when called, with no field-value demand; ignored whole calls record none. |

Counts are finite host observation controls against duplicated/dropped operand
demands, not a universal native callback-order or call-by-name theorem. The
in-super reference also has a structural check: both the direct path and
objectHasEx(true) use has_field on the captured Object(id,top) prefix. No bare
super Call is claimed as admissible public surface AST; that host view differs
from formal Core. Full child equality/mod/format/visibility/inheritance/static
and invocation judgments remain separate, especially PE0/N0/R0.

Three bounded native debug groups, sequential nice 10/frozen -j 1, no parallel
testing. Preserve first actual failures before any minimal product repair.
Reuse schema v2 without new checker machinery. Only scoped evidence is eligible;
DESUGAR-OPERATORS remains partial without whole-equation/child-domain proof.
No full suite, release/Linux, remote/browser/install/push or private proposals.
All A0/B0/N0/R0/PE0, encoding and prior child-relative limits remain intact.

<!-- Criteria above are frozen before execution; append results below. -->

## Results

The first native debug invocation passed **3/3**, exit 0, in 7.779 seconds:
`nice -n 10 moon test spec_operator_rewrites_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize`.
The formatted test SHA-256 remained
`ea6f10a9e4ce289d228c21c0d0dc10d1efc9d8ee2f791e645e6523ee665b59e4`
through final checks. No product failure, repair, oracle change or semantic
rerun was needed. Earlier comparison/logical/static evidence was mapped within
its original scope, without rerunning it or resolving its open domains.

OR1 checks original Binary forms and independently constructed reference
Call/Unary forms against literal expectations through both entry paths.
OR2 adds bounded demand-count controls to the existing Boolean demand-membership
evidence and isolates each rewritten operand's error without imposing priority
between two failures. OR3 tests legal original in-super syntax/AST; it does not
assert that a bare-super Call is legal through the public AST validator.

Inspection supports these witnesses: `imports.mbt` binds std/$std to the same
library thunk; `%` in `eval.mbt` calls that private library's source-defined mod
with pending operands. Direct equality and the native equals entry both use
`Vm::equal`. Direct in and objectHasEx(true) both use `has_field(id,top,key)`;
`objects.mbt` captures super at the defining layer while retaining final self.
The [public AST contract](../reference/API.md) retains semantic syntax rather
than formal Core metadata. These implementation facts support the fixed-text
expectations; they do not supply the oracle or prove every child domain.

Root check, info, fmt, script-format check and schema-v2 matrix generation each
exited 0. The checker/harness, old tests, product sources and public interfaces
are unchanged. All 179 old evidence objects, 68 named review records and 23
other prose records remain unchanged; only OR1-OR3 and this partial clause were
added. The mapping has **182 canonical case IDs**, not 182 newly run tests.
The 94-row matrix is **28 named complete (9 static, 19 evaluation), 1 relative
constructor complete, 61 partial, 4 unreviewed**. DESUGAR-OPERATORS remains
partial; full lowering, stdlib domains, child judgments, universal callback
order/count and the listed unresolved boundaries remain outside this result.

Raw receipts: `/tmp/moonjsonnet-operator-rewrites.bgt7wxwi`. No upstream
comparison, full suite, remote operation or push ran. The historical 539/539
suite result still belongs only to 5651ae9. A useful next distinct review is
the remaining SYN-EXPR surface grammar contract, using existing precedence and
token evidence without revisiting the greater-than or malformed-||| questions.
