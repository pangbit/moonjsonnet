///|
// Preserve this CLI's existing help text and host-policy documentation.
fn cli_usage() -> String {
  [
    "Usage: moonjsonnet [-e/--exec] [-S/--string] [-y/--yaml-stream] [-m/--multi DIR] [-c/--create-output-dirs] [--root DIR] [-V/--ext-str NAME[=VALUE]] [--ext-code NAME[=CODE]] [-A/--tla-str NAME[=VALUE]] [--tla-code NAME[=CODE]] [--ext-str-file/--ext-code-file/--tla-str-file/--tla-code-file NAME=FILE] [-o/--output-file FILE] [--max-steps N] [--max-depth N] [--max-source-bytes N] [--max-import-bytes N] [--max-imports N] [--max-output-bytes N] [--] INPUT\nINPUT is a file, - for stdin, or code with -e. Combined short options expand before --.",
    "-J/--jpath DIR adds a library path (rightmost wins). JSONNET_PATH adds colon-separated paths (leftmost wins), below -J. All imports remain confined to --root.",
    "-t/--max-trace N crops error context (default 20; 0 is unlimited).", "-s/--max-stack N limits runtime frames (default 500; positive).",
  ].join("\n") +
  "\n"
}
