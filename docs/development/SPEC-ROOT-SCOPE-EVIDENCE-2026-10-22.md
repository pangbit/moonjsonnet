# Nested lexical roots: bounded execution evidence

**Decision: the predefined ordinary-field and zero-argument-factory lexical
root group is reviewed complete.** Nested self, inherited outer roots,
standalone right-hand root bindings and extracted functions retain the
contexts fixed in the [pre-execution criteria](SPEC-ROOT-SCOPE-REVIEW.md).
This does not complete DESUGAR-ROOT, object inheritance/indexing or the
general substitution rules.

## Fixed definition and its limits

The normative input is the [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#desugaring)
at bbb38f1020be1f5aed560928fb839b2c448cefb4. Its object-context rules at
lines 1131-1165 introduce $=self for an outer object and preserve existing
bindings in a nested object. The function rule at line 1208 passes the
definition-context flag into the body. Indexing/inheritance then supplies
the appropriate receiver for that outer binding.

The pinned [language guide](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
still lists precise $ semantics as unfinished in its lines 655-661 comment.
This review uses the explicit object/function-context fragments above; it
does not invent a complete prose definition or resolve every desugaring,
key/local/comprehension/default case by analogy. Go/C++ agreement is not the
oracle.

## Actual source and handmade-AST behavior

The [new probes](../../spec_root_scope_test.mbt) independently construct source
and typed AST programs, with literal expected arrays and callback roles.
Neither a parser-export round trip nor another implementation provides them.

| Required clause in the selected group | Executed result |
| --- | --- |
| Root and nested self are distinct | Original inner f() returns [10,1]; deriving outer tag=20 changes its root result to [20,1] |
| Inner extension retains an inherited field's lexical root | Extending original/derived inner objects to tags 2/3 yields [10,2]/[20,3], rather than treating each new inner receiver as that field's root |
| A standalone right-hand object can introduce its own root | In the same extended inner object, newly defined localRoot=$.tag yields 3, while the inherited function still sees outer root 20 |
| Extraction and rehosting preserve roots | Saved and rehosted functions retain [20,3] despite holder tag=999; the original function remains [10,1] |
| Exact first oracle | RT1 returns [[10,1],[20,1],[10,2],[20,3],3,[20,3],[20,3],[10,1]] |
| Factory definition wins over dynamic placement | An outside-defined factory creates root 30, even from object fields. An inside-root factory's returned object tag=40 does not replace its captured outer root 10/20; its inner self is 5 |
| Saved factories and result functions retain context | RT2 returns [[30,4],[10,5],[30,4],[20,5],[30,4],[10,5]] |
| Root lookup does not borrow inner self | RT3 first reads inner needed=99, then actually demanded $.needed rejects Runtime for a missing or explicit-error root field; the explicit root-marker remains intact |
| Demand is deferred | RT3 metadata/unused-call modes return the explicit function/42 values with zero body events. Only actual invocation enters once before the root failure |
| Call-site objects cannot authorize a free lexical $ | RT4's outside getter is rejected Static at Program creation, through source and handmade AST, even though its caller is an object with needed=99 |

Static versus Runtime, entry identity and the literal marker are embedding
phase controls. The inner-value guard and body event reject wrong routes
without imposing arbitrary error ordering or general diagnostic formatting.
No malformed-source Syntax counterpart is claimed for typed ASTs.

Existing O2 supplies scalar root/self inheritance controls; C6 supplies a
source/exported-AST comprehension root control. C6 is now explicitly reused
under DESUGAR-ROOT, without a new comprehension campaign. Existing SR/SP
receiver/prefix mappings remain unchanged. Their old executions are not
rerun, added to this batch, or treated as new independent handmade ASTs.

## Dataflow supporting the bounded acceptance

objects.mbt creates each field scope from that field's captured environment.
It binds self to the full current receiver, but introduces $ only if lookup
finds no existing root binding. Nested fields therefore keep the outer root
while receiving their own self. An inherited outer field can establish its
root from the derived outer receiver, whereas an already selected nested
field retains the captured outer object when that nested object is extended.

Layer descriptions preserve their defining environments. This also explains
RT1's different roots within one composite inner object: inherited f retains
root 20; the standalone right-hand localRoot field starts without an outer
root and binds $ to the composite receiver with tag=3.

Function values capture their definition environment, and call_env builds
from that outer environment rather than the caller's object scope. A global
factory's returned object thus starts a new root; an inside-root factory
keeps the captured root, including after factory/result-function extraction.
AST conversion preserves Var("$"). Static checking permits it under object
scope and rejects the outside getter before any invocation. Debug scope
projection preserves the semantic environment rather than supplying a new
root from the caller.

These inspected paths support the selected ordinary-field/factory contract
beyond merely counting array members or tests. They are an engineering
review, not a machine-checked proof of all syntax, binders or object shapes.
No product defect was observed within the bounded group, and no product
implementation change was needed.

## Execution identity and final checks

Base source: ff3e77c82e45131c837909c4cc6acb2a78614e70, tree
9a60b199635a8813860e4c4c428bd6d245cd33c5, plus the new test identified below.
The pre-run manifest pins criteria, exact test bytes and inspected/reused
sources; those bytes remain unchanged after formatting and matrix work.
Existing Darwin arm64 tools: moon/moonrun 0.1.20260920 (914d7da),
moonc v0.10.14+7d59c7ec9. All fixtures are self-made with virtual callbacks,
without imported-file, private-document or network I/O.

One focused native debug invocation passed **4/4, exit 0**, on its first run:

```sh
nice -n 10 env RUST_LOG=error moon test spec_root_scope_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize
```

No second semantic run followed mapping/documentation edits. Reused or older
aggregate/platform results are not added to this count. Subsequent typecheck,
info/format and matrix commands ran sequentially with frozen dependencies and
reduced priority, one worker where supported. Installed info/fmt have no
worker-count option. No implementation, dependency or public interface changed.

The [matrix](SPEC-LANGUAGE-MATRIX.md) retains **8 completed named rules,
42 partial rows and 44 unreviewed rows**, with 70 named rules and 24 initial
prose/grammar rows. Only evidence/remaining-scope text for object-index,
object-inherit, DESUGAR-ROOT and SUBSTITUTION changes; all row completion
states are unchanged. RT3 is a later root-field lookup failure, not an error
of desugaring or object addition. Public stdlib remains 35/153 partial
reviews; whole-language acceptance and inferred execution remain false.

| Final check | Result |
| --- | --- |
| Root native check | Exit 0 with --frozen --deny-warn -j 1 |
| Root info then fmt; script fmt --check | All exited 0; no .mbti changes |
| Matrix regeneration | Exit 0; assertion locations and source hashes validated |
| Tracked/staged-only documentation checker | Exit 0; 149 files and 1122 local/current-source links passed |
| Whitespace and exact file scope | Working/staged diffs pass git diff --check; exactly seven scoped files, with no existing implementation/interface changes |

| Retained artifact / inspected source | SHA-256 |
| --- | --- |
| Pre-execution criteria | 45a79170fc8154771df7616ffa50b68a76b24fcc953e201eb7a9fef6de795e88 |
| Executed test file | 6f43b1017c33c74f6207911312193df725bf06d59d09d7464546a0a16cb461d5 |
| Passing 4/4 summary log | 68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499 |
| objects.mbt | 06fe3700af7171f9b67a9641a35c92d541849409bcd009e34428ee0456079436 |
| eval.mbt | f75c9e3fd45506a140711eaf21c09625dfa9879798ccc1ac40adc1f2983f55c3 |
| validate.mbt | 88fec7025eb865c2f5c4563ae7647d3269850673959018985e7b7af1892c7cb4 |
| ast_convert.mbt | bd3fbff39ccdfc2d177d41435d7a33e96014ae206697c902be69ec2b11d5beed |

Raw evidence: /tmp/moonjsonnet-root-scope.pyejSV. Temporary files are not an
archival delivery guarantee. Committed tests, criteria and the
[machine-readable matrix](spec-language-matrix.json) retain actual oracles
and source-bound scope. Counts/summary hashes alone are not source identity
or conformance; the retained input/command records bind this result.

Other root/key/local/comprehension/default combinations, super/additive/hidden
fields, object assertions, complete inheritance/substitution/closure laws,
GC/reentry, host metadata, resource limits, trace and CLI behavior remain open.
[Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays separate and
unknown for these cases; older macOS/Linux evidence retains its own source
identity. No full suite, release build, remote run, additional-platform
verification, dependency installation, push or tag occurred.
