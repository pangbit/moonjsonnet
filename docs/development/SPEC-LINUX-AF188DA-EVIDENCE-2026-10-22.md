# Approved frozen af188da Linux verification

The parent released the serial Linux window after the earlier remote job had
terminated. The previously approved archive and additional controller were the
only files uploaded to `root@192.168.12.111`, under
`/tmp/moonjsonnet-spec-af188da-20261022`. No bundle or newer source was uploaded.

This result binds source commit
`af188daba70b19b8b7b1b283fa856d372d62c132` by verified archive bytes, not a Git
checkout. The controller checked all 516 archive file/link inputs against a
fresh archive reference before and after execution. README.md's target was
checked as README.mbt.md before execution and again after completion.
No Git status or Git metadata was synthesized.

| Check on Linux x86_64 | Actual result |
| --- | --- |
| Native check, `--frozen --deny-warn -j 2` | Exit 0 |
| Native debug, same flags | 425/425; exit 0; no stderr |
| Native release, same flags | 425/425; exit 0; no stderr |
| Release CLI/P0/lazy and three application scenarios | 59/59; build and controller exit 0 |
| Archive/controller bytes and 516 source inputs | Unchanged |
| Existing SDK executable hashes and dependency-cache contents | Unchanged |
| Seven SafeLine container IDs/images/status/ports and host listeners | Exact before/after records unchanged |
| Own process, service, cgroup, timer and namespace mounts | Absent after completion |
| Approved remote temporary directory | Removed after every downloaded evidence file's hash was verified |

The environment, monitoring and embedded-application cases include exact JSON
outputs, parameter failures, assertions, controlled import escape, resource
limits, nonzero error status and preserved existing output files. The
[retained audit](spec-linux-af188da-evidence-2026-10-22.json) lists all 59 case IDs,
phase/log hashes, source identity and binary identities. This is a bounded
regression/scenario result, not full specification acceptance or Go/C++ parity.

The fixed existing tools were moon/moonrun 0.1.20260920 (914d7da) and moonc
v0.10.14+7d59c7ec9. All dependency use was frozen. The transient service had
200% CPU quota, 4 GiB memory maximum, zero additional swap, a 256-task limit,
read-only system paths and a private network namespace. Writable paths were
the approved directory and the existing empty dependency-cache lock file.
No toolchain/dependency installation, upgrade, SafeLine configuration change,
database access, push, release or tag occurred.

Native build scratch and controller build scratch used private temporary
filesystems capped at 7 GiB and 512 MiB. The remaining 512 MiB of the 8 GiB
budget covered the packet/source/evidence, observed at 21,229,938 bytes after
the run. Each native phase had its original 600-second controller cap. The
outer service used the remaining original budget, with cleanup time reserved;
the controller's internal deadline did not reset that outer budget.

The 30-minute total clock began at **07:32:29 UTC** on 2026-10-22, before remote
preflight or transfer, and cleanup finished at **07:46:01 UTC**: **812 seconds**
including preflight, transfer, execution, retrieval and cleanup. The service
itself ran for 8min 52.467s, used 15min 44.453s CPU and reported a 1.6 GiB memory
peak with zero swap peak. Existing unrelated historical failed units were only
observed; cleanup addressed this job's own unit and resources.

## Artifact identity

| Artifact | Bytes / SHA-256 |
| --- | --- |
| source-af188da.tar | 7,290,880 / b7c8d68558bcf3390c295729f26635b8ac8a8e5c6838da09c742d83ca2d6cc31 |
| verify-af188da.mbtx | 12,592 / 84248bf131b1afe20d8b44517a3997bd22f3574992352533d62ebe733839ba24 |
| Controller report.json | f3ed7e0d718414fb6ef7b772f0853427111b838591ec16961111f1dfe14a3987 |
| Provenance with 516 member hashes | 7c1413a21adb33ded068c8ef24ce5abc26a31bb8c81dee7f09978c6ae7c16796 |
| Raw cases.json | 1758f84339362d421f1604372a01ac02ab20f73bef2215bf92cc589666e3168e |
| Identical debug/release stdout summaries | 7a896dee13dae8fb1c5a8f8fa41e03d621321fd1f7739dcc3f7683c06d9ec176 |
| Linux release CLI | 6e857387e8e0bdc7720a8455343a7b0a205ad3f9cdf3b035abd4b3b8a5657483 |
| Linux release embedded executable | eb947c4e1421ac372d4d6ce97ba5efeeff3587674db95f5b0d767677641c97a4 |

Raw downloaded logs and before/after observations remain at
`/tmp/moonjsonnet-language-contracts.sSg2Ad/linux-af188da`. Their download hashes
matched the remote hashes before remote removal. The committed compact audit
retains the results and hashes; temporary raw files are not an archival
delivery guarantee. No remote phase failed or remained unexecuted.

## Scope separation

This approved packet has **425 tests / 59 scenarios**. It contains neither the
subsequent string/Unicode changes validated locally at **444 tests / 67
scenarios**, nor the [new language checks](SPEC-LANGUAGE-EVIDENCE-2026-10-22.md)
validated locally at **457 debug tests / 33 focused release tests**. Those newer
sources have no Linux result from this run. The
[Go/C++ comparison report](SPEC-LANGUAGE-COMPARISON-2026-10-22.md) remains separate
and unknown for the new cases. The serial remote window is released.
