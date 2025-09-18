#!/usr/bin/env python3
"""
Fetch multiple Google Sheet tabs (by gid) as CSV using a service account,
normalize them into one JSON snapshot for Terraform.

Env vars required:
  GOOGLE_CREDENTIALS   = JSON string of the service account key (or path; see below)
  SHEET_ID             = The spreadsheet ID
  TAB_REPOS_GID        = gid for each tab below...
  TAB_MEMBERS_GID
  TAB_TEAMS_GID
  TAB_TEAM_MEMBERS_GID
  TAB_BRANCHES_GID
  TAB_USER_PERMS_GID
  TAB_TEAM_PERMS_GID
  TAB_ADMINS_GID
  TAB_CODEOWNERS_GID

Optional:
  OUT_PATH             = where to write the snapshot (default: data/snapshot.json)

Requires: google-auth, requests
"""

import os
import io
import csv
import json
import requests
from typing import List, Dict
from google.oauth2 import service_account
import google.auth.transport.requests


# ---- Config ----
SHEET_ID = os.environ["SHEET_ID"]
OUT_PATH = os.environ.get("OUT_PATH", "data/snapshot.json")

TAB_ENV = {
    "repos":            "TAB_REPOS_GID",
    "members":          "TAB_MEMBERS_GID",
    "teams":            "TAB_TEAMS_GID",
    "team_members":     "TAB_TEAM_MEMBERS_GID",
    "branches":         "TAB_BRANCHES_GID",
    "user_permissions": "TAB_USER_PERMS_GID",
    "team_permissions": "TAB_TEAM_PERMS_GID",
    "administrators":   "TAB_ADMINS_GID",
    "codeowners_rules": "TAB_CODEOWNERS_GID",
}

# ---- Auth (Google service account) ----
def _load_credentials() -> service_account.Credentials:
    raw = os.environ.get("GOOGLE_CREDENTIALS")
    if not raw:
        raise RuntimeError("GOOGLE_CREDENTIALS env var is required")

    # Allow either raw JSON or a path to a JSON file
    if raw.strip().startswith("{"):
        info = json.loads(raw)
    else:
        with open(raw, "r", encoding="utf-8") as f:
            info = json.load(f)

    creds = service_account.Credentials.from_service_account_info(
        info,
        scopes=[
            "https://www.googleapis.com/auth/spreadsheets.readonly",
            "https://www.googleapis.com/auth/drive.readonly"
        ],
    )
    creds.refresh(google.auth.transport.requests.Request())
    return creds


def _fetch_csv_as_dicts(token: str, gid: str) -> List[Dict[str, str]]:
    url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/export?format=csv&gid={gid}"
    r = requests.get(url, headers={"Authorization": f"Bearer {token}"}, timeout=60)
    r.raise_for_status()

    # Parse CSV safely (handles commas/quotes/newlines)
    text = r.content.decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    rows = []
    for raw in reader:
        # Normalize: trim keys/values, drop empty rows
        row = { (k or "").strip(): (v or "").strip() for k, v in raw.items() }
        if any(v for v in row.values()):
            rows.append(row)
    return rows


def main():
    creds = _load_credentials()
    token = creds.token

    snapshot = {}
    missing = []
    for name, env_key in TAB_ENV.items():
        gid = os.environ.get(env_key)
        if not gid:
            missing.append(env_key)
            continue
        snapshot[name] = _fetch_csv_as_dicts(token, gid)

    if missing:
        raise RuntimeError(f"Missing required tab gid env vars: {', '.join(missing)}")

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2, sort_keys=True)
    print(f"Wrote snapshot to {OUT_PATH} (keys: {', '.join(snapshot.keys())})")


if __name__ == "__main__":
    main()
