# YAML syntax parser provenance

The eight `.mbt` source files in this directory come from
https://github.com/moonbit-community/yaml.mbt at commit
`e2f1129249a7cc707aa1c9c39bd8bfe207c93821` (version 0.0.7 source).
Copyright 2025 International Digital Economy Academy. MIT terms are retained in
`licenses/YAML-MIT.txt` at the module root. The upstream parser is a MoonBit port
of yaml-rust2. Only syntax/event parsing is included; its JSON loader and emitter
are not used. The generated interface is regenerated locally.

Local modifications: `Parser::next_token` is public so callers can consume events
iteratively and enforce budgets without the recursive `load` visitor. Root
`parse_yaml*.mbt` implements Go-compatible document splitting, scalar resolution,
mapping conversion and bounded alias expansion separately.
Plain scalars retain a colon before a flow delimiter, matching go-yaml v2's
YAML 1.1 scanner rather than the upstream YAML 1.2 rule.
The scanner accepts a configured flow nesting limit so buffered lookahead cannot
bypass the caller's depth bound. YAML 1.1 NEL/LS/PS line breaks are recognized.
A missing character advance in `scan_verbatim_tag` is fixed to prevent an
unbounded buffer loop on verbatim tags.
Percent-escaped multibyte tag characters decode UTF-8 payload bits and reject
overlong sequences, instead of combining raw octets as a code point.
