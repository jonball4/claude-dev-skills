import csv
import json
import os
import requests
from requests.auth import HTTPBasicAuth

# Mapping of logical keys to Jira keys
# UPDATE THIS MAPPING based on Phase 2 results (logical key -> actual Jira key)
mapping = {
    "M1-DB-1": "PX-9433",
    "M1-BL-1": "PX-9434",
    "M1-BL-2-CU": "PX-9435",
    "M1-BL-2-AR": "PX-9436",
    "M1-BL-2-ARCH": "PX-9437",
    "M1-API-1": "PX-9438",
    "M1-API-2": "PX-9439",
    "M1-API-3": "PX-9440",
    "M1-API-4": "PX-9441",
    "M1-API-5": "PX-9442",
    "M1-API-6": "PX-9443",
    "M1-API-7": "PX-9444",
    "M1-API-8": "PX-9445",
    "M1-API-9": "PX-9446",
    "M1-TEST-1": "PX-9447",
    "M1-TEST-2": "PX-9448",
    "M1-TEST-3": "PX-9449",
    "M1-DOC-1": "PX-9450",
    "M1-MON-1": "PX-9451"
}

# UPDATE THIS PATH to point to your CSV file
csv_file = "/Users/${whoami}/Dev/trade-services/lp-settlement-milestone-1-jira-tickets.csv"

# Jira configuration - uses environment variables for authentication
JIRA_BASE_URL = os.environ.get('JIRA_BASE_URL')
JIRA_EMAIL = os.environ.get('JIRA_EMAIL')
JIRA_TOKEN = os.environ.get('JIRA_TOKEN')

# Verify environment variables
if not JIRA_EMAIL or not JIRA_TOKEN or not JIRA_BASE_URL:
    print("❌ Error: JIRA_EMAIL, JIRA_TOKEN, or JIRA_BASE_URL environment variable is not set")
    exit(1)

# Read CSV
with open(csv_file, 'r', newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

links_to_create = []

# Extract dependencies from CSV
for row in rows:
    logical_key = row['Key']
    jira_key = mapping.get(logical_key)

    if not jira_key:
        continue

    # Process "Blocks" column (this ticket blocks others)
    blocks = row.get('Blocks', '').strip()
    if blocks:
        blocked_keys = [k.strip() for k in blocks.split('|') if k.strip()]
        for blocked_logical in blocked_keys:
            blocked_jira = mapping.get(blocked_logical)
            if blocked_jira:
                links_to_create.append({
                    'blocker_logical': logical_key,
                    'blocker_jira': jira_key,
                    'blocked_logical': blocked_logical,
                    'blocked_jira': blocked_jira
                })

    # Process "Is Blocked By" column (this ticket is blocked by others)
    is_blocked_by = row.get('Is Blocked By', '').strip()
    if is_blocked_by:
        blocker_keys = [k.strip() for k in is_blocked_by.split('|') if k.strip()]
        for blocker_logical in blocker_keys:
            blocker_jira = mapping.get(blocker_logical)
            if blocker_jira:
                links_to_create.append({
                    'blocker_logical': blocker_logical,
                    'blocker_jira': blocker_jira,
                    'blocked_logical': logical_key,
                    'blocked_jira': jira_key
                })

# Deduplicate links
unique_links = {}
for link in links_to_create:
    key = (link['blocker_jira'], link['blocked_jira'])
    if key not in unique_links:
        unique_links[key] = link

print(f"Found {len(unique_links)} unique dependency links to create")
print()

# Create links via curl
success_count = 0
skip_count = 0
error_count = 0

for (blocker, blocked), link in unique_links.items():
    print(f"Creating link: {link['blocker_logical']} ({link['blocker_jira']}) BLOCKS {link['blocked_logical']} ({link['blocked_jira']})")

    url = f"{JIRA_BASE_URL}/rest/api/3/issueLink"
    headers = {"Content-Type": "application/json"}
    auth = HTTPBasicAuth(JIRA_EMAIL, JIRA_TOKEN)
    payload = {
        "type": {"name": "Blocks"},
        "inwardIssue": {"key": link['blocker_jira']},
        "outwardIssue": {"key": link['blocked_jira']}
    }

    try:
        response = requests.post(url, json=payload, headers=headers, auth=auth)

        if response.status_code == 201:
            print(f"  ✓ Created successfully")
            success_count += 1
        elif response.status_code in (400, 404):
            print(f"  ⚠ Skipped (ticket may not exist): HTTP {response.status_code}")
            skip_count += 1
        else:
            print(f"  ✗ Failed: HTTP {response.status_code}")
            if response.text:
                print(f"    Response: {response.text[:200]}")
            error_count += 1
    except requests.RequestException as e:
        print(f"  ✗ Request failed: {str(e)}")
        error_count += 1
    print()

print(f"\nSummary:")
print(f"  Success: {success_count}")
print(f"  Skipped: {skip_count}")
print(f"  Errors: {error_count}")
print(f"  Total: {len(unique_links)}")
