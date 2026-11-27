#!/usr/bin/env python3
"""check-token.py — Preflight the automation token before scheduled workflows run.

The token is either a GitHub App installation token minted for this run by
actions/create-github-app-token (TOKEN_SOURCE=app, the default once the
TAP_APP_CLIENT_ID variable is set) or the legacy TAP_TOKEN personal access token
(TOKEN_SOURCE=pat). App tokens are minted fresh each run and never need renewing, so
the expiry handling below only applies to the PAT fallback.

Makes one authenticated REST call (GET /repos/<repo>) with the token and reports:
  ok        token works and has no expiry, or expires after the warning window
  expiring  token works but expires within --warn-days (warning only, exit 0)
  missing   the TAP_TOKEN secret is empty or not set           (exit 1)
  invalid   GitHub rejected the token (401: expired/revoked),
            or no app token could be minted                    (exit 1)
  no-access token authenticates but cannot read the repo       (exit 1)
  error     GitHub could not be reached or answered 5xx        (exit 1)

For a PAT, the expiry comes from the GitHub-Authentication-Token-Expiration response
header, which GitHub sends for personal access tokens that have an expiration date.
Tokens without an expiry simply do not send it.

With --report-issue, GITHUB_TOKEN (the built-in workflow token, which keeps working
when the PAT is dead) is used to open or update one tracking issue, identified by a
hidden marker, when the token needs attention, and to close it once the token is
healthy again. Transient "error" results never touch the issue.

The token value is only ever sent in the Authorization header; it is never printed.

Environment:
  TAP_TOKEN           the token to check: the minted app token or the PAT
  TOKEN_SOURCE        "app" or "pat" (default "pat"; or --source)
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

MARKER = "<!-- token-preflight:TAP_TOKEN -->"
STATUS_MARKER = "<!-- token-preflight-status:{} -->"
ISSUE_TITLE = "Automation token needs attention: scheduled automation is at risk"
NEEDS_ATTENTION = ("missing", "invalid", "no-access", "expiring")
SOURCES = {
    "app": {
        "label": "the GitHub App token",
        "hint": ("Check the TAP_APP_CLIENT_ID variable and TAP_APP_PRIVATE_KEY secret under "
                 "Settings > Secrets and variables > Actions, and that the GitHub App is "
                 "installed on this tap and every fleet repository."),
    },
    "pat": {
        "label": "TAP_TOKEN",
        "hint": ("Create a new token with access to the tap and every fleet repository, then "
                 "update the TAP_TOKEN secret under Settings > Secrets and variables > Actions. "
                 "Better: set up the GitHub App (see README) so there is nothing to renew."),
    },
}


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


def parse_expiry(value):
    """Parse e.g. '2026-12-01 00:00:00 UTC' or '2026-12-01 00:00:00 -0800'."""
    text = value.strip()
    if text.endswith(" UTC"):
        text = text[:-4] + " +0000"
    for fmt in ("%Y-%m-%d %H:%M:%S %z", "%Y-%m-%dT%H:%M:%S%z"):
        try:
            return datetime.strptime(text, fmt)
        except ValueError:
            pass
    return None


def check(token, api_url, repo, warn_days, now, source="pat"):
    """Return a dict describing the token's state."""
    result = {"status": "ok", "expires_at": "", "days_left": "", "detail": ""}
    label = SOURCES[source]["label"]
    if not token:
        if source == "app":
            result.update(status="invalid", detail=(
                "No GitHub App installation token could be minted for this run (see the "
                "'Mint GitHub App token' step for the reason)."))
        else:
            result.update(status="missing", detail="The TAP_TOKEN secret is empty or not set.")
        return result
    try:
        status, headers, payload = api("GET", f"{api_url}/repos/{repo}", token)
    except (urllib.error.URLError, OSError) as err:
        result.update(status="error", detail=f"Could not reach GitHub to verify {label}: {err}")
        return result

    message = payload.get("message", "") if isinstance(payload, dict) else ""
    if status == 401:
        cause = ("The app may have been suspended or uninstalled." if source == "app" else
                 "The token has expired, been revoked, or been replaced.")
        result.update(status="invalid", detail=(
            f"GitHub rejected {label} with HTTP 401 ({message or 'Bad credentials'}). {cause}"))
        return result
    if status in (403, 404):
        fix = ("Install the GitHub App on it." if source == "app" else
               "Check its repository access and scopes.")
        result.update(status="no-access", detail=(
            f"{label[0].upper() + label[1:]} authenticated but cannot read {repo} (HTTP {status}"
            f"{': ' + message if message else ''}). {fix}"))
        return result
    if status != 200:
        result.update(status="error", detail=f"Unexpected HTTP {status} while verifying {label}"
                                             f"{': ' + message if message else ''}.")
        return result

    if source == "app":
        # Installation tokens live for an hour and are re-minted every run: nothing to renew.
        result["detail"] = "The GitHub App token was minted for this run and can read the tap."
        return result
    raw_expiry = headers.get("GitHub-Authentication-Token-Expiration")
    if not raw_expiry:
        result["detail"] = "TAP_TOKEN is valid and GitHub reports no expiration date."
        return result
    expires = parse_expiry(raw_expiry)
    if expires is None:
        result["detail"] = (f"TAP_TOKEN is valid but its expiration header could not be parsed "
                            f"({raw_expiry!r}).")
        return result
    days_left = (expires - now).total_seconds() / 86400
    result["expires_at"] = expires.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    result["days_left"] = str(max(int(days_left), 0))
    if days_left <= warn_days:
        result.update(status="expiring", detail=(
            f"TAP_TOKEN expires on {result['expires_at']} (in {result['days_left']} day(s)). "
            "Renew it before then or every scheduled workflow will fail."))
    else:
        result["detail"] = (f"TAP_TOKEN is valid and expires on {result['expires_at']} "
                            f"(in {result['days_left']} days).")
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


def report_issue(result, api_url, repo, gh_token, source="pat"):
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
            {"body": f"Token preflight ({source}) passed in {workflow}"
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
        SOURCES[source]["hint"], "",
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
    parser.add_argument("--warn-days", type=int, default=14,
                        help="warn when the token expires within this many days (default 14)")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY",
                                                         "dl-alexandre/homebrew-tap"))
    parser.add_argument("--report-issue", action="store_true",
                        help="open/update/close a tracking issue using GITHUB_TOKEN")
    parser.add_argument("--source", choices=sorted(SOURCES),
                        default=os.environ.get("TOKEN_SOURCE") or "pat",
                        help="where the token came from: a GitHub App or the TAP_TOKEN PAT")
    args = parser.parse_args(argv)
    api_url = os.environ.get("GITHUB_API_URL", "https://api.github.com").rstrip("/")
    hint = SOURCES[args.source]["hint"]

    result = check(os.environ.get("TAP_TOKEN", ""), api_url, args.repo, args.warn_days,
                   datetime.now(timezone.utc), args.source)
    failed = result["status"] not in ("ok", "expiring")

    if failed:
        print(f"::error title=Token preflight failed ({args.source}: {result['status']})::"
              f"{result['detail']} {hint}")
    elif result["status"] == "expiring":
        print(f"::warning title=TAP_TOKEN expires soon::{result['detail']}")
    else:
        print(result["detail"])

    issue_note = ""
    if args.report_issue:
        gh_token = os.environ.get("GITHUB_TOKEN", "")
        try:
            if not gh_token:
                raise RuntimeError("GITHUB_TOKEN is not set")
            issue_note = report_issue(result, api_url, args.repo, gh_token, args.source)
            print(f"Tracking issue: {issue_note}")
        except (RuntimeError, urllib.error.URLError, OSError, KeyError, TypeError) as err:
            issue_note = f"could not update tracking issue: {err}"
            print(f"::warning title=Token tracking issue not updated::{err}")

    icon = {"ok": "✅", "expiring": "⚠️"}.get(result["status"], "❌")
    summary = [f"### {icon} Token preflight ({args.source}): `{result['status']}`", "",
               result["detail"]]
    if failed or result["status"] == "expiring":
        summary += ["", hint]
    if issue_note:
        summary += ["", f"Tracking issue: {issue_note}"]
    append("GITHUB_STEP_SUMMARY", "\n".join(summary) + "\n")
    append("GITHUB_OUTPUT", "".join(f"{k}={result[k]}\n"
                                    for k in ("status", "expires_at", "days_left")))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
