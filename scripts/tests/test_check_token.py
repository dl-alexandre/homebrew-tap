#!/usr/bin/env python3
"""Exercise check-token.py against a local fake of the GitHub REST API."""
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "check-token.py"
REPO = "dl-alexandre/homebrew-tap"
SECRET = "ghp_TESTSECRETVALUE0123456789abcdef"
BUILTIN = "builtin-workflow-token"


class FakeGitHub(BaseHTTPRequestHandler):
    """Minimal GitHub: /repos/<repo> probe plus issues and comments."""

    def log_message(self, *args):
        pass

    def _send(self, status, payload=None, headers=None):
        body = json.dumps(payload).encode() if payload is not None else b""
        self.send_response(status)
        for key, value in (headers or {}).items():
            self.send_header(key, value)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        length = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(length)) if length else None

    def _record(self, body=None):
        state = self.server.state
        state["calls"].append((self.command, self.path, self.headers.get("Authorization"), body))
        return state

    def do_GET(self):
        state = self._record()
        path = self.path.split("?")[0]
        if path == f"/repos/{REPO}":
            if self.headers.get("Authorization") != "Bearer " + SECRET:
                return self._send(401, {"message": "Bad credentials"})
            probe = state["probe"]
            return self._send(probe["status"], {"message": probe.get("message", "")}
                              if probe["status"] != 200 else {"full_name": REPO},
                              probe.get("headers"))
        if path == f"/repos/{REPO}/issues":
            open_issues = [i for i in state["issues"] if i["state"] == "open"]
            return self._send(200, open_issues)
        self._send(404, {"message": "Not Found"})

    def do_POST(self):
        body = self._body()
        state = self._record(body)
        path = self.path
        if path == f"/repos/{REPO}/issues":
            issue = dict(number=200 + len(state["issues"]), state="open", **body)
            state["issues"].append(issue)
            return self._send(201, issue)
        if path.startswith(f"/repos/{REPO}/issues/") and path.endswith("/comments"):
            state["comments"].append((int(path.split("/")[-2]), body["body"]))
            return self._send(201, {"id": 1})
        self._send(404, {"message": "Not Found"})

    def do_PATCH(self):
        body = self._body()
        state = self._record(body)
        number = int(self.path.rsplit("/", 1)[1])
        for issue in state["issues"]:
            if issue["number"] == number:
                issue.update(body)
                return self._send(200, issue)
        self._send(404, {"message": "Not Found"})


def expiry_header(days):
    when = datetime.now(timezone.utc) + timedelta(days=days)
    return {"GitHub-Authentication-Token-Expiration": when.strftime("%Y-%m-%d %H:%M:%S UTC")}


class CheckTokenTest(unittest.TestCase):
    def setUp(self):
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), FakeGitHub)
        self.server.state = {"probe": {"status": 200}, "issues": [], "comments": [], "calls": []}
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.summary = Path(self.temp.name) / "summary.md"
        self.output = Path(self.temp.name) / "output.txt"

    @property
    def state(self):
        return self.server.state

    def run_check(self, *args, token=SECRET, gh_token=BUILTIN):
        env = {k: v for k, v in os.environ.items() if not k.startswith("GITHUB_")}
        env.update(GITHUB_API_URL=f"http://127.0.0.1:{self.server.server_address[1]}",
                   GITHUB_REPOSITORY=REPO, GITHUB_REPOSITORY_OWNER="dl-alexandre",
                   GITHUB_RUN_ID="42", GITHUB_WORKFLOW="Update Formulas",
                   GITHUB_STEP_SUMMARY=str(self.summary), GITHUB_OUTPUT=str(self.output),
                   GITHUB_TOKEN=gh_token, TAP_TOKEN=token)
        result = subprocess.run([sys.executable, str(SCRIPT), *args], env=env, text=True,
                                capture_output=True, timeout=60)
        everything = result.stdout + result.stderr + self.summary.read_text() \
            if self.summary.exists() else result.stdout + result.stderr
        self.assertNotIn(SECRET, everything)
        self.assertNotIn(SECRET[4:12], everything)
        return result

    def outputs(self):
        return dict(line.split("=", 1) for line in self.output.read_text().splitlines())

    def test_missing_token_fails_without_calling_github(self):
        result = self.run_check(token="")
        self.assertEqual(result.returncode, 1)
        self.assertIn("::error title=TAP_TOKEN preflight failed (missing)::", result.stdout)
        self.assertEqual(self.outputs()["status"], "missing")
        self.assertEqual(self.state["calls"], [])

    def test_rejected_token_fails_with_one_actionable_error(self):
        result = self.run_check(token="ghp_wrong")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout.count("::error"), 1)
        self.assertIn("HTTP 401 (Bad credentials)", result.stdout)
        self.assertIn("update the TAP_TOKEN secret", result.stdout)
        self.assertIn("`invalid`", self.summary.read_text())

    def test_token_is_sent_only_as_bearer_header(self):
        self.run_check()
        method, path, auth, _ = self.state["calls"][0]
        self.assertEqual((method, path, auth), ("GET", f"/repos/{REPO}", "Bearer " + SECRET))

    def test_token_without_expiry_header_is_ok(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("::warning", result.stdout)
        self.assertIn("no expiration date", result.stdout)
        self.assertEqual(self.outputs(), {"status": "ok", "expires_at": "", "days_left": ""})

    def test_distant_expiry_is_ok(self):
        self.state["probe"]["headers"] = expiry_header(90)
        result = self.run_check()
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("::warning", result.stdout)
        self.assertEqual(self.outputs()["status"], "ok")
        self.assertIn(self.outputs()["days_left"], ("89", "90"))

    def test_near_expiry_warns_but_passes(self):
        self.state["probe"]["headers"] = expiry_header(5)
        result = self.run_check()
        self.assertEqual(result.returncode, 0)
        self.assertIn("::warning title=TAP_TOKEN expires soon::", result.stdout)
        self.assertEqual(self.outputs()["status"], "expiring")
        self.assertIn("⚠️", self.summary.read_text())

    def test_warn_days_threshold_is_configurable(self):
        self.state["probe"]["headers"] = expiry_header(20)
        self.assertNotIn("::warning", self.run_check().stdout)
        self.assertIn("::warning", self.run_check("--warn-days", "30").stdout)

    def test_numeric_offset_expiry_format_is_parsed(self):
        when = datetime.now(timezone(timedelta(hours=-8))) + timedelta(days=3)
        self.state["probe"]["headers"] = {
            "GitHub-Authentication-Token-Expiration": when.strftime("%Y-%m-%d %H:%M:%S %z")}
        result = self.run_check()
        self.assertEqual(self.outputs()["status"], "expiring", result.stdout)

    def test_unparseable_expiry_does_not_fail(self):
        self.state["probe"]["headers"] = {"GitHub-Authentication-Token-Expiration": "soon"}
        result = self.run_check()
        self.assertEqual(result.returncode, 0)
        self.assertIn("could not be parsed", result.stdout)

    def test_token_without_repo_access_fails(self):
        self.state["probe"] = {"status": 404, "message": "Not Found"}
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.outputs()["status"], "no-access")

    def test_unreachable_api_is_an_error(self):
        port = self.server.server_address[1]
        self.server.shutdown()
        self.server.server_close()
        env = dict(os.environ, GITHUB_API_URL=f"http://127.0.0.1:{port}", TAP_TOKEN=SECRET,
                   GITHUB_REPOSITORY=REPO)
        env.pop("GITHUB_STEP_SUMMARY", None)
        env.pop("GITHUB_OUTPUT", None)
        result = subprocess.run([sys.executable, str(SCRIPT)], env=env, text=True,
                                capture_output=True, timeout=60)
        self.assertEqual(result.returncode, 1)
        self.assertIn("preflight failed (error)", result.stdout)
        self.assertNotIn(SECRET, result.stdout + result.stderr)

    # Tracking issue -------------------------------------------------------------------

    def test_bad_token_opens_one_issue_with_builtin_token(self):
        result = self.run_check("--report-issue", token="ghp_wrong")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(self.state["issues"]), 1)
        issue = self.state["issues"][0]
        self.assertIn("<!-- token-preflight:TAP_TOKEN -->", issue["body"])
        self.assertEqual(issue["assignees"], ["dl-alexandre"])
        self.assertIn("/actions/runs/42", issue["body"])
        issue_calls = [c for c in self.state["calls"] if "/issues" in c[1]]
        self.assertTrue(all(c[2] == "Bearer " + BUILTIN for c in issue_calls))
        self.assertIn("opened tracking issue #200", result.stdout)

    def test_repeated_failures_update_the_same_issue_without_new_comments(self):
        self.run_check("--report-issue", token="ghp_wrong")
        self.run_check("--report-issue", token="ghp_wrong")
        result = self.run_check("--report-issue", token="ghp_wrong")
        self.assertEqual(len(self.state["issues"]), 1)
        self.assertEqual(self.state["comments"], [])
        self.assertIn("updated tracking issue #200", result.stdout)

    def test_status_change_comments_on_existing_issue(self):
        self.state["probe"]["headers"] = expiry_header(3)
        self.run_check("--report-issue")
        self.run_check("--report-issue", token="ghp_wrong")
        self.assertEqual(len(self.state["issues"]), 1)
        self.assertEqual(len(self.state["comments"]), 1)
        self.assertIn("`invalid`", self.state["comments"][0][1])
        self.assertIn("token-preflight-status:invalid", self.state["issues"][0]["body"])

    def test_healthy_token_closes_tracking_issue(self):
        self.run_check("--report-issue", token="")
        result = self.run_check("--report-issue")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.state["issues"][0]["state"], "closed")
        self.assertIn("Closing", self.state["comments"][-1][1])

    def test_unrelated_issues_are_never_touched(self):
        self.state["issues"].append(dict(number=104, state="open", title="ci: renew TAP_TOKEN",
                                         body="Human-written issue about the token."))
        self.run_check("--report-issue", token="ghp_wrong")
        self.run_check("--report-issue")
        human = self.state["issues"][0]
        self.assertEqual((human["state"], human["body"]),
                         ("open", "Human-written issue about the token."))
        touched = [c for c in self.state["calls"] if "/issues/104" in c[1]]
        self.assertEqual(touched, [])

    def test_healthy_token_without_issue_makes_no_writes(self):
        self.run_check("--report-issue")
        self.assertEqual([c for c in self.state["calls"] if c[0] != "GET"], [])

    def test_transient_error_leaves_issue_alone(self):
        self.state["probe"] = {"status": 502, "message": "Bad Gateway"}
        result = self.run_check("--report-issue")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.state["issues"], [])
        self.assertIn("untouched", result.stdout)

    def test_issue_failure_does_not_mask_token_result(self):
        result = self.run_check("--report-issue", token="ghp_wrong", gh_token="")
        self.assertEqual(result.returncode, 1)
        self.assertIn("preflight failed (invalid)", result.stdout)
        self.assertIn("::warning title=TAP_TOKEN tracking issue not updated::", result.stdout)


if __name__ == "__main__":
    unittest.main()
