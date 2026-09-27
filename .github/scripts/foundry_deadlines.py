"""Open one GitHub issue per foundryR deadline whose reminder window has opened.

Reads .github/foundry-deadlines.yml. Set DRY_RUN=1 to print what would be
filed without calling GitHub, and TODAY=YYYY-MM-DD to test another date.
"""

import datetime as dt
import json
import os
import subprocess

import yaml

LABEL = "foundry-deadline"
MARKER = "foundry-deadline-id:"


def gh(*args, stdin=None):
    result = subprocess.run(
        ["gh", *args], check=True, capture_output=True, text=True, input=stdin
    )
    return result.stdout


def as_date(value):
    return value if isinstance(value, dt.date) else dt.date.fromisoformat(str(value))


def filed_ids():
    issues = json.loads(
        gh("issue", "list", "--label", LABEL, "--state", "all",
           "--limit", "500", "--json", "body")
    )
    ids = set()
    for issue in issues:
        for line in (issue.get("body") or "").splitlines():
            if line.startswith(MARKER):
                ids.add(line[len(MARKER):].strip())
    return ids


def issue_body(entry, due):
    tasks = "\n".join(f"- [ ] {task}" for task in entry["tasks"])
    models = ", ".join(f"`{model}`" for model in entry["models"])
    return (
        f"**Due:** {due.isoformat()}\n"
        f"**Models:** {models}\n\n"
        f"{entry['why']}\n\n"
        f"{tasks}\n\n"
        "Re-check the date first with `az cognitiveservices model list -l eastus2`; "
        "if Microsoft moved it, update `.github/foundry-deadlines.yml`.\n\n"
        f"{MARKER} {entry['id']}\n"
    )


def main():
    today = as_date(os.environ.get("TODAY") or dt.date.today())
    dry_run = os.environ.get("DRY_RUN") == "1"
    with open(".github/foundry-deadlines.yml", encoding="utf-8") as handle:
        deadlines = yaml.safe_load(handle)["deadlines"]

    existing = set()
    if not dry_run:
        gh("label", "create", LABEL, "--color", "D93F0B",
           "--description", "Azure retirement that needs foundryR maintenance",
           "--force")
        existing = filed_ids()
    owner = os.environ.get("GITHUB_REPOSITORY_OWNER", "")

    for entry in deadlines:
        due = as_date(entry["date"])
        opens = due - dt.timedelta(days=int(entry["remind_days"]))
        if today < opens:
            print(f"{entry['id']}: reminder opens {opens.isoformat()}")
            continue
        if entry["id"] in existing:
            print(f"{entry['id']}: issue already filed")
            continue
        title = f"{entry['title']} (due {due.isoformat()})"
        body = issue_body(entry, due)
        if dry_run:
            print(f"{entry['id']}: WOULD FILE '{title}'\n{body}")
            continue
        args = ["issue", "create", "--title", title, "--label", LABEL,
                "--body-file", "-"]
        if owner:
            args += ["--assignee", owner]
        print(f"{entry['id']}: filed {gh(*args, stdin=body).strip()}")


if __name__ == "__main__":
    main()
