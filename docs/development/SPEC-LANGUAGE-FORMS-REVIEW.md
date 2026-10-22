# Recursive bindings and comprehensions: pre-probe oracle

Starting source: `5e757b4`. This batch selects two previously unreviewed named
rules, `chk-local` and `object-comp`, from the 53-row unreviewed inventory.
It also tests adjacent comprehension desugaring/scope dimensions without
granting complete acceptance to those rows.

The independent basis is the fixed Google Jsonnet commit
`bbb38f1020be1f5aed560928fb839b2c448cefb4`:
[specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html)
(`chk-local`, `chk-object-comp`, object/array comprehension desugaring,
`object-comp`, substitution and `object-inherit`) and
[language reference](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
(lexical scope, lazy arrays, comprehension nesting/shadowing and inheritance).
Retained source SHA-256 values remain
`bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a` and
`c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.
This oracle is written before the first new probe. No Go/C++ output is used.

## Existing evidence checked first

`ast_test.mbt` already rejects one top-level duplicate-binding AST and malformed
comprehension shapes. `moonjsonnet_test.mbt` has one recursive local function and
simple comprehensions. `language_test.mbt` has one comprehension with object
locals and final self. The earlier language tests cover function defaults and
ordinary object field-name scope. They do not establish the dimensions below;
none is counted as a new check merely by citing an existing test name.

## Locked expectations

| Selected obligation | Expected result or error phase |
| --- | --- |
| Whole local group is recursively in scope | `local a=b,b=42;a` gives 42; mutually recursive even/odd functions give the explicitly asserted booleans |
| Nested local groups shadow without caller/sibling leakage | Valid shadowed values give exact JSON; an initializer using a variable confined to a sibling nested local is Static before evaluation |
| Binding names within one group are unique | Duplicate local variable/function names, ordinary object locals and comprehension locals reject statically, including unused branches and empty domains |
| Local initialization is lazy and cached | Ignored error/recursive bindings produce 42; repeated aliases share one demanded native result, unused initializers run zero callbacks |
| Object-local recursion retains late self and lexical super | Extending a layer with mutually recursive local aliases recomputes the appropriate object result while the original remains unchanged |
| Comprehension generators use sequential lexical scope | Later domains can use earlier variables; repeated generator names shadow; the first domain uses the enclosing binding; later variables do not leak backward/outside |
| Cartesian order and lazy body values | Nested generator output order is explicit; false filters skip later domains/body; length and unselected elements do not force body payloads |
| Object comprehension key and body have different scope | Keys can use loop variables and enclosing self, but cannot capture new object locals/self; body object locals can use loop variables and final self/super |
| Object names are constructed before shape inspection succeeds | Demanded erroneous/nonstring keys and duplicate non-null keys fail even under std.type; null names may repeat and suppress their bodies |
| Static and runtime duplicate keys differ | Ordinary literal duplicate fields are Static; dynamically equal computed keys and duplicate comprehension results are Runtime after successful parsing |
| Explicit empty/null/filter boundaries stay lazy | Empty domains do not demand keys/body, null keys skip body evaluation, false filters skip later erroneous domains; native counters verify demand and sharing |
| Demanded invalid filters and numeric domains fail | A nonboolean comprehension condition or numeric generator domain fails at evaluation; an earlier false filter prevents the latter from being evaluated |

The numeric-domain negative uses a number, whose required sequence operations
cannot succeed. This batch does not adjudicate mechanical string/object/function
domain extensions of array-comprehension desugaring. It does not choose an error
order between unrelated failing keys or fields, or a particular resource error
for a demanded divergent binding. These remain unreviewed.

## Separate entry paths and observations

Valid and runtime-error source cases are checked through source parsing and a
validated exported-AST round trip. That round trip is not a replacement for
handmade invalid ASTs: separate tests construct duplicate local groups, invalid
comprehension scope and dynamic duplicate/null-key ASTs without parsing source.
Static cases fail Program creation; runtime Type/Runtime categories are asserted
only after creation succeeds. Native counters measure required nonexecution and
reuse rather than relying on a successful final value alone.

The CLI corpus separately executes source text and checks exact JSON or exit 1,
empty stdout and the expected static/runtime diagnostic class. CLI rendering
does not expose the finer library Type category; it is recorded from independent
library assertions, not inferred from a message substring. Existing tool API
and error wording remain unchanged. Single-worker focused native checks are the
default; there is no new remote, full multi-platform or upstream campaign.
