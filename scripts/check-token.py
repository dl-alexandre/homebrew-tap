#!/usr/bin/env python3
"""check-token.py — Preflight the GitHub App token before scheduled workflows run.

The token is a GitHub App installation token minted for this run by
actions/create-github-app-token from the TAP_APP_CLIENT_ID (or TAP_APP_ID) variable and
the TAP_APP_PRIVATE_KEY secret. It is minted fresh on every run and never needs renewing.

Makes one authenticated REST call (GET /repos/<repo>) with the token and reports:
  ok        the token works and can read the repo
  invalid   no app token could be minted (APP_TOKEN is empty),
            or GitHub rejected it (401)                        (exit 1)
  no-access token authenticates but cannot read the repo       (exit 1)
  error     GitHub could not be reached or answered 5xx        (exit 1)

With --report-issue, GITHUB_TOKEN (the built-in workflow token, which keeps working
when the app token cannot be minted) is used to open or update one tracking issue,
identified by a hidden marker, when the token needs attention, and to close it once the
token is healthy again. Transient "error" results never touch the issue.

The token value is only ever sent in the Authorization header; it is never printed.

Environment:
  APP_TOKEN           the minted GitHub App installation token (empty if the mint failed)
  GITHUB_REPOSITORY   owner/name to probe and to file the issue in (or --repo)
  GITHUB_API_URL      API base URL (default https://api.github.com)
  GITHUB_TOKEN        token used for --report-issue
  GITHUB_STEP_SUMMARY, GITHUB_OUTPUT, GITHUB_SERVER_URL, GITHUB_RUN_ID,
  GITHUB_WORKFLOW, GITHUB_REPOSITORY_OWNER   standard Actions variables (optional)
"""
import argparse
from datetime import datetime, timezone
import json
import os
import sys
import urllib.error
import urllib.request

# Kept byte-for-byte from the PAT era so tracking issues opened then are still found.
MARKER = "<!-- token-preflight:TAP_TOKEN -->"
STATUS_MARKER = "<!-- token-preflight-status:{} -->"
ISSUE_TITLE = "Automation token needs attention: scheduled automation is at risk"
NEEDS_ATTENTION = ("invalid", "no-access")
LABEL = "the GitHub App token"
HINT = ("Check the TAP_APP_CLIENT_ID (or TAP_APP_ID) variable and TAP_APP_PRIVATE_KEY secret under "
        "Settings > Secrets and variables > Actions, and that the GitHub App is "
        "installed on this tap and every fleet repository.")


def api(method, url, token, body=None, timeout=30):
    """Return (status, headers, parsed_json_or_None). Never raises on HTTP errors."""
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    req.add_header("User-Agent", "homebrew-tap-token-preflight")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            status, headers, raw = resp.status, resp.headers, resp.read()
    except urllib.error.HTTPError as err:
        status, headers, raw = err.code, err.headers, err.read()
    try:
        payload = json.loads(raw) if raw else None
    except ValueError:
        payload = None
    return status, headers, payload


def check(token, api_url, repo):
    """Return a dict describing the token's state."""
    result = {"status": "ok", "detail": ""}
    if not token:
        result.update(status="invalid", detail=(
            "No GitHub App installation token could be minted for this run (see the "
            "'Mint GitHub App token' step for the reason)."))
        return result
    try:
        status, _, payload = api("GET", f"{api_url}/repos/{repo}", token)
    except (urllib.error.URLError, OSError) as err:
        result.update(status="error", detail=f"Could not reach GitHub to verify {LABEL}: {err}")
        return result

    message = payload.get("message", "") if isinstance(payload, dict) else ""
    if status == 401:
        result.update(status="invalid", detail=(
            f"GitHub rejected {LABEL} with HTTP 401 ({message or 'Bad credentials'}). "
            "The app may have been suspended or uninstalled."))
        return result
    if status in (403, 404):
        result.update(status="no-access", detail=(
            f"The GitHub App token authenticated but cannot read {repo} (HTTP {status}"
            f"{': ' + message if message else ''}). Install the GitHub App on it."))
        return result
    if status != 200:
        result.update(status="error", detail=f"Unexpected HTTP {status} while verifying {LABEL}"
                                             f"{': ' + message if message else ''}.")
        return result

    # Installation tokens live for an hour and are re-minted every run: nothing to renew.
    result["detail"] = "The GitHub App token was minted for this run and can read the tap."
    return result


def run_url():
    server = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    repo, run_id = os.environ.get("GITHUB_REPOSITORY"), os.environ.get("GITHUB_RUN_ID")
    return f"{server}/{repo}/actions/runs/{run_id}" if repo and run_id else ""


def find_issue(api_url, repo, gh_token):
    page = 1
    while True:
        status, _, issues = api("GET", f"{api_url}/repos/{repo}/issues?state=open&per_page=100"
                                       f"&page={page}", gh_token)
        if status != 200:
            raise RuntimeError(f"listing issues returned HTTP {status}")
        for issue in issues or []:
            if "pull_request" not in issue and MARKER in (issue.get("body") or ""):
                return issue
        if not issues or len(issues) < 100:
            return None
        page += 1


def report_issue(result, api_url, repo, gh_token):
    """Open/update/close the tracking issue. Returns a short description of the action."""
    if result["status"] == "error":
        return "left tracking issue untouched (transient error)"
    issue = find_issue(api_url, repo, gh_token)
    link = run_url()
    workflow = os.environ.get("GITHUB_WORKFLOW", "a scheduled workflow")

    if result["status"] not in NEEDS_ATTENTION:
        if not issue:
            return "no tracking issue open"
        number = issue["number"]
        api("POST", f"{api_url}/repos/{repo}/issues/{number}/comments", gh_token,
            {"body": f"Token preflight (app) passed in {workflow}"
                     f"{' ([run](' + link + '))' if link else ''}: {result['detail']} Closing."})
        status, _, _ = api("PATCH", f"{api_url}/repos/{repo}/issues/{number}", gh_token,
                           {"state": "closed", "state_reason": "completed"})
        if status != 200:
            raise RuntimeError(f"closing issue #{number} returned HTTP {status}")
        return f"closed tracking issue #{number}"

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    body = "\n".join([
        MARKER, STATUS_MARKER.format(result["status"]), "",
        f"**Status:** `{result['status']}`", "",
        result["detail"], "",
        HINT, "",
        f"Last checked: {now} by {workflow}" + (f" ([run]({link}))" if link else "") + ".", "",
        "This issue is maintained by `scripts/check-token.py`: it is updated in place on each "
        "scheduled run and closed automatically once the token passes the preflight again.",
    ])
    if issue:
        number = issue["number"]
        previous = STATUS_MARKER.format(result["status"]) in (issue.get("body") or "")
        status, _, _ = api("PATCH", f"{api_url}/repos/{repo}/issues/{number}", gh_token,
                           {"body": body})
        if status != 200:
            raise RuntimeError(f"updating issue #{number} returned HTTP {status}")
        if not previous:
            # Only comment (and so notify) when the status changes, not every night.
            api("POST", f"{api_url}/repos/{repo}/issues/{number}/comments", gh_token,
                {"body": f"Status changed to `{result['status']}`: {result['detail']}"})
            return f"updated tracking issue #{number} (status changed)"
        return f"updated tracking issue #{number}"

    payload = {"title": ISSUE_TITLE, "body": body}
    owner = os.environ.get("GITHUB_REPOSITORY_OWNER")
    if owner:
        payload["assignees"] = [owner]
    status, _, created = api("POST", f"{api_url}/repos/{repo}/issues", gh_token, payload)
    if status == 422 and "assignees" in payload:
        del payload["assignees"]
        status, _, created = api("POST", f"{api_url}/repos/{repo}/issues", gh_token, payload)
    if status != 201:
        raise RuntimeError(f"creating issue returned HTTP {status}")
    return f"opened tracking issue #{created['number']}"


def append(path_var, text):
    path = os.environ.get(path_var)
    if path:
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(text)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY",
                                                         "dl-alexandre/homebrew-tap"))
    parser.add_argument("--report-issue", action="store_true",
                        help="open/update/close a tracking issue using GITHUB_TOKEN")
    args = parser.parse_args(argv)
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com").rstrip("/")

    result = check(os.environ.get("APP_TOKEN", ""), api_url, args.repo)
    failed = result["status"] != "ok"

    if failed:
        print(f"::error title=Token preflight failed (app: {result['status']})::"
              f"{result['detail']} {HINT}")
    else:
        print(result["detail"])

    issue_note = ""
    if args.report_issue:
        gh_token = os.environ.get("GITHUB_TOKEN", "")
        try:
            if not gh_token:
                raise RuntimeError("GITHUB_TOKEN is not set")
            issue_note = report_issue(result, api_url, args.repo, gh_token)
            print(f"Tracking issue: {issue_note}")
        except (RuntimeError, urllib.error.URLError, OSError, KeyError, TypeError) as err:
            issue_note = f"could not update tracking issue: {err}"
            print(f"::warning title=Token tracking issue not updated::{err}")

    icon = "❌" if failed else "✅"
    summary = [f"### {icon} Token preflight (app): `{result['status']}`", "", result["detail"]]
    if failed:
        summary += ["", HINT]
    if issue_note:
        summary += ["", f"Tracking issue: {issue_note}"]
    append("GITHUB_STEP_SUMMARY", "\n".join(summary) + "\n")
    append("GITHUB_OUTPUT", f"status={result['status']}\n")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
