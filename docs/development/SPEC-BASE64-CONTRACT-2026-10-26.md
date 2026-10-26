# Base64 String codepoints and byte-array equivalence

## Fixed contract and bounded scope

The review is pinned to Google Jsonnet
`bbb38f1020be1f5aed560928fb839b2c448cefb4`. The
[public signature and paragraph](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/stdlib.html#L3395-L3415)
describe `base64(input)`: a String or number Array, codepoints/numbers in 0..255,
the ordinary Base64 alphabet, `=` padding and no line breaks. The
[source definition](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/stdlib/std.jsonnet#L1356-L1401)
maps String characters through `std.codepoint` before grouping bytes. For the
unambiguous integral byte domain, String and corresponding Array inputs must
therefore agree. `base64('é')` and `base64([233])` both yield `"6Q=="`;
`base64(encodeUTF8('é'))` receives `[195,169]` and yields `"w6k="`.
No reference interpreter supplies these expectations.

The raw public HTML and upstream source hashes remain respectively
`0eb80c0ccaf781c4c2c1bc06a22d2d6e57f9866f41c0b62431b5ca4f510e6853` and
`e76dd6b8e51a2ca041b292dadea9c5521aeea5781b0ffe7c2c683865e7e45351`.
The source retrieval matched the previously recorded fingerprints. Raw-file
line numbers are used above; browser text extraction can number lines differently.

## Independent regression and original failure

The fifteen [contract groups](../../spec_base64_contract_test.mbt) were frozen
before changing product code, at clean tracked source `2d34a66` with 708 entries.
Most use separately built source and public handmade-AST entries. C05 and C06
split the primary witness so one failure cannot prevent the other entry's run.

| Groups | Obligation |
| --- | --- |
| C01-C03 | One required `input`, positional/named calls and aliases, binding errors before supplied demand, empty String/Array and result heads |
| C04-C08 | Literal ASCII/alphabet/padding results; source/AST Latin-1 witnesses; all 256 single-byte encodings; mixed lengths with high and zero bytes |
| C09-C10 | Invalid root/element types and codepoints/integer elements above 255 fail during evaluation |
| C11-C12 | Required input/element errors propagate before result-head observations; unselected branches, hidden values and unused arguments remain lazy |
| C13-C15 | Input/alias/map immutability, explicit UTF-8 composition controls, and the exact unwrapped full-byte-alphabet result |

Literal expected values were constructed before execution using octet arithmetic:
256 one-byte vectors, ten mixed-length vectors and the full 256-byte alphabet.
The scalar constants are independent of the product's encoder and of Go/C++.
Error-kind assertions express project phase boundaries; unrelated-error ordering,
native callback counts and exact host-generated diagnostics are not new promises.

The original native debug baseline on 2026-10-26 ran with frozen dependencies,
closed stdin, one worker and serial execution. Check exited 0 in 0.673s.
The contract file exited 2 in 10.513s: **10 passed, 5 failed**. Failures were
C05, C06, C07, C08 and C15, all consistent with the String branch encoding UTF-8
bytes after validating Latin-1 codepoints. Both primary entries returned
`["w6k=","6Q==","w78=","/w=="]` instead of
`["6Q==","6Q==","/w==","/w=="]` for the `'é'`/`[233]`/`'ÿ'`/`[255]` witness.
C07's completed source vector had all 256 Array results correct, while String
codepoints 128..255 all differed. Its later AST run was NOTRUN. C08 stopped at
the first String containing codepoint 128; later paths/vectors were NOTRUN.
C15 stopped after its first full-alphabet String comparison. Declared loop
contents are not evidence that those later assertions executed.

The unchanged legacy encoding file passed 2/2 in 0.289s. The separate observation
collector exited 0 in 0.187s and emitted all eighteen records; this is not a
normative pass count. The four-command window completed in 11.932s, with stable
input hashes and independently absent owned process groups. Original stdout,
stderr, exits, durations and the old test file remain preserved. Key SHA-256s:

| Original artifact | SHA-256 |
| --- | --- |
| Contract failure stdout | `1f997ee903ea0738f8a973d96c6881ff58fe472364bf5eb1a3f1f730eea38613` |
| Observation stdout | `34a9f6240fb93f6178c0b50c90dfdcd87d76ad095d7812b6baaed9f0f8defcd1` |
| Unchanged legacy stdout | `ddd0722f90fd133207ca9e423fc1faa05c3608f3be5c5eb4fdbea4259682b120` |
| Baseline execution result | `609a88953ec03175e57f042a44fd34e99de9bb4aa9b42998f4a7009796337896` |

## Scoped repair and exact legacy migration

The [repair](../../std_encoding.mbt) changes only the `base64` String branch:
each validated codepoint is appended as one Byte. The existing per-character
budget tick and above-255 rejection are retained. The Array helper, dispatch,
integer conversion, UTF-8 functions and both decoder paths are unchanged.

One item in the existing [encoding test](../../std_encoding_test.mbt) migrates:
the first result in
`[base64('é'),base64([233]),base64(input=[0,1,255]),base64(''),base64([])]`
changes from `"w6k="` to `"6Q=="`. Its other four expected values are identical.
The fixed codepoint definition requires one byte 233, whose padded encoding is
`"6Q=="`; the old value encodes two UTF-8 bytes and violates that definition.
The old assertion and its passing baseline remain historical compatibility
evidence. Decoder and invalid-number assertions are not silently migrated.

## Directed validation and formatted-input binding

The repaired candidate was tested on 2026-10-26 with the same fifteen independent
groups and all observation inputs unchanged. The local macOS native run used
frozen dependencies, closed stdin, one worker and serial execution:

```sh
moon check . --target native --frozen --deny-warn -j 1
moon test spec_base64_contract_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test spec_base64_profile_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test std_encoding_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test arguments_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
moon test spec_string_scalar_test.mbt --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

| Command | Actual result | Seconds | Exit |
| --- | --- | ---: | ---: |
| Check | Passed | 0.729 | 0 |
| Independent contract | 15/15 groups | 15.162 | 0 |
| Profile collector | 18/18 observations from nine inputs; zero normative passes | 0.243 | 0 |
| Migrated encoding regression | 2/2 groups | 0.289 | 0 |
| Argument regression | 1/1 group | 0.187 | 0 |
| String-scalar regression | 4/4 groups | 0.295 | 0 |

The complete window took 17.418s within its 600s budget. All six owned process
groups and the controller exited and were independently confirmed absent.
All 711 candidate inputs were stable throughout execution. The original five
failures remain historical failures; the new 15/15 result completes the formerly
blocked C07/C08/C15 paths with the unchanged assertions. It does not rewrite
their original NOTRUN subbranches. Profile stdout is byte-identical to baseline.

The original candidate freeze is
`e8e593331427ff097fea2eec44f991076f9742db6ee24b2f951954840a255046`;
its execution result is
`1d676da433a0ad8f294d80b4fc47a01eea2992866579c5dcdff08b365967107b`.
The passing contract stdout is
`4a9e15c05605fecaa5caebbb582b737f49bcc287b3baa55643b3b084e7e0b54a`.
The implemented `std_encoding.mbt` SHA-256 is
`9f863a5d2046bb3ac63efe1510f700118c251956483da468261f81549c7fce92`;
the migrated legacy test is
`5b39846fe7a09bcc91042cf278809a0b1e40c8622a2d169cd9d6901eb57e5c11`.

Subsequent `moon info --frozen`, `moon fmt` and `moon fmt --check` each exited 0.
All 20 generated interface files, product bytes and legacy test bytes remained
unchanged. Formatting changed only layout and trailing commas in the two new
test files. The ordered non-layout tokens and exact String/Char literals were
compared with the executed inputs; there is no assertion or input migration.

| File | Executed SHA-256 | Formatted SHA-256 |
| --- | --- | --- |
| `spec_base64_contract_test.mbt` | `9f3a73b7aa93f54757f6768aa8bef286ceb1f64a994c59e79281c8d793e7fcd7` | `e4509595ecd40a8283d47997ae55bf5f7723a5c7d7af8b1032785b1c6fca2844` |
| `spec_base64_profile_test.mbt` | `c8a36de1a2a62297f54d683b7dce1e4a6b7d32b3f6a064898b3f1ec397a01d8a` | `8d1be03754b95e751a5b08efd29a1382c30920877032acc164066bba474c2ac2` |

These formatted files and this updated record are later bytes, not the old
candidate freeze. At that directed checkpoint no post-format semantic rerun was
claimed. The subsequent complete run below validates the final committed bytes.

## Complete macOS native debug regression at 5ae6aab

The complete package suite on 2026-10-26 binds final implementation commit
`5ae6aabf4150fcf1e9114555f94d9e9419ac6249` and all 711 committed inputs. With
`RUST_LOG=error`, closed stdin and the command below, actual output reports
**851/851 passed, failed 0, skipped 0, exit 0**. Generated test metadata agrees:
799 root blackbox cases plus 52 other cases. The entire window took 152.930s
within its 600s bound; no separate compile/test duration is inferred.

```sh
moon test --target native --debug --frozen --deny-warn -j 1 --no-parallelize
```

The committed-input manifest SHA-256 is
`770529c8724536e54820ffbb157a6944c03d285ca2e157150c2526b6a6a08da3`;
raw stdout is `00ca837672c893409005c9e9284229c5784e13609bb64e1e1138878be822c86e`.
Stderr is empty. Inputs and clean repository state remained stable; all owned
processes exited. This run includes the final formatted tests. The eighteen
observations still match the baseline and earn zero normative passes; B64-R0/F0
and the original five failures retain their recorded status. Package regression
does not establish whole-function or complete specification acceptance.
Release, Linux and standalone CLI/API remain NOTRUN for this changed product;
the earlier 835-test platform cohort remains bound to its earlier source.

## Unresolved boundaries retained separately

- **B64-R0:** public 0..255 excludes negatives, but source sanity only tests
  `<256` before masking. The current Array helper rejects negative inputs.
  This source/domain conflict is not resolved by the String repair.
- **B64-F0:** public wording permits numbers without explicitly stating
  integrality. Fractional inputs reach source bitwise operations; the
  [numeric rule](https://github.com/google/jsonnet/blob/bbb38f1020be1f5aed560928fb839b2c448cefb4/doc/ref/spec.html#L2807-L2817)
  specifies signed 64-bit conversion without an explicit fractional rounding
  rule. Values between 255 and 256 also expose the prose/source upper-bound
  difference. The existing nonintegral rejection remains a project profile.

The [nine ungraded inputs](../../spec_base64_profile_test.mbt) produced matching
source/AST errors in all eighteen baseline observations, including negative or
fractional elements preceding an `error` expression. That observation does not
settle either boundary or establish an independent error-priority rule. Base64
decoder invalid-input policy and malformed Unicode are outside this encoding
repair. The generated public inventory is a separately bound historical snapshot
and is not regenerated by this closeout. This scoped record establishes the tested
byte-domain obligations, with no whole-function acceptance; overall conformance
is incomplete.
