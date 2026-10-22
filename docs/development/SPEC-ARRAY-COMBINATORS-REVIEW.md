# Array combinators and unresolved boundary adjudication

Normative sources remain Google Jsonnet commit
bbb38f1020be1f5aed560928fb839b2c448cefb4:
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html),
[language](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md),
[public functions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html),
and [source definitions](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet).
This expectation review precedes the new executable regressions. Existing finite,
index and slice-timing checks are regression protection, not newly earned coverage.
All new inputs are synthetic and contain no business data.

## Boundary investigation outcome

Valid array cardinality is a nonnegative integer: the value grammar contains zero
or more elements and length is a count. The makeArray rule writes the result as
f(0) through f(n-1), but supplies neither an explicit n-in-N premise nor an
invalid-size conversion/error rule. The documentation promises sz elements;
range delegates to makeArray(to-from+1,...). Cross-checking these sources does
not uniquely specify what to do outside the successful cardinality domain.

| Boundary | Candidate interpretations | Adjudication |
| --- | --- | --- |
| Negative makeArray size, hence a sufficiently descending range | Reject because no array can have that length; or interpret the indexed sequence as empty | Reject is the stronger count-preserving candidate, but no unique exceptional/normalization rule is established here; unresolved |
| Fractional makeArray size, hence a nonintegral range cardinality | Reject because the length is not integral; or convert the count before generation | Rejection is the stronger literal-count candidate; conversion details are not specified; unresolved |
| Nonboolean filter result | Require a Boolean predicate as a filtering condition; or retain only literal true and discard other returned values | The formal set selects true results without an explicit Boolean-result premise, and the prose does not add one; unresolved |

The filter relation is not an explicit desugaring into an if expression. Applying
the language's Boolean-only conditional rule to it would be an additional
interpretation. Conversely, reading every failure to derive true as false would
also conceal demanded callback errors. These omissions require clarification;
they are not settled by matching Go or C++. The
[observation inputs](../../tests/spec-array-boundary-observations.json) have no
expected outputs or passing status. Observed empty/error behavior is not a new
normative regression criterion. No boundary implementation change is proposed.

## Five-function expectations locked for this batch

All public arguments are required; no signature has optional defaults. In slice,
explicit null values select the default bounds/step, while omitted arguments are
binding failures. Names follow documented/source signatures, without aliases.

| Function | Normal/type/boundary expectation | Callback order and lazy/immutable expectation |
| --- | --- | --- |
| makeArray(sz,func) | Nonnegative integral size, zero and named calls; function-valued callback required even at zero; nonnumeric size/invalid function fail | Construction/length does not call the body; demanded integer indices initialize independent cached thunks; callback defaults are overridden by supplied indices |
| foldl(func,arr,init) | Left association, named calls, arrays and codepoint strings; required arguments; nonempty bad callback and primitive bad sequence fail | Empty sequence returns init without using func; first callback may ignore init; each intermediate callback result is forced because source recursion is tailstrict; input/init arrays unchanged |
| foldr(func,arr,init) | Right association and right-to-left traversal with element before accumulator; same supported sequence/binding boundaries | Same empty/initial-thunk rule; strict intermediate heads, lazy nested payloads and unchanged input/init |
| flatMap(func,arr) | Array callback returns arrays, string callback returns strings, with empty/Unicode cases; numeric wrong returns fail in both doc/source paths | Validate function before using arr; callback result heads are required to flatten structure, payloads may remain lazy; callbacks traverse in order and input remains unchanged |
| slice(indexable,index,end,step) | Documented named calls, explicit-null defaults, negative/large bounds, positive steps and Unicode; zero/negative/type-invalid step fails | Source validation order retained even on empty input; selected array payloads stay shared/lazy, original array unchanged; strings remain strict |

The source folds pass init lazily into the first callback. tailstrict applies to
the recursive helper's new accumulator, not to the original init before that
callback. This distinction is the independent criterion; old strict-Go assertions
cannot override it. The native implementation may remain iterative for supported
array/string inputs if it preserves those forcing rules.

Unresolved scope stays separate: makeArray callback declaration-count wording,
negative/fractional cardinality behavior, mechanically source-defined fold results
on empty objects/functions versus the advertised sequence domain, and flatMap's
null/string callback results outside the documented return-kind constraints.
None earns acceptance from an existing Go-style error or success. removeAt naming
and earlier public-source conflicts are unchanged.

The [execution evidence](SPEC-ARRAY-COMBINATORS-EVIDENCE-2026-10-22.md) retains
baseline failures, the test-construction correction, fixes and source-bound
validation. Observations and normative assertions remain separate.
