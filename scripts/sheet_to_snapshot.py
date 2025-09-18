# requirements: google-api-python-client google-auth google-auth-httplib2
import os, json
from typing import Dict, List
import google.auth
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"

SHEET_ID = os.environ["SHEET_ID"]
OUT_PATH = os.environ.get("OUT_PATH", "data/snapshot.json")

# Use TAB NAMES (no gid). Set these envs in your workflow, or hardcode them.
TAB_NAMES = {
    "repos":            os.environ["TAB_REPOS_GID"],
    "members":          os.environ["TAB_MEMBERS_GID"],
    "teams":            os.environ["TAB_TEAMS_GID"],
    "team_members":     os.environ["TAB_TEAM_MEMBERS_GID"],
    "branches":         os.environ["TAB_BRANCHES_GID"],
    "user_permissions": os.environ["TAB_USER_PERMISSIONS_GID"],
    "team_permissions": os.environ["TAB_TEAM_PERMISSIONS_GID"],
    "administrators":   os.environ["TAB_ADMINS_GID"],
    "codeowners_rules": os.environ["TAB_CODEOWNERS_GID"],
}

def get_service():
    creds, _ = google.auth.default(scopes=[SCOPE])
    if not creds.valid:
        creds.refresh(Request())
    return build("sheets", "v4", credentials=creds, cache_discovery=False)

def normalize(headers: List[str], rows: List[List[str]]):
    heads = [(h or "").strip().lower() for h in headers]
    out = []
    for r in rows:
        obj = {heads[i]: (r[i].strip() if i < len(r) and r[i] is not None else "")
               for i in range(len(heads))}
        if any(v for v in obj.values()):
            out.append(obj)
    return out

def main():
    svc = get_service()
    ranges = list(TAB_NAMES.values())                       # e.g. ["Repos","Members",...]
    resp = svc.spreadsheets().values().batchGet(
        spreadsheetId=SHEET_ID,
        ranges=ranges,
        valueRenderOption="FORMATTED_VALUE",
        dateTimeRenderOption="FORMATTED_STRING",
        majorDimension="ROWS",
    ).execute()

    # Map each returned valueRange to our keys
    by_range = {vr["range"].split("!")[0].strip("'"): vr.get("values", []) for vr in resp.get("valueRanges", [])}

    snapshot: Dict[str, list] = {}
    for key, tab in TAB_NAMES.items():
        values = by_range.get(tab, [])
        if not values:
            snapshot[key] = []
            continue
        headers, *rows = values
        snapshot[key] = normalize(headers, rows)

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2, sort_keys=True)
    print(f"Wrote {OUT_PATH} with keys: {', '.join(snapshot.keys())}")

if __name__ == "__main__":
    main()