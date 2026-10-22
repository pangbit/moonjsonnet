# Language expectations fixed before probes

This stage starts at `84e7e20` and uses Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
and [language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md).
The retained specification SHA-256 is
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`;
the reference SHA-256 is
`c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.
These expectations precede this stage's first new test execution. Go/C++ outputs
do not choose the expectations. All examples are synthetic.

## Selected gap 1: function binding, defaults and lexical scope

Basis: `chk-function`, `chk-apply`, `apply`, capture-avoiding substitution, and
the reference's Expressions / Function Parameters sections.

| Obligation | Independent expected result / rejection |
| --- | --- |
| Definition and caller environments differ | `local x=10,f(a=x,b=a)=[a,b]; local x=99; [f(),f(x)]` gives `[[10,10],[99,99]]` |
| Defaults bind all formal parameters | `(function(a=b,b=7)[a,b])()` gives `[7,7]`; supplying `b=9` gives `[9,9]` |
| Optional and required parameters may interleave | `(function(a=1,b,c=a+b)[a,b,c])(b=4)` gives `[1,4,5]` |
| Explicit arguments override defaults without forcing them | `(function(a=error 'default')a)(a=42)` gives `42` |
| Unused parameters, defaults and bodies stay lazy | Ignoring an error-valued argument/default or a recursive default gives `42`; an unused default's native callback runs zero times |
| One call shares each default thunk | A native default used repeatedly and through another default runs once; two calls run it twice |
| Binding errors precede supplied/default expressions and body | Missing, unknown, repeated positional/named and extra arguments are runtime errors with zero native calls |
| Invalid unused syntax is still statically checked | Undefined default/body variables and duplicate named arguments fail `Program::parse`; undefined defaults are rejected even when a later call supplies the parameter |
| Argument expressions use caller scope | A supplied argument mentioning an unavailable formal variable is a static error; formals do not leak into caller scope |

Required/optional ordering is explicitly permitted by the fixed reference;
`chk-function`'s grouped presentation does not override that statement. Exact
diagnostic wording is a tool contract. Tests distinguish parse/static rejection
from evaluation errors, and inspect native counters where successful output alone
would not prove laziness or caching. Diverging defaults are only exercised when
unused; no claim about a particular resource-error category is required.

## Selected gap 2: object scope, inheritance and manifestation

Basis: `chk-object`, `chk-object-comp`, object desugaring, `object-index`,
`object-inherit`, hidden-status inheritance, and `manifest-object`/`manifest-array`.

| Obligation | Independent expected result / rejection |
| --- | --- |
| Field-name scope is outside the object under construction | Top-level `{[self.key]:1}`, `{local k='x',[k]:1}` and `{[self.key]:x for x in [1]}` fail statically even in unused branches |
| A nested object's key can use the outer object's self | `{key:'x',nested:{[self.key]:self.key,key:'inner'}}.nested` gives `{"x":"inner","key":"inner"}` |
| Inherited self remains late bound; super selects lower layers | Deriving from `{x:1,y:self.x}` changes inherited `y` after overriding `x`; repeated access to the original retains `1` |
| Root and nested self bind separately | A nested object using `$` sees the outermost object; its `self` sees the nested object; extension rebinds inherited fields |
| Assertion uses the final derived self | An invalid base made valid by extension succeeds; a valid base made invalid by extension fails on selected field access and manifestation |
| Shape inspection does not check assertions | `std.type({assert false})` is `"object"`; array length, excluded hidden fields and ignored arguments do not force asserted objects |
| Field access and manifestation check assertions | Accessing a visible or hidden field of `{assert false,...}` fails; top-level/nested/array manifestation of assertion-only objects fails even without visible fields |
| Assertion messages and fields are separately lazy | A true assertion does not evaluate its error-valued message; a false assertion does not evaluate the requested field payload; count native demands |
| Visibility affects output, not direct access | All nine lower/upper visibility combinations follow hidden-status inheritance; hidden errors/functions remain unforced, forced-visible errors/functions fail on manifestation |
| Recursive JSON conversion rejects functions and demanded errors | Nested array/object functions and errors fail; hidden function fields are omitted without invocation |

This stage does not choose error precedence when more than one unrelated
assertion/field fails, and does not infer a rule for `std.manifestJson` from the
top-level manifestation rule. Equality/assertion interactions, exhaustive object
algebra, every lexical/desugaring rule, all import caching combinations and full
public-library acceptance remain open unless separately mapped and tested.

## Evidence policy

The language matrix records exact clauses, manually reviewed assertions and
uncovered dimensions. A matching test or function name proves no behavior.
`reviewed-subset` means only the stated executed cases; `unreviewed` and
`unresolved` never mean passing. Current-stage execution and Go/C++ compatibility
belong to separate reports. The private proposal and frozen Linux packet remain
unchanged; this stage runs no SSH or remote jobs.

The first run was 12/13: the method-default test mistakenly used `=` as its
method/body separator. Both inputs were syntax errors, so that run exercised
neither method-default expectation. The corrected inputs use `:` as required by
the field grammar. The original oracle, test sources and failed log remain in
the local stage evidence directory. No product fix follows from that failure.

Later steering released the separately approved frozen af188da Linux window
after the local language checkpoint. That isolated run and cleanup are recorded
in [their own report](SPEC-LINUX-AF188DA-EVIDENCE-2026-10-22.md); no newer language
source or changed oracle was inserted into the frozen packet. The initial
local-only scope statement above describes the scope before that steering.
