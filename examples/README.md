# Runnable examples

Run from the repository root with the native backend. These are real programs;
`moon test` compares their JSON values against committed reference outputs.

| Example | Run | Acceptance |
| --- | --- | --- |
| Multiple environments | `moon run cmd/main -- examples/environments/main.jsonnet` | Shared app/region; distinct dev/prod replicas, debug and endpoint |
| Batch dashboards | `moon run cmd/main -- examples/dashboards/main.jsonnet` | Service file → functions/comprehensions → exact panel structure |
| Embedded application | `moon run examples/embedded` | Valid result, invalid parameter, failed assertion and rejected root escape |

The embedded example imports the library through its public API, following the
per-directory runnable-package style used by official MoonBit examples. Examples
are kept in this repository, but excluded from the published library archive.
The three inputs also run against official Jsonnet v0.21.0 in the differential suite.
