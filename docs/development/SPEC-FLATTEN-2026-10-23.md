# Public shallow and deep flattening contracts

## Frozen definitions and independent obligations

Base 584d99fce87a93eb5a28a5fd8f196bd3c3d2370a. This batch reviews two
previously unmapped public functions, flattenArrays and flattenDeepArray,
using the existing manual map and inventory. Existing array_std_test examples
are candidate evidence only; their historical execution is not a current run.
The reviewed flatMap/fold/join subsets are retained without duplicate review.

The fixed official commit is bbb38f1020be1f5aed560928fb839b2c448cefb4.
The [source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L889-L896)
and [public declarations](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#std-flattenArrays)
(stdlib.html 2488-2536) establish different operations:

- flattenArrays folds addition over an outer collection with initial [].
  Its advertised Array-of-Arrays domain concatenates exactly one level,
  preserving order, nested arrays and arbitrary inner payloads. The
  [foldl definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L823-L829)
  requires each accumulator head, so all outer member heads must be obtained;
  their array payloads remain lazy. Unlike join, a null outer member is not
  skipped: adding Array and Null is unsupported.
- flattenDeepArray recursively classifies Array values and wraps every
  non-Array value in [value]. Nested empty arrays disappear; null, Boolean,
  Number, String, Object and Function leaves remain. Object fields are not
  recursively flattened. Scalar-root singleton behavior is an explicit
  source obligation; the public prose primarily describes an Array input.
  Constructing the complete result structure requires every recursive leaf
  head even when observing only length or the first result element. Object
  fields and function defaults/bodies remain unrequired at that point.

The fixed [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
requires immutable values (93), lazy arguments (154), lazy array elements
(203), and explains array comprehension traversal/desugaring (201-286).
These and the public definitions establish order and demand independently
of reference-interpreter output. A0's printed concatenation conflict remains
unresolved; this review does not promote that formal transfer rule.

The flattenArrays parameter is arr in the documentation and arrs in source.
Named success and alias policy remain unadjudicated; no alias is added.
Its source has no outer Array guard and String addition can coerce values.
String/Object/Function outer inputs and String members are excluded rather
than treated as universal Type errors. The error subset covers primitive
Null/Boolean/Number roots whose length is unsupported and clearly unsupported
Array additions with Null/Boolean/Number/Object/Function members.
flattenDeepArray has no rejected non-Array value kind: source wraps all such
heads. Its error subset is demanded errors and invalid call bindings, not an
invented Array-only restriction.

| Group | Independent expected assertions |
| --- | --- |
| FL1 | Shallow empty/singleton/empty-member inputs, ordered one-level concatenation, retained null/Boolean/String/Object/nested Array payloads. |
| FL2 | Deep nested empties, ordered leaves, null preservation, atomic Object payloads, source-defined scalar roots and named value calls. |
| FL3 | Shallow unambiguous domain errors, opaque rejected payloads, required outer heads even for length/early selection. |
| FL4 | Shallow retained payloads stay lazy until selected or manifested; Array/Object/Function head observation avoids their contents. |
| FL5 | Deep recursive leaf heads are required for result structure; Object fields and Function defaults/body stay lazy until separately demanded. |
| FL6 | Original nested/top-level arrays and aliases retain literal data before/after cold/warm result reads; repeated calls agree. |
| FL7 | Native gates prove demanded original heads and retained leaves are shared once across repeat selection, aliases and a second flatten call; unused calls run no gates. |
| FL8 | Missing/extra/unambiguously unknown bindings reject before argument gates; unused calls remain lazy and free names still fail statically. |

Source strings and typed ASTs are built independently with existing neutral
builders; expected JSON values are literal data. FL groups are report labels,
not new canonical language IDs. Native counters and Type/Runtime/Static names
describe the embedding checks, not official error wording or a general
callback/error ordering requirement. Object assertions, inheritance/self,
root/std rebinding, Function equality/PE0, exhaustive host encoding/resource
limits and competing errors remain outside the subset. DF0/HP0, BOM/surrogate,
out-of-range conversions, language print conflicts and shift exclusions retain
their prior status. Neither function receives whole-contract acceptance.

Freeze criteria, formatted tests and mapping before semantic execution.
Use native debug with --frozen --deny-warn -j 1 --no-parallelize. Retain real
failures before any product fix; reuse valid old evidence and run only necessary
neighbors if a fix changes product code. Full suite, Linux, release and Go/C++
comparison are NOTRUN unless independently executed and recorded here.

<!-- Criteria above are frozen before execution; append results below. -->

## Execution and bounded result

The first semantic execution passed all eight groups, including separate source
and handmade AST evaluation in each group. It used native debug on Darwin
arm64, Moon 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9, --frozen,
--deny-warn, -j 1 and --no-parallelize. No product defect was exposed by this
subset and no implementation change was made. Existing tests and reference
fixtures are unchanged. Neighboring tests were not rerun because no product
path changed; prior join/prune results remain bound to their own reports.

The frozen, formatted test SHA-256 is
`032cbb5d0bb36e7b9b47da3e9eb7f2b4168efae399f1aa99d5628e134d63b2c5`.
Type checking, semantic execution and final formatting all retained these
bytes. An initial test command combined incompatible path and --file options;
the CLI rejected it before executing any tests. That exit-2 receipt is not a
product failure. The corrected file-path command is the sole semantic run
and returned exit 0, 8 passed, 0 failed. A temporary freeze-script type error
was corrected before the script executed; it also provides no semantic result.

Independent review found no blocking expectation issue. One post-run mapping
wording clarification separates recursive leaf errors required by length/early
selection from Object-field errors required by manifestation. The original
frozen mapping is retained; no input, expected value, test or frozen criterion
changed. The final map has 11 scoped declaration references across eight test
groups; shared groups explicitly identify the shallow/deep arm.

Both existing inventory generators passed. The public map adds exactly two
records while preserving the prior 50, yielding 52 records and 49 functions
with reviewed dimensions among 153 candidates. All whole-function statuses
remain unaccepted and behavioral_conformance_proven remains false. The
language map and regenerated JSON/Markdown are byte-identical to the base:
28 named transfers complete, one constructor relative to its children,
63 partial rows, two unreviewed rows and 195 canonical IDs. No inspection
snapshot or language evidence change is needed for this test-only batch.

Root check, info and formatting passed; generated public interfaces have no
diff. The final documentation validator and exact staged/committed readback
are recorded separately. The generated public inventory records the base
and pending test path at generation time, not a committed-clean execution.

Current full suite, Linux, release and Go/C++ comparisons are NOTRUN. The
historical full-suite numbers are not inherited. Existing unresolved
arr/arrs, String-domain, A0, DF0/HP0, PE0, object assertion, encoding/conversion
and resource boundaries remain open. After the resource-priority update,
only serial formatting, static metadata/documentation checks and local commit
verification were performed; successful checks were not repeated.

Frozen files, command intents, completed results and stdout/stderr digests
are retained in `/tmp/moonjsonnet-flatten.C8tRWs`. Owned commands are accounted
for by receipts. System process enumeration remains unavailable and is not
bypassed or reported as successful. No push, release, upstream edit or private
proposal material is included.
