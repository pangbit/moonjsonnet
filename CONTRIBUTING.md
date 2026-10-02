# Contributing

This project currently has one maintainer. Small, reviewable commits and a
reproducible local baseline are preferred over branch/process ceremony.

1. Describe the language behavior and make the smallest failing example.
2. Check the pinned Jsonnet v0.21.0 reference; add a regression case without
   removing existing failures or relabeling supported behavior as unsupported.
3. Keep parser, evaluator and host responsibilities separate. Public API types
   belong to the package users import. Never manually edit generated `.mbti`.
4. Run the commands in [validation](docs/VALIDATION.md), including zero-warning
   checks. Use `.mbtx` for project automation.
5. Use conventional commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`); describe
   the user-visible change and keep the commit scope narrow. Stage explicit paths.

Document public behavior, limits, errors and any unsupported feature. New public
APIs need black-box or executable documentation tests. Fix compiler warnings
rather than blanket-disabling them. `moon info` then `moon fmt` must be run before
committing; review interface changes. Add attribution and license information
for externally sourced material. Do not commit generated binaries, credentials,
reference checkouts, `_build`, or local environment configuration.

Issues and pull requests are welcome at
<https://github.com/pangbit/moonjsonnet>. Publication, remote pushes and release
tags are separate maintainer actions; a local test pass does not imply a registry
publication or a successful remote CI run.
