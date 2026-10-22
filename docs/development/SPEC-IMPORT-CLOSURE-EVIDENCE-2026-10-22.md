# Code-import closures: isolation and deferred dependency evidence

**Decision: the predefined exported-factory closure/import-scope contract is
reviewed complete within its stated bounds.** Caller locals and object/root
contexts do not replace module definitions; explicit arguments still cross the
call boundary normally. Nested dependency failures wait for actual default
demand. This is the [pre-execution contract](SPEC-IMPORT-CLOSURE-REVIEW.md),
not completion of CORE-IMPORT, substitution or any whole child judgment.

## Fixed oracle and reused evidence

The [official specification](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
at bbb38f1020be1f5aed560928fb839b2c448cefb4 requires code imports to be
parsed/desugared/statically checked in isolation, loaded lazily and unaffected
by their importing environment (911-925). Its local/apply/substitution rules
and the [language Function section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
supply lexical binding, lazy actual arguments and definition-scope defaults.
No implementation output or Go/C++ run supplies an expected value.

Existing [I1-I3](../../spec_import_scope_test.mbt) already cover direct free-name
rejection, unused imports, separate imported Syntax/Static errors and a valid
module-local binding. They are reused without rerun or additional passing
counts. [F1/F2](../../spec_language_function_test.mbt) supply the previously
reviewed function/default children; [RT1/RT2](../../spec_root_scope_test.mbt)
supply scoped lexical self/root behavior. This batch adds an import boundary
and returned closure around those children, rather than reopening general
function or object-inheritance contracts.

## Actual source-entry and handmade-entry outcomes

The [new tests](../../spec_import_closure_test.mbt) use synthetic memory
modules only. Entry trees are built separately with ImportFile, Local, Call
and Obj constructors, using neutral root_* builders. No parser export creates
those trees. The resolver supplies fixed Source.text modules on both entry
paths; those modules are parsed by the import path, **not independent module
ASTs**. Source.id and resolver from/path checks are explicit virtual embedding
controls, not general filesystem/canonicalization requirements.

The module defines local x=10, root x=11 and nested x=12. Its nested make
function defaults seed to dep.a, captures saved=x+seed, and returns a function
defaulting arg to dep.b. Its result is [x,seed,saved,arg,self.x,$.x]. The normal
dependency has a=2,b=3 and an unused erroneous field. The caller instead has
local x=900, a colliding dep=90/91 and an object with x=700.

| Probe | Actual result through both entry paths |
| --- | --- |
| IC1: default call | [10,2,12,3,12,11] |
| IC1: same closure under caller x=800,dep=80/81 | [10,2,12,3,12,11]; the saved environment is retained |
| IC1: caller x/self.x passed explicitly | [10,900,910,700,12,11]; explicit arguments are evaluated in the caller context |
| IC1: caller $.x passed as seed | [10,700,710,3,12,11]; passing root data does not rebind module root |
| IC1: dependency origin | The nested request carries closure-module.libsonnet, even though the returned function runs in the entry caller |
| IC2: valid caller context | [777,100,99,100] for caller/self.x/super.x/$.x |
| IC2: imported function body references caller, self.x, super.x or $.x | Static in closure-module.libsonnet while only inspecting its type; no function call is needed |
| IC3: factory or returned-closure type | function, without loading the malformed/static-invalid/runtime-failing dependency |
| IC3: explicit seed=5,arg=7 | [10,5,15,7,12,11], without loading that dependency |
| IC3: defaults demanded | The dependency's Syntax, Static or Runtime failure appears in closure-dep.libsonnet; the Runtime marker is dep-default-required |

The Static dependency has an unused function referencing free x: neither the
intermediate module's x=10 nor the entry caller's x can satisfy it. This is
independent checking of the nested imported file, beyond I1's direct free x.
The normal unused dep field remains unforced. Every entry Program is created
successfully before its resolver is used; imported compilation errors occur
during evaluation only when the relevant import is demanded.

Request maps collapse repeated pairs. They require only the fixture's necessary
module/dependency identities or absence of a dependency request, not cache
callback multiplicity, lifetime or unrelated order. Each failure fixture has
one demanded problem. Error kind, source identity and literal Runtime marker
are embedding phase controls; the specification does not standardize diagnostic
presentation. Source-level Syntax is not asserted for a malformed typed AST.

## Dataflow review

imports.mbt loads the supplied source, then parser.mbt parses it and validates
with only the initial std name and no enclosing-object context. Caller local,
self, super or root names are therefore not an imported static scope. The
import thunk stores the expression in base_env(file=source.id); that environment
has no caller parent, contains the standard bindings and retains its own import
origin. This is the relevant isolation boundary, independent of native host
resolver policy.

eval.mbt stores Func as Closure(params,body,env). Calls construct their child
environment from that definition environment. Explicit actuals are thunks from
the caller, while missing defaults are pending expressions in the callee's
scope. The local saved binding is also lazy. Returning or type-inspecting the
inner closure consequently need not evaluate seed, saved or the nested dep
import; explicit seed/arg overrides avoid those defaults entirely. Once needed,
dep still resolves using the captured module origin and receives its own
isolated parsing/base environment.

The module's field environments supply its own nested self and lexical root;
entry object contexts cannot overwrite those saved environments. These are the
previously scoped self/root children, observed across this new import boundary.
AST conversion preserves ImportFile, functions, bindings and calls without
inlining code into the importing AST scope. Tests and these constructor paths
support the bounded result without a product fix or a claim that every child
evaluation/substitution rule is complete.

## Execution identity and checks

Base commit: 306f89a316679c4b0c8b81799b14a2d4e349fb89, tree
1858b4ef73de1d32bd184182803b30dc84b5419d. Raw records are in
/tmp/moonjsonnet-import-closure.70yzcze2. baseline.json and before-run.json pin
the clean starting tree, inspected implementation, reused controls/builders,
fixed sources, criteria and executed test. Pre-execution copies preserve both
new inputs. No expected result or tested byte changed after execution.

One directed native debug invocation passed **3/3, exit 0**, on its first run:

    nice -n 10 env RUST_LOG=error moon test spec_import_closure_test.mbt --target native --frozen --deny-warn -j 1 --no-parallelize

Only IC1-IC3 executed. Their source/AST/default variants are not additional
completed judgments. Limits were steps=20000, depth=64 and stack=96, including
standard-library setup for the two virtual modules. No additional semantic
run was needed because product and shared test code were unchanged. Measured
tools were moon/moonrun 0.1.20260920 (914d7da), moonc v0.10.14+7d59c7ec9
on Darwin arm64.

| Subsequent check | Result |
| --- | --- |
| Native root type check | Exit 0 with --frozen --deny-warn -j 1 |
| Info then fmt; script fmt --check | All exited 0; tested bytes and public .mbti files unchanged |
| Matrix validation/regeneration | First invocation exited 0; source hashes, assertion anchors and existing completion records validated |
| Tracked/staged-only documentation checker | Exit 0: 166 files and 1231 local/current-source links; root layout, language candidates, README parity and migration targets passed |
| Whitespace and exact file scope | Staged/worktree diff checks passed; exactly the seven intended test, criteria, evidence and matrix files |

Checks were sequential, reduced priority and one worker where supported;
installed info/fmt expose no worker-count option. One earlier exec creation
attempt failed before a process existed. A successful read-only clean/HEAD
check preceded the actual baseline write; no uncertain mutation was repeated.
The test and subsequent checks were each awaited to process completion.
Fixtures cannot launch background work: the resolver only returns synthetic
strings and records request membership. No private/imported disk file, network,
full suite, remote/browser/CLI run, installation, push or tag was involved.
Standard/default was retained.

## Matrix boundary, remaining work and next candidate

Only CORE-IMPORT and SUBSTITUTION receive scoped IC mappings. Every one of
the 94 [matrix](SPEC-LANGUAGE-MATRIX.md) inventory IDs, states and completion
records remains unchanged: **10 completed named reviews, 1 constructor transfer
relative to children, 57 partial rows and 26 unreviewed rows**. There is no new
named-rule or generic relative-constructor completion record. Public-library
completion counts, whole-language acceptance and inferred execution do not
change. [Go/C++ comparison](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) stays
separate and unknown for these new probes.

This exported-closure/isolation and deferred-dependency group is closed.
General code-import source/decoding forms, BOM interpretation, canonical
aliases, cycles, cross-mode/source/value/failure cache identities and lifetimes,
host resolver/I/O/ext/TLA policy and resource contracts remain outside it.
The broader import/substitution rows stay partial. B0/N0/R0 remain unchanged
and are not exercised by these assertion-free fixture paths.

A distinct next candidate is the still-unreviewed array-concat structural and
element-laziness contract, first mapping existing array immutability evidence.
That work has not been started here.

| Identity | SHA-256 |
| --- | --- |
| Pre-execution criteria | 318bd3bc2e4c558780d60d18bdf235fe8e65a7c0990846921eeb2e30f0cdfb7a |
| Executed new test | e8136fdc0bb06add93a8589d9409b3b579aaa653077d0700fe4fcf244c02da58 |
| Neutral root helpers / existing RT tests | 6f43b1017c33c74f6207911312193df725bf06d59d09d7464546a0a16cb461d5 |
| Reused I1-I3 source | a267fed917387b8edf62b4d1b72ed7764680cd14b919ced2af7f298847a9d2ed |
| Passing summary log | 97372d6d024ba8fb9a214e3a9a3495ca88a0631086280e8b2271682e11ea6fb0 |
| imports.mbt | df4728b32aa8f9e01feb96e12ff690edd61be224cbb369e34498d5d8ebb52b56 |

Temporary evidence is not an archival guarantee. Committed criteria/tests and
the [machine-readable matrix](spec-language-matrix.json) preserve the scope
and independent oracle; equal summary hashes alone do not identify executed
source. Product code, dependencies, prior tests and public interfaces are
unchanged.
