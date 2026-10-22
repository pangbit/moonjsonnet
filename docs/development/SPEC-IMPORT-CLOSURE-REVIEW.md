# Code-import closure isolation: pre-execution criteria

Base source: 306f89a316679c4b0c8b81799b14a2d4e349fb89. Fixed official Jsonnet:
bbb38f1020be1f5aed560928fb839b2c448cefb4. Cached spec.html SHA-256:
bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a;
language.md SHA-256:
c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be.
These sources and literal outputs precede execution. Implementation output
and Go/C++ behavior do not determine the oracle.

## Fixed contract and reused children

The [fixed Core Syntax import prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
(911-925) requires imported code to be parsed/desugared/statically checked in
isolation, loaded lazily during execution, and unaffected by the environment
into which it is imported. The existing local/apply/substitution rules supply
ordinary lexical closure and lazy default behavior. The
[language Function section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md)
(144-195) supplies lazy arguments and definition-scope defaults.

I1 already rejects a directly imported free x despite a caller local. I2
already skips unused local/branch/argument/default/hidden/array imports. I3
already separates demanded imported Syntax/Static failures from entry creation
and accepts a module's own local x. Reuse those meanings without rerunning
their groups. F1/F2 supply definition/caller/default children; RT1/RT2 supply
the scoped lexical self/root children. This batch adds an import boundary
around a returned factory closure, not another general object/root campaign.

## Synthetic module and independently fixed output

The only modules are memory strings. closure-module.libsonnet defines:

    local x=10,dep=import 'dep';
    {x:11,nested:{x:12,make:function(seed=dep.a)
      local saved=x+seed;
      function(arg=dep.b)[x,seed,saved,arg,self.x,$.x]}}

The normal dependency is {a:2,b:3,dormant:error 'dep-unused'}. The importer has
x=900 and dep={a:90,b:91}, extracts make, saves its returned closure, and calls
it inside an object with x=700. A further caller local shadows x with 800 and
dep with 80/81. Imported module-local x, nested self and root must remain
10/12/11; explicit caller arguments are still passed normally.

| Probe | Required source-entry and independent handmade-entry result |
| --- | --- |
| IC1: default call and call under further caller locals | Both yield [10,2,12,3,12,11]. |
| IC1: explicit caller x and self.x arguments | [10,900,910,700,12,11]. Isolation does not block explicit argument passing. |
| IC1: explicit caller $.x seed, module default arg | [10,700,710,3,12,11]. Caller root can be passed as data without rebinding module root. |
| IC2: caller namespaces are valid in their own context | A caller local and inherited object give [777,100,99,100] for caller/self.x/super.x/$.x. |
| IC2: invalid imported function body | function() caller, function() self.x, function() super.x and function() $.x reject Static in the imported module, even though the caller context provides those namespaces and only asks for the function's type. |
| IC3: deferred dependency | Inspecting the factory or returned closure's type gives function without loading dep. Explicit seed=5,arg=7 returns [10,5,15,7,12,11] without loading dep, even if dep would fail. |
| IC3: actual default demand | Calling the returned closure with defaults loads dep and exposes its own Syntax, Static or Runtime error. The Runtime marker is dep-default-required. |

The failing dependencies are function( for Syntax; an unused function
referencing free x for Static; and {a:error 'dep-default-required',b:3} for
Runtime. Even the intermediate module's x=10 cannot satisfy a free name in a
separately imported dependency. No fixture has competing demanded errors.

Entry source and typed ImportFile/Local/Call/Obj trees are constructed separately
with neutral root_* builders. Imported modules use Source.text on both paths
because the resolver API supplies code text; they are parsed by the import
path, not claimed independent module ASTs. Source.id and resolver from/path
membership are explicit virtual host-protocol controls. Request maps collapse
repetitions and impose no universal cache callback count or unrelated order.
No filesystem path/canonicalization policy is derived from these identities.

## Inspection and stopping point

Inspect isolated parsing, parent-free module environments, stored import origin,
closure definition environments, pending defaults/locals and child AST/static
preservation. Accept this bounded exported-closure/import-scope and deferred
dependency contract only if results and dataflow agree. Keep CORE-IMPORT and
general substitution partial; no named or relative-constructor completion is
added. Canonical aliases, cycles, cross-mode/source/value/failure cache identity
and lifetimes, byte decoding/BOM, host I/O policy and resource contracts remain
separate. B0/N0/R0 are unchanged and not on these assertion-free paths.

Every evaluation is bounded by steps=20000, depth=64 and stack=96; the larger
step allowance includes standard-library setup for the two imported virtual
modules. All graphs and fixture inputs are finite. One worker, reduced
priority, frozen dependencies and directed native debug only. No other user
files, network, full suite, remote/browser/CLI run, installation, push or tag.
