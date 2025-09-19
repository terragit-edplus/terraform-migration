# requirements: google-api-python-client google-auth google-auth-httplib2
import os
import io
import json
from typing import Dict, List

from google.oauth2 import service_account
from googleapiclient.discovery import build
from google.auth.transport.requests import Request

SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"

SHEET_ID = os.environ["SHEET_ID"]
OUT_PATH = os.environ.get("OUT_PATH", "data/snapshot.json")
HEADER_LOWERCASE = os.environ.get("HEADER_LOWERCASE", "true").lower() in ("1", "true", "yes")

# Use TAB NAMES (no gid). Set these envs in your workflow, or hardcode them.
TAB_NAMES = {
    "repos":            os.environ["TAB_REPOS"],
    "members":          os.environ["TAB_MEMBERS"],
    "teams":            os.environ["TAB_TEAMS"],
    "team_members":     os.environ["TAB_TEAM_MEMBERS"],
    "branches":         os.environ["TAB_BRANCHES"],
    "user_permissions": os.environ["TAB_USER_PERMISSIONS"],
    "team_permissions": os.environ["TAB_TEAM_PERMISSIONS"],
    "administrators":   os.environ["TAB_ADMINS"],
    "codeowners_rules": os.environ["TAB_CODEOWNERS"],
}

def load_service_account_credentials():
    raw = os.environ.get("GOOGLE_CREDENTIALS")
    if not raw:
        raise RuntimeError("GOOGLE_CREDENTIALS is required (JSON content or a path to the JSON key file).")

    if raw.strip().startswith("{"):
        info = json.loads(raw)
    else:
        with open(raw, "r", encoding="utf-8") as f:
            info = json.load(f)

    creds = service_account.Credentials.from_service_account_info(info, scopes=[SCOPE])
    # Refresh to ensure an access token is present
    creds.refresh(Request())
    return creds


def get_sheets_service():
    creds = load_service_account_credentials()
    # cache_discovery=False avoids cache warnings on ephemeral runners
    return build("sheets", "v4", credentials=creds, cache_discovery=False)


def normalize(headers: List[str], rows: List[List[str]]) -> List[Dict[str, str]]:
    # Clean header cells
    heads = [(h or "").strip() for h in headers]
    if HEADER_LOWERCASE:
        heads = [h.lower() for h in heads]

    out: List[Dict[str, str]] = []
    width = len(heads)
    for r in rows:
        # Pad row to header width to avoid index errors
        padded = list(r) + [""] * max(0, width - len(r))
        obj = {heads[i]: (padded[i].strip() if padded[i] is not None else "") for i in range(width)}
        if any(v for v in obj.values()):
            out.append(obj)
    return out


def main():
    # Build Sheets API client
    svc = get_sheets_service()

    # Fetch all tabs in one call
    ranges = list(TAB_NAMES.values())  # e.g., ["Repos","Members",...]
    resp = svc.spreadsheets().values().batchGet(
        spreadsheetId=SHEET_ID,
        ranges=ranges,
        valueRenderOption="FORMATTED_VALUE",
        dateTimeRenderOption="FORMATTED_STRING",
        majorDimension="ROWS",
    ).execute()

    # Map returned valueRanges by sheet/tab name (strip quotes like 'Sheet Name')
    by_tab: Dict[str, List[List[str]]] = {}
    for vr in resp.get("valueRanges", []):
        full_range = vr.get("range", "")
        tab_name = full_range.split("!", 1)[0].strip("'")
        by_tab[tab_name] = vr.get("values", [])

    # Build the snapshot object keyed by our logical names
    snapshot: Dict[str, List[Dict[str, str]]] = {}
    for key, tab in TAB_NAMES.items():
        values = by_tab.get(tab, [])
        if not values:
            snapshot[key] = []
            continue
        headers, *rows = values
        snapshot[key] = normalize(headers, rows)

    # Write snapshot
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, indent=2, sort_keys=True)

    print(f"Wrote {OUT_PATH} with keys: {', '.join(snapshot.keys())}")


if __name__ == "__main__":
    main()