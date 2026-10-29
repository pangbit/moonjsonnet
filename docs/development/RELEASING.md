# Release checklist

Publication and remote push are explicit maintainer actions. Versions 0.1.0 and
0.2.0 have published registry records; 0.1.0 was published on 2026-10-13.
The selected next candidate is 0.2.1. Do not overwrite an existing version.
Versioned release notes describe the changes without asserting publication or
a source tag. Record the registry result and timestamp after actual success.
Mooncakes publication is a project delivery goal; this checklist does not
establish a competition requirement or a successful publication/remote CI run.

The existing macOS/Linux native debug/release campaigns each passed 1087/1087
at product source `3d25317903f1d42799c3d05a1e3c07bdf3a75ffc`. Reuse those results
only after confirming the tested product and fixture hashes still match. The
138 finite public mappings do not establish complete v0.21.0 conformance.
Version/documentation changes create a new package identity: earlier archive
and local-consumer success do not verify the 0.2.1 archive or a registry install.

1. Review the diff, compatibility scope, license/NOTICE, module version and
   repository URL. Select applicable checks from [VALIDATION](VALIDATION.md),
   reusing source-identical evidence. Version/documentation-only edits do not
   require repeating unchanged runtime suites; verify the CLI version banner
   separately when it changes.
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
   Keep version `0.2.1` notes free of unverified publication dates or claims.
   If the version already exists, stop and select a new version explicitly;
   do not attempt to replace it. Revalidate a changed toolchain or package.
6. With explicit authorization, push commits and verify CI for that exact release
   commit; an older green main run is not evidence for new commits. No auto-publish
   token is stored in CI. Then publish using `moon publish` and verify the registry
   with a fresh independent `moon add pangbit/moonjsonnet@0.2.1` consumer. Update
   both README status paragraphs if needed after the actual publication is confirmed;
   do not present the local archive consumer as a registry installation.
7. Record the actual registry result and archive checksum, update release notes,
   and create a matching source tag/release when authorized.

Local package/consumer success, GitHub push/CI success and Mooncakes publication
are separate evidence. `moon publish --dry-run` can submit a package for registry
validation; it is not a local-only packaging check and must not be used during
an offline or no-publication audit. No publication command is part of steps 1–5.
