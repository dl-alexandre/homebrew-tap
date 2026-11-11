#!/usr/bin/env python3
"""Exercise health reports with isolated repositories and mocked GitHub responses."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPTS = Path(__file__).resolve().parents[1]


class HealthChecksTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        for name in ("check-ci-health.sh", "check-releases.sh", "refresh-dependencies.sh"):
            shutil.copy2(SCRIPTS / name, self.root / "scripts" / name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "remote", "add", "origin",
                        "git@github.com:dl-alexandre/homebrew-tap.git"], check=True)
        (self.root / ".gitmodules").write_text(
            '[submodule "tool"]\n\tpath = Tools/tool\n'
            '\turl = https://github.com/dl-alexandre/tool.git\n')
        self.bin = self.root / "bin"
        self.bin.mkdir()
        gh = self.bin / "gh"
        gh.write_text('''#!/usr/bin/env python3
import json, os, sys
repo = sys.argv[sys.argv.index("--repo") + 1]
data = json.loads(os.environ["GH_RESPONSES"]).get(repo, [])
if data == "error":
    print("HTTP 401: Bad credentials", file=sys.stderr)
    sys.exit(1)
print(json.dumps(data))
''')
        gh.chmod(0o755)

    def run_check(self, name, responses):
        env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                   GH_RESPONSES=json.dumps(responses))
        return subprocess.run(["bash", str(self.root / "scripts" / name)],
                              env=env, text=True, capture_output=True)

    def test_parent_workflow_failure_is_included(self):
        result = self.run_check("check-ci-health.sh", {
            "dl-alexandre/homebrew-tap": [self.workflow_run("failure")]})
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("homebrew-tap", result.stdout)
        self.assertIn("https://github.com/example/run/1", result.stdout)

    def test_ci_lookup_failure_is_not_reported_as_clean(self):
        result = self.run_check("check-ci-health.sh", {"dl-alexandre/tool": "error"})
        self.assertEqual(result.returncode, 1)
        self.assertIn("unable to fetch workflow runs", result.stderr)
        self.assertNotIn("No failures detected", result.stdout)

    def test_timeout_is_an_actionable_failure(self):
        result = self.run_check("check-ci-health.sh", {
            "dl-alexandre/tool": [self.workflow_run("timed_out")]})
        self.assertEqual(result.returncode, 1)
        self.assertIn("timed_out", result.stdout)

    def test_new_success_supersedes_historical_failure(self):
        old = self.workflow_run("failure")
        old["createdAt"] = "2026-11-08T00:00:00Z"
        result = self.run_check("check-ci-health.sh", {
            "dl-alexandre/tool": [old, self.workflow_run("success")]})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_release_lookup_failure_is_not_no_releases(self):
        result = self.run_check("check-releases.sh", {"dl-alexandre/tool": "error"})
        self.assertEqual(result.returncode, 1)
        self.assertIn("unable to fetch releases", result.stderr)
        self.assertNotIn("no releases", result.stdout)

    def test_empty_release_list_is_valid(self):
        result = self.run_check("check-releases.sh", {})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("no releases", result.stdout)

    def test_dependency_failure_stops_that_module_and_checks_the_next(self):
        normalizer = self.root / "scripts" / "normalize-go-workflows.sh"
        normalizer.write_text("#!/usr/bin/env bash\nexit 0\n")
        normalizer.chmod(0o755)
        for name in ("bad", "good"):
            directory = self.root / name
            directory.mkdir()
            (directory / "go.mod").write_text("module example.com/" + name + "\n")
        go = self.bin / "go"
        go.write_text('''#!/usr/bin/env bash
printf '%s %s\\n' "${PWD##*/}" "$*" >> "$GO_CALLS"
if [[ "$PWD" == */bad && "$1" == "get" ]]; then exit 42; fi
''')
        go.chmod(0o755)
        calls = self.root / "go-calls"
        env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                   GO_CALLS=str(calls))
        result = subprocess.run(["bash", str(self.root / "scripts/refresh-dependencies.sh")],
                                env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertEqual(calls.read_text().splitlines(), [
            "bad get -u -t ./...", "good get -u -t ./...",
            "good mod tidy", "good test ./..."])

    @staticmethod
    def workflow_run(conclusion):
        return dict(workflowName="CI", status="completed", conclusion=conclusion,
                    event="push", createdAt="2026-11-09T00:00:00Z", headBranch="master",
                    url="https://github.com/example/run/1")


if __name__ == "__main__":
    unittest.main()
