#!/usr/bin/env python3
"""Bounded metadata-only regression controls; uses Python's standard library.

Run from the repository root:
  python3 tools/spec-language-matrix-test.py REFERENCE_DIR NEW_EVIDENCE_DIR
After a positive-only failure, reuse verified negative results with the same
arguments followed by --resume-positive. Existing attempts are retained.
Use --case-prefix sign- for only the comparison-sign form controls.
Use --case-prefix neg- for only the Boolean-negation form controls.
Use --case-prefix pair- for only the static-pair transfer controls.
Only tracked/staged inputs are mirrored; stage new test/report fixtures first. The
negative checker runs sequentially in that mirror. Positive readback runs in
the real repository and regenerates its matrix, whose Git identity is required.
No Jsonnet programs or upstream tools execute.
"""

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import time


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key: " + key)
        result[key] = value
    return result


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference")
    parser.add_argument("output")
    parser.add_argument("--resume-positive", action="store_true")
    parser.add_argument("--case-prefix", default="")
    args = parser.parse_args()
    resume = args.resume_positive
    root = Path.cwd().resolve()
    reference = Path(args.reference).resolve()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=resume)
    mapping_path = Path("tests/spec-language-coverage.json")
    original_text = (root / mapping_path).read_text()
    original = json.loads(original_text, object_pairs_hook=unique_object)
    tracked = set(subprocess.check_output(["git", "ls-files", "-z"], text=True).strip("\0").split("\0"))
    paths = {str(mapping_path), "tools/spec-language-matrix.mbtx"}
    paths.update(item["file"] for item in original["evidence"].values())
    for row in list(original["rules"].values()) + original["clauses"]:
        paths.update(row["implementation"])
        if "rule_review" in row:
            review = row["rule_review"]
            paths.add(review["review_report"])
            paths.update(item["file"] for item in review["inspection"])
            paths.update(review["evidence_sha256"])
    mirror = output / "mirror"
    identities = {}
    for path in sorted(paths):
        relative = Path(path)
        assert not relative.is_absolute() and ".." not in relative.parts, path
        assert path in tracked, path
        source = (root / relative).resolve()
        assert root in source.parents, path
        if not resume:
            target = mirror / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
        identities[path] = sha(source)
    if resume:
        assert identities == json.loads((output / "inputs.json").read_text()), "inputs changed; a new run is required"
    else:
        (output / "inputs.json").write_text(json.dumps(identities, indent=2) + "\n")
    dump = lambda data: json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    cases = []

    def add(name, data, marker, changed_source=None):
        cases.append((name, dump(data) if isinstance(data, dict) else data, marker, changed_source))

    def insert_member(text, member):
        return text[:1] + member + "," + text[1:]

    prefix = '  "evidence": {'
    assert original_text.count(prefix) == 1
    super_case = json.dumps(original["evidence"]["SP1"], ensure_ascii=False)
    add("duplicate-evidence-key", original_text.replace(prefix, prefix + '"SP1":' + super_case + ",", 1), "duplicate mapping key: $.evidence.SP1")
    add("duplicate-top-key", insert_member(original_text, '"version":2'), "duplicate mapping key: $.version")
    add("duplicate-nested-key", insert_member(original_text, '"validator_fixture":{"n":0,"n":1}'), "duplicate mapping key: $.validator_fixture.n")
    add("escaped-duplicate-key", original_text.replace(prefix, prefix + '"SP\\u0031":' + super_case + ",", 1), "duplicate mapping key: $.evidence.SP1")
    add("duplicate-key-in-array", insert_member(original_text, '"validator_fixture":[{"n":0,"n":1}]'), "duplicate mapping key: $.validator_fixture[0].n")
    data = copy.deepcopy(original)
    del data["evidence"]["SC2"]["test_id"]
    add("missing-global-test-id", data, "global test ID required: SC2")
    data = copy.deepcopy(original)
    data["evidence"]["PREC1"] = copy.deepcopy(data["evidence"]["SP1"])
    add("duplicate-global-test-id", data, "duplicate global test ID:")
    data = copy.deepcopy(original)
    data["evidence"]["SC2"]["file"] = data["evidence"]["SP1"]["file"]
    add("wrong-file", data, "evidence test ID/file/case mismatch: SC2")
    data = copy.deepcopy(original)
    data["evidence"]["SC2"]["test"] = data["evidence"]["SC1"]["test"]
    add("wrong-case", data, "evidence test ID/file/case mismatch: SC2")
    data = copy.deepcopy(original)
    data["evidence"]["SC2"]["assertions"] = ["assert_eq(@json.parse(text), expected)"]
    add("helper-anchor", data, "assertion anchor changed: SC2")
    data = copy.deepcopy(original)
    data["evidence"]["SC2"]["assertions"] = ["(ordering_array([function]), @moonjsonnet.Type, None)"]
    add("other-case-anchor", data, "assertion anchor changed: SC2")
    test_path = Path(original["evidence"]["SC1"]["file"])
    test_source = (root / test_path).read_text()
    repeated = test_source + '\n///|\ntest "' + original["evidence"]["SC1"]["test"] + '" {\n}\n'
    add("duplicate-case-declaration", original, "unique test declaration for SC1", (test_path, repeated))
    data = copy.deepcopy(original)
    item = data["evidence"]["SC2"]
    item["file"] = "./" + item["file"]
    item["test_id"] = item["file"] + "::" + item["test"]
    add("noncanonical-file", data, "canonical relative test path required: SC2")
    data = copy.deepcopy(original)
    data["version"] = 1
    add("old-schema", data, "mapping schema v2 required")

    if "greater-or-equal-true" in original["rules"]:
        def sign_review(data):
            return data["rules"]["greater-or-equal-true"]["rule_review"]

        data = copy.deepcopy(original)
        row = copy.deepcopy(data["rules"]["greater-or-equal-true"])
        row["rule_review"]["rule"] = "greater-than-true"
        data["rules"]["greater-than-true"] = row
        add("sign-foreign-rule", data, "comparison-sign completion restricted to six reviewed rules")
        data = copy.deepcopy(original)
        sign_review(data)["fixed_statement"] += " UNREVIEWED"
        add("sign-formula", data, "reviewed comparison-sign statement mismatch")
        data = copy.deepcopy(original)
        sign_review(data)["operator"] = ">"
        add("sign-operator", data, "comparison-sign operator")
        data = copy.deepcopy(original)
        sign_review(data)["accepted_signs"] = [1]
        add("sign-accepted-signs", data, "comparison-sign accepted signs")
        data = copy.deepcopy(original)
        sign_review(data)["result"] = False
        add("sign-result", data, "comparison-sign result")
        data = copy.deepcopy(original)
        sign_review(data)["comparison_domain"] = [-1, 0, 1, 2]
        add("sign-domain", data, "comparison-sign domain")
        data = copy.deepcopy(original)
        sign_review(data)["operand_roles"] = ["right", "left"]
        add("sign-order", data, "comparison-sign operand order")
        data = copy.deepcopy(original)
        sign_review(data)["child_judgments_assumed"] = ""
        add("sign-child", data, "comparison-sign child assumptions required")
        data = copy.deepcopy(original)
        sign_review(data)["excluded_obligations"] = [item for item in sign_review(data)["excluded_obligations"] if not item.startswith("Whole operand")]
        add("sign-exclusion", data, "comparison-sign must exclude Whole operand")
        data = copy.deepcopy(original)
        sign_review(data)["inspection"][0]["sha256"] = "0" * 64
        add("sign-snapshot", data, "inspected implementation changed: operators.mbt")

    if "not-true" in original["rules"]:
        def negation_review(data):
            return data["rules"]["not-true"]["rule_review"]

        data = copy.deepcopy(original)
        row = copy.deepcopy(data["rules"]["not-true"])
        row["rule_review"]["rule"] = "boolean-and-shortcut"
        data["rules"]["boolean-and-shortcut"] = row
        add("neg-foreign-rule", data, "Boolean negation completion restricted to two reviewed rules")
        data = copy.deepcopy(original)
        negation_review(data)["fixed_statement"] += " UNREVIEWED"
        add("neg-formula", data, "reviewed Boolean negation statement mismatch")
        data = copy.deepcopy(original)
        negation_review(data)["operator"] = "+"
        add("neg-operator", data, "Boolean negation operator")
        data = copy.deepcopy(original)
        negation_review(data)["operand_domains"] = ["Number"]
        add("neg-domain", data, "Boolean negation domain")
        data = copy.deepcopy(original)
        negation_review(data)["operand_value"] = False
        add("neg-operand", data, "Boolean negation operand")
        data = copy.deepcopy(original)
        negation_review(data)["result"] = True
        add("neg-result", data, "Boolean negation result")
        data = copy.deepcopy(original)
        negation_review(data)["demand_policy"] = "manifest"
        add("neg-demand", data, "Boolean negation demand policy")
        data = copy.deepcopy(original)
        negation_review(data)["child_judgments_assumed"] = ""
        add("neg-child", data, "Boolean negation child assumptions required")
        data = copy.deepcopy(original)
        negation_review(data)["excluded_obligations"] = [item for item in negation_review(data)["excluded_obligations"] if not item.startswith("Whole operand")]
        add("neg-exclusion", data, "Boolean negation must exclude Whole operand")
        data = copy.deepcopy(original)
        negation_review(data)["inspection"][0]["sha256"] = "0" * 64
        add("neg-snapshot", data, "inspected implementation changed: eval.mbt")

    if "chk-array-index" in original["rules"]:
        data = copy.deepcopy(original)
        row = copy.deepcopy(data["rules"]["chk-array-index"])
        row["rule_review"]["rule"] = "chk-lit"
        data["rules"]["chk-lit"] = row
        add("pair-foreign-rule", data, "static pair completion restricted to index and binary")
        data = copy.deepcopy(original)
        data["rules"]["chk-array-index"]["rule_review"]["fixed_statement"] += " UNREVIEWED"
        add("pair-formula", data, "reviewed transfer statement mismatch")
        data = copy.deepcopy(original)
        data["rules"]["chk-array-index"]["rule_review"]["premise_roles"] = ["index", "target"]
        add("pair-roles", data, "transfer premise roles")
        data = copy.deepcopy(original)
        data["rules"]["chk-binary"]["rule_review"]["child_judgments_assumed"] = ""
        add("pair-child", data, "transfer child assumptions required")

    cases = [case for case in cases if case[0].startswith(args.case_prefix)]
    assert cases, "no metadata cases match the selected prefix"

    env = os.environ.copy()
    env["RUST_LOG"] = "error"
    results = json.loads((output / "negative-results.json").read_text()) if resume else []
    if resume:
        assert [item["case"] for item in results] == [item[0] for item in cases]
        assert all(item["passed"] and item["no_output"] for item in results)
    generated = [mirror / "docs/development/SPEC-LANGUAGE-MATRIX.md", mirror / "docs/development/spec-language-matrix.json"]
    for name, text, marker, source_change in ([] if resume else cases):
        (mirror / mapping_path).write_text(text)
        if source_change:
            (mirror / source_change[0]).write_text(source_change[1])
        destination = output / name
        assert not destination.exists() and not any(path.exists() for path in generated)
        argv = ["nice", "-n", "10", "moon", "run", "--frozen", "-j", "1", "tools/spec-language-matrix.mbtx", str(reference), str(destination)]
        started = time.monotonic()
        proc = subprocess.run(argv, cwd=mirror, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
        log = output / (name + ".log")
        log.write_text(proc.stdout)
        no_output = not destination.exists() and not any(path.exists() for path in generated)
        passed = proc.returncode != 0 and marker in proc.stdout and no_output
        record = {"case": name, "argv": argv, "exit": proc.returncode, "expected_marker": marker, "marker_found": marker in proc.stdout, "no_output": no_output, "passed": passed, "seconds": round(time.monotonic() - started, 3), "log_sha256": sha(log)}
        results.append(record)
        (output / "negative-results.json").write_text(json.dumps(results, indent=2) + "\n")
        if source_change:
            (mirror / source_change[0]).write_text(test_source)
        print(json.dumps({"case": name, "exit": proc.returncode, "passed": passed}), flush=True)
        if not passed:
            raise AssertionError("wrong rejection path: " + name + "\n" + proc.stdout[-3500:])

    (mirror / mapping_path).write_text(original_text)
    destination = output / ("positive-recovered" if resume else "positive")
    assert not destination.exists(), "inspect previous positive outcome before retry"
    argv = ["nice", "-n", "10", "moon", "run", "--frozen", "-j", "1", "tools/spec-language-matrix.mbtx", str(reference), str(destination)]
    started = time.monotonic()
    proc = subprocess.run(argv, cwd=root, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
    log = output / ("positive-recovered.log" if resume else "positive.log")
    log.write_text(proc.stdout)
    assert proc.returncode == 0, proc.stdout[-3500:]
    matrix = json.loads((destination / "matrix.json").read_text(), object_pairs_hook=unique_object)
    for index in range(1, 6):
        assert matrix["evidence"]["PREC" + str(index)]["file"] == "spec_precedence_test.mbt"
    for index in range(1, 4):
        assert matrix["evidence"]["SP" + str(index)]["file"] == "spec_super_prefix_test.mbt"
    ids = [item["test_id"] for item in matrix["evidence"].values()]
    assert len(ids) == len(set(ids)) == matrix["global_test_ids"]
    assert all(item["test_id"] == item["file"] + "::" + item["test"] for item in matrix["evidence"].values())
    for path, digest in identities.items():
        assert sha(root / path) == digest, "real input changed: " + path
    record = {"argv": argv, "cwd": str(root), "exit": proc.returncode, "seconds": round(time.monotonic() - started, 3), "log_sha256": sha(log), "negative_controls": len(results), "case_prefix": args.case_prefix, "all_rejected_before_output": all(item["passed"] for item in results), "positive_bindings_verified": True, "global_test_ids": len(ids), "real_inputs_unchanged": True, "reused_negative_results": resume}
    (output / "result.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(record), flush=True)


if __name__ == "__main__":
    main()
