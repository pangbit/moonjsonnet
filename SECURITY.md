# Security boundaries

Jsonnet resource limits are not a general-purpose sandbox. Run untrusted input
in a separately isolated process with OS CPU/memory/time limits as appropriate.
The library is synchronous. Step limits are accounting units, not milliseconds
or an exact byte-level heap budget, and do not interrupt a custom host callback.

`FileHost` resolves canonical paths and checks root boundaries with a separator,
rejecting `..` and symlink escapes. It opens each canonical relative component
using directory descriptors with `O_NOFOLLOW`, and only reads regular files with
a bounded size. The configured root and its ancestors must be trusted and stable;
the host does not defend against a privileged attacker changing mounts or root
ancestors concurrently. It is a read boundary, not a confinement mechanism for
the whole embedding process. Output files are explicitly chosen by the caller.

Custom resolvers must enforce their own policy before returning data. Cache
identities must be stable, and a resolver must not return different contents for
the same identity during one evaluation. Use fresh file hosts to observe changes.

Please report a reproducible security issue privately through the repository's
GitHub private vulnerability reporting if enabled. If unavailable, open an issue
requesting a private contact without posting exploit details or sensitive data.
