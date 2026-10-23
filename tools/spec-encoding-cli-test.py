#!/usr/bin/env python3
"""Bounded UTF-8 entry checks. Pass a built native-debug CLI and a new evidence directory.

No build, network, upstream tool, user input file, or dependency installation is
performed here. Fixture text/bytes are independent literals. Invalid-byte rows
assert the documented project host policy, not a normative recovery algorithm.
"""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    assert len(sys.argv) == 3, "usage: spec-encoding-cli-test.py CLI NEW_EVIDENCE_DIR"
    cli = Path(sys.argv[1]).resolve(strict=True)
    output = Path(sys.argv[2]).resolve()
    output.mkdir(parents=True, exist_ok=False)
    fixture_root = output / "fixtures"
    fixture_root.mkdir()
    expected = "\u00a0\u07ff\u0800\ud7ff\ue000\uffff\U00010000\U0010ffff|é|e\u0301|A\ufeffZ|�"
    valid = b"/* \xc3\xa9 */\r\n'\xc2\xa0\xdf\xbf\xe0\xa0\x80\xed\x9f\xbf\xee\x80\x80\xef\xbf\xbf\xf0\x90\x80\x80\xf4\x8f\xbf\xbf|\xc3\xa9|e\xcc\x81|A\xef\xbb\xbfZ|\xef\xbf\xbd'"
    invalid = {"ff": b"'\xff'", "overlong": b"'\xc0\xaf'", "truncated": b"'\xe2\x82'"}
    fixtures = {"valid.jsonnet": valid, "valid.libsonnet": valid}
    fixtures.update({"bad-" + name + ".jsonnet": data for name, data in invalid.items()})
    for name, data in fixtures.items():
        (fixture_root / name).write_bytes(data)
    # None is only the host-rejection expectation; no fixture returns JSON null.
    cases = [
        ("file-valid", ["valid.jsonnet"], None, expected),
        ("stdin-valid", ["-"], valid, expected),
        ("code-import-valid", ["-e", "import 'valid.libsonnet'"], None, expected),
        ("unused-code-import", ["-e", "if false then import 'bad-ff.jsonnet' else 42"], None, 42),
    ]
    for name, data in invalid.items():
        cases.append(("file-host-reject-" + name, ["bad-" + name + ".jsonnet"], None, None))
        cases.append(("stdin-host-reject-" + name, ["-"], data, None))
    cases.append(("code-import-host-reject", ["-e", "import 'bad-ff.jsonnet'"], None, None))
    identity = {
        "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
        "cli": str(cli), "cli_sha256": sha(cli.read_bytes()),
        "runner_sha256": sha(Path(__file__).read_bytes()),
        "fixtures": {name: {"hex": data.hex(), "sha256": sha(data)} for name, data in fixtures.items()},
        "expected_valid_text": expected,
        "scope": "BOM-free valid UTF8 and documented strict host rejection; no malformed-byte language or BOM-policy verdict",
    }
    (output / "inputs.json").write_text(json.dumps(identity, indent=2, ensure_ascii=False) + "\n")
    results = []
    for name, arguments, stdin, value in cases:
        argv = ["nice", "-n", "10", str(cli), "--root", str(fixture_root), *arguments]
        started = time.monotonic()
        proc = subprocess.run(argv, input=b"" if stdin is None else stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
        (output / (name + ".stdout")).write_bytes(proc.stdout)
        (output / (name + ".stderr")).write_bytes(proc.stderr)
        if value is None:
            passed = proc.returncode == 1 and not proc.stdout and bool(proc.stderr)
        else:
            try:
                actual = json.loads(proc.stdout.decode("utf-8"))
            except (UnicodeDecodeError, ValueError):
                actual = None
            passed = proc.returncode == 0 and not proc.stderr and actual == value
        results.append({"case": name, "argv": argv, "stdin_hex": None if stdin is None else stdin.hex(), "expected": value,
                        "host_rejection_only": value is None, "exit": proc.returncode, "passed": passed,
                        "seconds": round(time.monotonic() - started, 3), "stdout_sha256": sha(proc.stdout), "stderr_sha256": sha(proc.stderr)})
        (output / "results.json").write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n")
        print(json.dumps({"case": name, "exit": proc.returncode, "passed": passed}), flush=True)
        if not passed:
            raise AssertionError("encoding entry mismatch: " + name + "\n" + proc.stderr.decode("utf-8", errors="replace"))
    assert sha(cli.read_bytes()) == identity["cli_sha256"]
    assert sha(Path(__file__).read_bytes()) == identity["runner_sha256"]
    (output / "result.json").write_text(json.dumps({"passed": len(results), "total": len(cases), "all_passed": True,
                                                   "source_commit": identity["source_commit"], "cli_sha256": identity["cli_sha256"]}, indent=2) + "\n")


if __name__ == "__main__":
    main()
