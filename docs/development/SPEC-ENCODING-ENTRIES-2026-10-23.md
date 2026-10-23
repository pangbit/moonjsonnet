# UTF-8 source entry boundaries

## Frozen criteria

Base 638c0dff27c1f94807cdc4caa21d80cf62dd4626. Official Jsonnet is fixed at
bbb38f1020be1f5aed560928fb839b2c448cefb4. [Lexing](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#lexing)
line 123 defines programs as UTF-8 encoded text. [Core imports](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#core_syntax)
(907-916) distinguish code, UTF-8 String data and binary data.
These statements fix the successful valid-text domain. They do not themselves
standardize an invalid-byte recovery algorithm, diagnostic kind/message or BOM
handling. Those questions must not become passing language expectations.

The independent [project API](../reference/API.md) (importer/host sections)
requires strict UTF-8 for winning file candidates and code/String imports.
The [CLI contract](../reference/CLI.md) also requires strict UTF-8 file/stdin
input. Rejection tests below check that documented **host policy**, separately
from the fixed language's successful UTF-8 domain. No Go/C++ result is an oracle.

| Path / group | Independent required result |
| --- | --- |
| EN1, direct library String | A manually written String source and independent canonical Literal AST retain the literal Unicode result. This API receives text already constructed by the caller; it cannot test rejection of original invalid bytes or prove CLI decoding. |
| EN2, binary code import | A literal byte program containing one-to-four-byte scalar edges, composed/decomposed text, interior U+FEFF and valid U+FFFD decodes/parses to the literal expected String. Parsed and hand-built ImportFile headers are separate entries; neither supplies an AST for the imported byte text. |
| EN3, demanded import errors | One malformed-byte sample rejects according to the strict host policy. Distinct valid UTF-8 programs instead propagate Syntax, Static and an isolated Unicode Runtime marker. Every unused import returns 42 without invoking its resolver, so decoding is not performed eagerly. |
| CLI files/stdin/import | Build only native debug cmd/main at nice 10/-j 1. The same literal valid byte fixture succeeds independently as file, stdin and code import. Three representative invalid quoted byte payloads reject with exit 1/no stdout/nonempty diagnostic as file and stdin; a demanded invalid code import rejects while an unused one yields 42. No exact human message or cross-entry generalization is required. |

Reuse IU1-IU4 and IB1-IB4 for existing importstr/importbin data and lazy-byte
contracts; do not rerun their whole groups. Source/AST success observes values,
not all source encodings. Expected text is literal, never decoded from fixture
bytes by an implementation to produce the oracle. CLI fixture bytes and expected
text are also declared independently. CLI receipts are supplemental host
evidence, not fake Moon case identities in the schema-v2 matrix.

Initial UTF-8 BOM stripping/acceptance remains unadjudicated and is not probed.
Interior U+FEFF is String data, not an initial-BOM verdict. Malformed host
String/surrogate representation and source escape-surrogate policy remain
unadjudicated. Encoded-surrogate/other malformed-byte treatment has no new
normative verdict here: prior IU2 or new strict-host observations cannot fill
that gap. Full invalid-byte recovery, UTF-16/other encodings, all whitespace/
comments/greedy-token compositions and universal decoder/resource properties
remain outside completion. LEX-ENCODING may gain partial evidence only.

Three new bounded library groups plus 11 CLI cases, sequential nice 10,
native debug/frozen -j 1, no parallel tests. Preserve first actual failures
before minimal product repair. Use existing schema/checker; no new metadata
framework, full suite, release/Linux, remote/browser/install/push or private
proposal files. A0/B0/N0/R0/PE0 and previous child-relative decisions stay intact.

<!-- Criteria above are frozen before execution; append results below. -->

## Results and path-specific interpretation

The first native debug library run passed **3/3, exit 0**. Its unchanged test
SHA-256 is `2a4d39967638879a230a300ad345a7f52986a03ab739048e996d12f911dd4d4c`.
The native-debug cmd/main build exited 0; the first supplemental CLI run passed
**11/11**. No product failure or implementation/API change was found.
No semantic groups, old CLI suite or importstr/importbin suite were rerun.

| Exercised route | Inspected path and evidence limit |
| --- | --- |
| Direct library text | [Program::parse](../../program.mbt) accepts a String and lexes it; EN1 has no original byte buffer to validate. Its separate Literal AST checks the canonical value, not lexing. |
| Reusable Evaluator code import | [ImportReader](../../evaluator_imports.mbt) applies the configured binary callback and strict text decoder; [Vm::import_file](../../imports.mbt) subsequently parses/validates code on demand and retains error categories. EN2/EN3 exercise this configuration, not every importer/query API. |
| CLI file | [load_input](../../cmd/main/io.mbt) calls FileHost.load; [decode_source](../../fs/host.mbt) strictly decodes the winning file. The valid file and three representative invalid quoted payloads are separate observations. |
| CLI stdin | [main](../../cmd/main/main.mbt) reads bounded bytes and performs its own strict decode. Success/failure receipts are independent of the file path. |
| CLI code import | FileHost.resolve supplies decoded text to Vm::import_file. Valid/invalid demanded imports and an unused bad target are exercised; no inference from the reusable Evaluator path supplies these receipts. |

The [concrete CLI runner](../../tools/spec-encoding-cli-test.py) records each
argv, stdin bytes, fixture hex/hash, stdout/stderr bytes, executable hash and
outcome. Success expectations are literal JSON values. Bad-input rows enforce
only the documented host rejection protocol, not a normative error message or
recovery algorithm. CLI unused-import success proves no eager decoding error
escaped; no syscall/read count is asserted there. Zero resolver callbacks are
measured only by EN3 in the library path. Raw and String import contracts are
reused from IU/IB under their existing scopes; strict source decoding is not
substituted for the separate std.decodeUTF8 library-function contract.

The unchanged schema-v2 checker passed **179** unique Moon file::case bindings.
CLI receipts remain supplemental and are not included in that count. No new
metadata mechanism or repeated negative-control suite was needed. All 176 old
evidence records, 68 named mappings and 23 other prose rows retain their bytes
and meanings outside the evidence insertion and single LEX-ENCODING edit.

The 94-row matrix now records **28 named completions, 1 relative constructor,
60 partial and 5 unreviewed**. LEX-ENCODING changes only from unreviewed to
partial. Initial BOM handling, surrogate/host-String representation and
normative malformed-byte recovery/diagnostics are still unadjudicated; the
successful interior U+FEFF/valid U+FFFD fixtures resolve none of them. Other
host modes and the full lexical obligation remain outside this batch.

Native check, supported info, root/tool formatting and matrix generation
exited 0; product, old tests, checker/harness and .mbti remain unchanged.
Final tracked/staged documentation and exact commit/blob/clean/process receipts
are under `/tmp/moonjsonnet-encoding-entry.8vnfcep1`. CLI executable/source
identities are frozen there; all temporary files contain self-made public
fixtures. Full native 539/539 is still only evidence for 5651ae9. No upstream
comparison, release/Linux run, dependency install, remote or push occurred.
A next different candidate is fixed operator desugaring, starting with an
explicit mapping of existing comparison/Boolean evidence and open PE0/B0 limits.
