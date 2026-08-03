#!/usr/bin/env python3
"""
Nyaya-Agent :: eCourts Cause List fetcher

Uses the real `ecourts` PyPI package (openjustice-in/ecourts,
https://openjustice-in.github.io/ecourts/) to fetch published Cause Lists
for a configured set of courts and push them to Supabase.

Confidence note: unlike the OpenNyAI script, this one was written against
the library's ACTUAL installed source code (inspected directly - ecourt.py,
entities/cause_list.py, entities/court.py, cli/__init__.py all read to
confirm the real API), not just documentation. The package installs
cleanly on Python 3.12. What could NOT be verified: an actual live call
against hcservices.ecourts.gov.in's real servers - that domain isn't
reachable from the sandbox this was built in, and government portals are
prone to change without notice. The CAPTCHA-solving mechanism itself
(OpenCV + Tesseract) is the library's own long-standing, published,
cited approach - not something written for this project.

Requires the `tesseract-ocr` system binary (installed via apt-get in the
GitHub Actions workflow) - the ecourts library's Captcha.decaptcha() shells
out to it directly.
"""

import datetime
import json
import sys

import requests

SUPABASE_URL = "https://qojdhatypfuakhkkedar.supabase.co"
SUPABASE_ANON_KEY = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R"

# Seed list of courts to fetch cause lists for. (state_code, court_code, label)
# court_code=None means the court's principal/main bench.
# Full list of covered courts: https://raw.githubusercontent.com/openjustice-in/ecourts/main/courts.csv
# Note: several major High Courts (Delhi, Punjab & Haryana, Madhya Pradesh)
# are NOT in this list - they run separate portals outside
# hcservices.ecourts.gov.in, which is all this library covers.
COURTS = [
    ("3", None, "High Court of Karnataka - Principal Bench at Bengaluru"),
    ("4", None, "High Court of Kerala"),
    ("10", None, "Madras High Court - Principal Bench"),
]


def fetch_cause_lists_for_court(state_code, court_code, label, target_date):
    from ecourt import ECourt, RetryException
    from entities import Court

    court = Court(state_code=state_code, court_code=court_code)
    ecourt = ECourt(court)
    ecourt.set_max_attempts(15)

    try:
        return list(ecourt.getCauseLists(target_date))
    except RetryException as e:
        print(f"  RetryException for {label}: {e} (likely CAPTCHA-solving ran out of attempts, or the portal is down)")
        return []
    except Exception as e:
        print(f"  ERROR for {label}: {e}")
        return []


def upsert_cause_list(row):
    resp = requests.post(
        f"{SUPABASE_URL}/rest/v1/cause_lists?on_conflict=state_code,court_code,cause_list_date,causelist_id",
        headers={
            "Content-Type": "application/json",
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
            "Prefer": "resolution=ignore-duplicates",
        },
        data=json.dumps([row]),
        timeout=20,
    )
    return resp.ok, (resp.text if not resp.ok else "")


def main():
    target_date = datetime.date.today()
    print(f"Fetching cause lists for {target_date.isoformat()} across {len(COURTS)} court(s)...")

    total_ok, total_fail = 0, 0
    for state_code, court_code, label in COURTS:
        print(f"\n{label} (state_code={state_code}, court_code={court_code}):")
        cause_lists = fetch_cause_lists_for_court(state_code, court_code, label, target_date)
        print(f"  Found {len(cause_lists)} cause list entr{'y' if len(cause_lists)==1 else 'ies'}.")

        for cl in cause_lists:
            row = {
                "state_code": state_code,
                "court_code": court_code,
                "court_name": label,
                "cause_list_date": cl.date.isoformat(),
                "bench": cl.bench,
                "list_type": cl.type,
                "causelist_id": cl.causelist_id,
                "document_url": cl.url(),
                "video_conferencing": cl.video_conferencing,
            }
            ok, err = upsert_cause_list(row)
            if ok:
                total_ok += 1
            else:
                total_fail += 1
                print(f"  FAILED to save: {err[:200]}")

    print(f"\nDone. Saved {total_ok}, failed {total_fail}.")
    if total_ok == 0 and total_fail == 0:
        print("No cause lists found for any configured court today - this can be normal (weekends/holidays), or may indicate the portal/library needs attention.")


if __name__ == "__main__":
    main()
