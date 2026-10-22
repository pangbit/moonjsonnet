# Array ordering: pre-execution criteria

Base source: 27ddda4daaed67ede29779efed49b5fd6e79c448. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These clauses and literal expectations precede execution. Go/C++ behavior and
the implementation do not determine the oracle.

## Why this group

All five cmp-array rules are unreviewed in the 94-row language matrix. The
existing language syntax test supplies one nested-array less-than example;
array_std_test supplies ordinary internal comparison-helper results and broad
error controls. Those are retained controls, not independent coverage of
empty/prefix/recursive demand boundaries, and will not be rerun or counted as
new results. Earlier array laziness and numeric-library evidence keeps its
original scope.

## Fixed clauses and independent outcomes

The [fixed specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#execution)
at 2448-2510 defines the five array cases: empty/empty gives 0, only the left
empty gives -1, only the right empty gives 1, unequal first elements decide
without a tail premise, and equal first elements recurse on the tails.
The less-than rules at 2360-2378 and less-or-equal rules at 2404-2420 turn that
sign into booleans. The number/string children at 2514-2538 and numeric prose
at 2796-2804 supply ordinary number order and Unicode-codepoint string order.
The [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
at 202-222 independently states array-element laziness and lexicographic
ordering, including a shorter equal prefix.

Observe signs through the language operators < and <=, without assuming that
the specification's std.cmp notation is a registered public function. For sign
-1, 0 and 1 the explicit expected (<, <=) pairs are respectively (true,true),
(false,true) and (false,false). Other relational operators are outside this
group; no conclusion about their printed rules is inferred.

| Probe | Required source and independent handmade-AST outcomes |
| --- | --- |
| AO1: structural cases | Empty/empty is equal. Empty versus a nonempty error-valued array decides by shape in either direction. A shorter equal prefix decides without forcing the unmatched element. First differences decide in both directions, with error-valued tails unforced. Equal finite nested arrays compare equal. |
| AO1: recursive boundaries | A nested first difference skips both inner and outer tails. A nested equal prefix allows the next outer element to decide. Nested empty versus nonempty skips the latter's payload. U+E000 sorts before U+1F600, with later values unforced. |
| AO2: necessary prefix only | A finite nested comparison records only L0/R0, LN0/RN0 and LN1/RN1. Distinct LT/RT tail callbacks remain absent. An unused binding containing the same comparison returns 42 without any callbacks. Membership maps impose no left/right callback order or universal invocation count. |
| AO3: demanded failures | Explicit errors in a required head, after an equal prefix, or inside a required nested prefix propagate as Runtime with their fixed literal markers. Noncomparable boolean/null elements, mixed number/string or number/array elements and non-array outer partners fail Type. The same expressions stay lazy in an unused binding. |
| AO3: static boundary | Unknown names in either potentially skipped array tail or either binary operand reject Static at Program creation, including under an unused local binding. Runtime laziness cannot excuse an invalid scope. |

Typed trees are built separately with Array/Binary/Local/Fail/Call constructors;
none comes from parsing or exporting source. Shared fixture literals and
neutral builders do not compute expected comparison results. Type/Runtime,
virtual entry identity and explicit marker text are embedding phase controls;
the normative distinction is successful evaluation versus stuck execution.
No malformed-source Syntax equivalence is claimed for typed trees.

## Scope and stopping point

Inspect the two container heads, common-prefix recursion, empty/length cases,
first-difference return, thunk forcing, and source/AST static traversal. Accept
only this finite array-ordering group if outcomes agree with these criteria.
No full number/string/operator judgment or generic constructor completion is
inferred. No sorting/equality/public-helper contract is added. Cycles, resource
policies and arbitrary order among independent errors remain outside scope.
N0/R0 assertion questions are not on these assertion-free paths and are not
reopened.

Each evaluation is bounded by steps=5000, depth=48 and stack=64; arrays have at
most three elements and finite nesting. Use one worker at reduced priority,
existing frozen dependencies and directed native debug checks. No full suite,
remote/browser/CLI run, dependency installation, push, tag, imported/private
file or network I/O is included.
