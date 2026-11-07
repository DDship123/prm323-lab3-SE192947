from e2e_test.runner import _checker_failures, parse_verdict


def test_dict_output_with_verdict():
    assert parse_verdict({"verdict": "PASS", "evidence": "x"})["verdict"] == "PASS"


def test_fenced_json_inside_report_prose():
    output = 'Báo cáo...\n```json\n{"verdict": "FAIL", "evidence": "e", "failed_step": "s"}\n```'
    verdict = parse_verdict(output)
    assert verdict["verdict"] == "FAIL"
    assert verdict["failed_step"] == "s"


def test_string_result_wrapped_with_test_summary():
    output = {"result": '{"verdict": "PASS"}', "test_summary": {"failed": 0}}
    assert parse_verdict(output)["verdict"] == "PASS"


def test_plain_prose_fallback():
    assert parse_verdict("Verdict: pass, all good")["verdict"] == "PASS"


def test_missing_output_has_no_verdict():
    assert parse_verdict(None) == {}


def test_checker_failures_prefers_run_outcome():
    checks = {"run_outcome": {"tests": {"passed": 1, "failed": 2}}}
    assert _checker_failures(checks, None) == 2
    assert _checker_failures(None, {"test_summary": {"failed": 1}}) == 1
    assert _checker_failures(None, "text") == 0
