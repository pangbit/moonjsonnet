# Release checklist

Publication and remote push are explicit maintainer actions. Version 0.1.0 was
published on Mooncakes on 2026-10-13. The current candidate is 0.2.0 and remains
Unreleased until its registry publication succeeds. This checklist does not
claim a 0.2.0 publication, source tag or successful remote CI run.

1. Review the diff, compatibility matrix, license/NOTICE, module version and
   repository URL. Run every applicable check in [VALIDATION](VALIDATION.md).
2. Commit source and generated interfaces. Bind the acceptance report to that
   source commit; a separate report-only commit avoids a circular self-hash.
3. Confirm the installed command semantics, then run local-only
   `moon package --list --frozen`. Confirm source, all three native C stubs,
   generated interfaces, LICENSE, NOTICE and every third-party license exist.
   The package keeps the two consumer indexes under `docs/`, and only API, CLI,
   COMPATIBILITY, VERSIONS and GO-STDLIB-SURFACE under `docs/reference/`.
   Both root README languages must be present. Tests, examples, scripts,
   `docs/archive/`, `docs/development/` and CONTRIBUTING must be absent.
   Run `moon run tools/documentation.mbtx`, check relative links and scan the extracted files
   for local paths, private network addresses and credential material.
4. Run `moon run tools/consumer.mbtx`, record its actual selected test count, verify a
   minimal native executable against the extracted archive, and record the
   actual archive SHA-256 and file manifest. Do not assume separate ZIP builds
   are byte-identical merely because their extracted contents match.
5. Verify a clean worktree and `moon whoami` for namespace `pangbit`. Inspect the
   target registry version before any publication; versions are release identities.
   Keep the candidate `0.2.0` marked Unreleased until its authorized publication.
   If the version already exists, stop and select a new version explicitly;
   do not attempt to replace it. Revalidate a changed toolchain or package.
6. With explicit authorization, push commits and verify remote CI. No auto-publish
   token is stored in CI. Then publish using `moon publish` and verify the registry
   with a fresh independent `moon add pangbit/moonjsonnet@0.2.0` consumer. Update
   both README status paragraphs only after the actual publication is confirmed;
   do not present the local archive consumer as a registry installation.
7. Record the actual registry result and archive checksum, update release notes,
   and create a matching source tag/release when authorized.

Local package/consumer success, GitHub push/CI success and Mooncakes publication
are separate evidence. `moon publish --dry-run` can submit a package for registry
validation; it is not a local-only packaging check and must not be used during
an offline or no-publication audit. No publication command is part of steps 1–5.
