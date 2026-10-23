# Imported configuration validation: fixed four-group scope

Execution status: all four fixed groups completed through both entry paths;
the native debug baseline passed 4/4. No implementation defect or change was
needed. This batch is closed at its agreed stopping point. The criteria below
were written before execution; measured results follow them.

Base: `44c3d80c674a259c8bc38d15f275c890803bf53d`. The parent selected exactly
four composition groups from the existing coverage-gap review. Completion of
these four groups through both entry paths is the stopping point; no automatic
additional subgroup, whole-rule acceptance or implementation edit is implied.
The following expectations precede execution.

## Fixed authority and purpose

The official reference remains Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4` (v0.21.0), read from the retained
local sources. [Core Syntax import prose](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
at lines 911-925 requires lazy loading and isolated parsing/static checking of
imported code. Import behavior cannot borrow the importing environment.
chk-function at 1693-1703 checks defaults even without invocation. chk-object
and assertion desugaring at 1586-1595 and 1351-1363 check a message child even
when its condition is true. Imported failures therefore remain imported Static
errors reached during entry evaluation, rather than errors at entry creation.

The [language Function section](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/language.html.md#function)
at 144-195 supplies lazy arguments/defaults. Its Object inheritance section
supplies final-self lookup across layers. Existing I/IC, FS, OAS and
receiver/assertion reviews provide scoped child evidence; the new batch checks
their composition in a configuration-import boundary, not another independent
constructor completion.

Cached reference hashes:

- spec.html: `bbac3701ef0316fc29de6c543049ae8f0f78c876bdd94fbf6ab845b2023a720a`.
- language.md: `c55666af13894c8100c84fb053e647cd0ca516f3bb554d0ced29dfa83c3772be`.

No implementation output or Go/C++ behavior supplies an expected value.

## Actual interfaces and controlled imports

The two entry paths are exactly Program::parse(entry.source,
filename="ordering-entry") and Program::from_ast(entry.tree), selected by the
existing ordering_program helper. Every entry tree is constructed directly
from typed Local/Call/ImportFile/Obj/Index/Arr nodes and neutral literal builders;
neither a parsed nor an exported AST supplies it.

Both paths then call Program::evaluate with the same resolver interface and
explicit limits (steps 20000, depth 64, stack 96). Imported modules are
Source.text on **both** paths and are parsed by the import implementation.
This is not a claim of an independently supplied AST for each imported module,
nor of testing reusable Evaluator cache APIs.

The resolver accepts only four named paths from ordering-entry and the one
factory-to-bad-message dependency. It returns these fixed memory strings:

| Path / Source.id | Exact text |
| --- | --- |
| bad-default / memory/bad-default.libsonnet | `function(config=caller_default) 42` |
| bad-message / memory/bad-message.libsonnet | `{assert true:caller_message,value:42}` |
| factory / memory/factory.libsonnet | `function(config=import 'bad-message') config` |
| config / memory/config.libsonnet | `local policy=42;{assert policy==42,limit:1,value:self.limit,hidden::error 'unselected-field'}` |

The test opens no file and performs no network operation. Source.id values are
virtual identities, not filesystem paths to read. Unexpected requests fail the
fixture. A map records the unique (from,path) set; its finite membership/counts
are fixture protocol and absence-of-demand checks, not a universal resolver
callback order, retry or cache-lifetime theorem. No request is allowed during
entry creation. The fixture texts and identities receive individual input
hashes in the pre-run receipt in addition to the whole test-file hash.

## Independent expected outcomes

| ID | Finite scenario and required result for each entry path |
| --- | --- |
| IV1 | The caller binds caller_default=99 and observes the type of bad-default without calling it. Entry creation succeeds without requests; demanded import rejects Static at memory/bad-default.libsonnet. The unused default cannot capture the caller. |
| IV2 | The caller binds caller_message='caller' and observes only bad-message's type. Entry creation succeeds without requests; the import rejects Static at memory/bad-message.libsonnet even though its predicate is true and its message is never selected. |
| IV3 | Exactly four modes: unused bad-message import returns 42 without requests; factory type returns 'function' with no dependency request; explicit named config={limit:7} returns that literal object with no dependency request; factory() demands its default and rejects Static in memory/bad-message.libsonnet. The nested request origin is memory/factory.libsonnet. |
| IV4 | A caller policy=99 cannot replace the module's policy=42. Save base from config, derive base+{limit:2}, then read base.value, derived.value, base.value. The literal result is [1,2,1]; the hidden error remains unselected. |

Static tags and module filename identities are public host-phase checks, not
requirements on diagnostic wording. Each negative has one invalid identifier;
no precedence among independent errors is imposed. Both entries must complete
every listed loop; a first failure leaves later subcases NOTRUN. Four is the
planned native group count, not a passing result or eight separate tests.

IV4's assertion reads only module-local policy, not self/super or another
object field, so it does not require R0's missing in-progress checking-state
model. No assertion uses super, so it does not repair N0's omitted inherited
assertion-prefix transformation. Ordinary final-self field behavior follows
the fixed language guide and the existing bounded receiver review; DF0's
printed field-value discrepancy remains unadjudicated. There is no claim of
literal whole-field desugaring, full substitution or full object-inherit.
No std.manifestJson call or empty-object assertion expectation is introduced.

## Frozen execution and stopping rule

Before execution, preserve the initially written criteria/test, perform the
required interface/format preparation, and freeze the resulting actual execution
bytes plus all 678 existing tracked files, symlink targets, both fixed
references and all four individual memory fixtures. No expected semantics may
change during formatting. After verifying that freeze, execute only:

```sh
RUST_LOG=error moon check . --target native --frozen --deny-warn -j 1 </dev/null
RUST_LOG=error moon test spec_import_validation_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize </dev/null
```

Commands are serial, each in an owned process group with closed stdin and a
600-second whole-command cap. Retain raw stdout/stderr, actual exits/counts,
duration, changed-input checks and process-group exit proof. A compiler failure
is not a semantic failure; retain original bytes before any syntax/type repair.

If all four groups pass, register only their bounded composition evidence,
preserve all existing records/counts and make the authorized English local
test/evidence commit. If a definite implementation defect appears, preserve
the failing baseline and frozen criteria, make the smallest own-source fix,
and rerun these four plus only directly affected I/IC or FS/OAS controls.
Do not add groups after the fixed four have complete dual-entry evidence.

No full suite, release, Go/C++, CLI/API process integration, Linux, remote,
container, external/private-file I/O, dependency update, upstream change,
snapshot update, push or release is part of this batch. The private proposal
stays outside the project. All existing normative gaps remain explicit.

## Executed result and input identity

Preflight verified source HEAD `44c3d80c674a259c8bc38d15f275c890803bf53d`,
all 678 existing tracked files and symlink targets, both new execution inputs,
the fixed references and every individual memory fixture. The index was empty;
only the prepared test and report were untracked. No expected value, module
text, test semantics or product source was changed to obtain the result.

| Frozen command | Actual result | Duration | Owned PID/group |
| --- | --- | --- | --- |
| native check, frozen, deny-warn, -j 1 | exit 0 | 0.451 seconds | 42992, exited |
| native debug spec_import_validation_test.mbt, same options plus no-parallelize | exit 0; 4 total, 4 passed, 0 failed | 5.505 seconds | 43012, exited |

Check ran at 16:52:41.868-16:52:42.335 UTC and the test ran at
16:52:46.623-16:52:52.148 UTC on 2026-10-23. Each command used closed stdin,
RUST_LOG=error, one worker, its own process group and a 600-second cap. Neither
timed out. All frozen input hashes remained unchanged afterward. All four
groups traversed both entry choices; IV3 completed all four modes on each.
No first-failure tail remains unexecuted. No adjacent semantic run, extra group,
snapshot update or implementation correction was needed.

The raw evidence directory is `/tmp/moonjsonnet-import-validation.pgsarakp`.
initial/ preserves the initially written criteria/test. Before the execution
freeze, native frozen moon info exited 0 in 0.089 seconds and moon fmt exited
0 in 0.530 seconds; no existing tracked file or .mbti changed. Info has no
jobs option and used its auxiliary default. The format-equivalence receipt
checks unchanged string literals, comments and other tokens, allowing only
whitespace and optional trailing commas. original/ then preserves the exact
formatted execution bytes. The test was not edited again after its passing run,
so the delivered test hash is the hash actually checked and executed.

| Frozen artifact | SHA-256 |
| --- | --- |
| freeze.json | `14dca022a18a90a9f99f66463edabc1ab15ae1ad3b9cae71fc4f06fe72b0db99` |
| plan.json | `19fdacc4fb652fe2ae9a349dd7b941037768adedaffdbd6d2db3ca7fbc7ec71c` |
| fixtures.json, all four memory identities/texts | `10458014cc352941d3f1b990c69fce970e9b9bbac824b78665b8866681a79eeb` |
| original/spec_import_validation_test.mbt, execution and delivery bytes | `fa3cb0b273adda2795d4c94c524be8961c71b95740168ec69fd4a1133a91dd58` |
| original/docs/development/SPEC-IMPORT-VALIDATION-2026-10-23.md | `e0ccc6db9e6558b139fd011f0a6fb5597877b27b2402f7abc909b311a5919dfd` |
| baseline/test.stdout | `68e3eed91ee5d217ff66600d731275bc52d0148ef97ff479d64faef8d2e15499` |

| Individual fixture text, without added newline | UTF-8 bytes | SHA-256 |
| --- | --- | --- |
| bad-default | 34 | `aeb1b3f9db143ad84c609b1b530bf35cfc4aef0c42b7e05c1fc99577c5af929d` |
| bad-message | 37 | `4a9fa71df58f49510946c9ff2088a48203a853943f1d09ccbb2b5acf87444f74` |
| factory | 44 | `08308f7126b02621f2e90d7fc3a35346f896081bb8f76ec47d8cd20b2f860fbe` |
| config | 93 | `88820c22d5285088b43541a63bd6f7b18af3eef5367909bca562b300cc5fa20d` |

fixtures/memory/ contains those exact audit copies; the test reads none of
these files. Check stdout and test stderr were empty. Check stderr contained
only its 44-byte up-to-date message; test stdout was exactly the 38-byte
`Total tests: 4, passed: 4, failed: 0.` line with a newline. The *.run.json
receipts preserve actual argv, timestamps, elapsed time, exits/counts, raw
hashes, process-group absence and unchanged-input checks. The host was Darwin
mini.local 27.0.0 arm64; moon/moonrun were 0.1.20260920 (914d7da), moonc was
v0.10.14+7d59c7ec9, with rr_moon_mod and rr_moon_pkg enabled.

## Bounded evidence closeout

Only CORE-IMPORT receives IV1-IV4 mappings. Every prior evidence record, named
rule mapping and other prose-clause record is preserved. The updated matrix
generator exited 0 in 4.193 seconds under --frozen/-j 1 with formally approved
local cache access; metadata/matrix-final.* records that result. The earlier
metadata/matrix.* run checked the unchanged mapping before IV registration
and is not the validation of the new entries.

Two metadata readers were corrected to accept formatter line breaks in fixture
declarations and the existing compact JSON clause row. Both initial failures
occurred before their intended writes; their notes remain in metadata/. They
were not compiler or semantic failures and changed no fixture or oracle.

The inventory changes from 209 to 213 unique evidence IDs. Acceptance counts
remain 28 completed named reviews, 1 relative constructor review, 63 partial
rows and 2 unreviewed rows, with 70 named rules plus 24 prose/grammar rows.
CORE-IMPORT remains partial. Public-library subset/whole-function counts and
all existing normative gaps are unchanged; whole conformance remains incomplete.

No reusable-Evaluator/host-cache lifetime, filesystem identity, cycle policy,
source decoding, CLI/API process, release, full-suite, Go/C++, Linux, remote,
container or network campaign was performed. Historical full/native/platform
counts remain attached to their original sources. The delivery receipt binds
the exact local commit to this executed test and all fixture/output hashes;
the commit contains only this test/report and three mapping/matrix files.
Nothing is pushed or released, and no automatic follow-on group is started.
