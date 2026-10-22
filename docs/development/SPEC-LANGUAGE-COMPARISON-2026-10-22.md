# Language-stage Go/C++ comparison status

This report concerns the two independent language reviews introduced by
`2dd6dd4`: function binding/defaults and object scope/assertion/manifestation.
The [normative review](SPEC-LANGUAGE-REVIEW.md),
[clause matrix](SPEC-LANGUAGE-MATRIX.md) and
[MoonJsonnet execution evidence](SPEC-LANGUAGE-EVIDENCE-2026-10-22.md) are separate.

| Reference | Required identity | New execution in this language stage | Compatibility verdict |
| --- | --- | --- | --- |
| Google Jsonnet C++ v0.21.0 | bbb38f1020be1f5aed560928fb839b2c448cefb4 | Not run | Unknown |
| Google go-jsonnet v0.21.0 | 67968688d9952f50662e979fab1bef889d0d3e57; unmodified build metadata | Not run | Unknown |

No fresh reference checkout, build, installation or differential campaign was
performed. Historical parity reports describe their own source and corpus; they
are not results for these new tests. No missing or unexecuted reference check is
counted as passing, and no upstream error/output was used to choose this stage's
expected values. Future comparison must retain raw inputs, statuses, outputs,
fixed source/build identities and differences separately from normative decisions.

The separately approved frozen `af188da` Linux verification executes MoonJsonnet
only. Its native and 59 CLI/application checks cannot establish Go/C++ agreement
for either `af188da` or the newer language-stage source.

The later [recursive-binding/comprehension batch](SPEC-LANGUAGE-FORMS-EVIDENCE-2026-10-22.md)
at `e49dd7d` adds 15 library groups and 30 source CLI checks. No fresh Go/C++
reference execution was performed for it either. Its normative results do not
establish compatibility; both fixed-reference compatibility verdicts remain
unknown. No historical comparison count is carried forward as a passing result.
