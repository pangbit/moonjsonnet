# Release checklist

Publication and remote push are explicit maintainer actions. This document does
not claim they have happened. The current changelog remains Unreleased until a
registry publication succeeds.

1. Review the diff, compatibility matrix, license/NOTICE, module version and
   repository URL. Run every applicable check in [VALIDATION](VALIDATION.md).
2. Commit source and generated interfaces. Bind the acceptance report to that
   source commit; a separate report-only commit avoids a circular self-hash.
3. Run `moon package --list`; confirm source, C stubs, LICENSE, NOTICE, README and
   linked package docs exist. Tests, examples, scripts and reports must be absent.
4. Run the independent archive consumer check. Record the archive SHA-256.
5. Verify a clean worktree and `moon whoami` for namespace `pangbit`. Inspect the
   target registry version before any publication; versions are release identities.
6. With explicit authorization, push commits and verify remote CI. No auto-publish
   token is stored in CI. Then publish using `moon publish` and verify the registry
   with a fresh independent `moon add pangbit/moonjsonnet@0.1.0` consumer.
7. Record the actual registry result and archive checksum, update release notes,
   and create a matching source tag/release when authorized.

Local package/consumer success, GitHub push/CI success and Mooncakes publication
are separate evidence. A dry run does not prove the version exists in the registry.
