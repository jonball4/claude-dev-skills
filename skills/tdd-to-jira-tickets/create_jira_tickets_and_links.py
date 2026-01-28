#!/usr/bin/env python3
"""
Automate Jira ticket creation and dependency linking from markdown.

This script handles all three phases of the tdd-to-jira-tickets skill workflow:
1. Phase 1: Read markdown file with ticket specifications
2. Phase 2: Create tickets in Jira via REST API and capture logical Key → Jira Key mapping
3. Phase 3: Create dependency links in Jira via REST API

Usage:
    python create_jira_tickets_and_links.py <markdown_file>

Requirements:
    - JIRA_BASE_URL environment variable must be set
    - JIRA_EMAIL environment variable must be set
    - JIRA_TOKEN environment variable must be set
    - Markdown file must have structured format with ticket specifications
"""

import json
import os
import sys
import re
import requests
from requests.auth import HTTPBasicAuth
from typing import Dict, List, Optional
from pathlib import Path

try:
    import mistletoe
    from mistletoe import Document
    from mistletoe.block_token import Heading, Paragraph, List as MList, ThematicBreak
    from mistletoe.span_token import RawText, Strong, LineBreak
except ImportError:
    print("❌ Error: mistletoe library is required. Install it with: pip install mistletoe==1.4.0")
    sys.exit(1)


# Jira configuration - uses environment variables for authentication
JIRA_BASE_URL = os.environ.get('JIRA_BASE_URL')
JIRA_EMAIL = os.environ.get('JIRA_EMAIL')
JIRA_TOKEN = os.environ.get('JIRA_TOKEN')

# Configuration file paths
CONFIG_PATHS = [
    Path.home() / '.claude' / 'config.json',
    Path('.claude') / 'config.json',
]

def load_config():
    """Load configuration from config.json, returning defaults if not found."""
    defaults = {
        'jira': {
            'customFields': {
                'storyPoints': 'customfield_10115'  # Default value
            },
            'defaultProjectKey': 'PX'  # Default value
        }
    }

    for config_path in CONFIG_PATHS:
        if config_path.exists():
            try:
                with open(config_path, 'r') as f:
                    loaded_config = json.load(f)
                    # Extract namespaced config
                    if 'claude-dev-skills' in loaded_config:
                        skill_config = loaded_config['claude-dev-skills']
                        # Merge with defaults
                        if 'jira' in skill_config:
                            defaults['jira'].update(skill_config['jira'])
                        print(f"✓ Loaded configuration from {config_path}")
                        return defaults
            except (json.JSONDecodeError, IOError) as e:
                print(f"⚠ Warning: Could not load config from {config_path}: {e}")

    print("⚠ No config file found, using default values")
    return defaults

# Load configuration
CONFIG = load_config()
STORY_POINTS_FIELD = CONFIG['jira']['customFields']['storyPoints']
DEFAULT_PROJECT_KEY = CONFIG['jira']['defaultProjectKey']


def verify_environment():
    """Verify required environment variables are set."""
    if not JIRA_BASE_URL:
        print("❌ Error: JIRA_BASE_URL environment variable is not set")
        sys.exit(1)
    if not JIRA_EMAIL:
        print("❌ Error: JIRA_EMAIL environment variable is not set")
        sys.exit(1)
    if not JIRA_TOKEN:
        print("❌ Error: JIRA_TOKEN environment variable is not set")
        sys.exit(1)
    print("✓ Required environment variables are set")


def read_markdown(markdown_file: str) -> List[Dict[str, str]]:
    """Read markdown file and return list of ticket dictionaries."""
    if not os.path.exists(markdown_file):
        print(f"❌ Error: Markdown file not found: {markdown_file}")
        sys.exit(1)

    with open(markdown_file, 'r', encoding='utf-8') as f:
        content = f.read()

    tickets = parse_markdown_tickets(content)
    print(f"✓ Read {len(tickets)} tickets from markdown")
    return tickets


def extract_text_from_token(token) -> str:
    """Recursively extract plain text from a mistletoe token."""
    if isinstance(token, RawText):
        return token.content
    if hasattr(token, 'children') and token.children is not None:
        return ''.join(extract_text_from_token(child) for child in token.children)
    return ''


def parse_markdown_tickets(content: str) -> List[Dict[str, str]]:
    """Parse markdown content into ticket dictionaries using mistletoe."""
    tickets = []
    doc = Document(content)

    # Pattern: ## KEY: Summary
    ticket_pattern = r'^(M\d+-[A-Z]+-\d+(?:-[A-Z]+)?): (.+?)$'

    i = 0
    while i < len(doc.children):
        token = doc.children[i]

        # Look for level 2 headings that match ticket pattern
        if isinstance(token, Heading) and token.level == 2:
            heading_text = extract_text_from_token(token).strip()
            match = re.match(ticket_pattern, heading_text)

            if match:
                key = match.group(1)
                summary = match.group(2).strip()

                # Initialize ticket dict
                ticket = {
                    'Key': key,
                    'Summary': summary,
                    'Description': '',
                    'Issue Type': '',
                    'Parent': '',
                    'Labels': '',
                    'Priority': '',
                    'Story Points': '',
                    'Blocks': '',
                    'Is Blocked By': '',
                    'Jira Key': ''
                }

                # Parse subsequent paragraphs for metadata
                i += 1
                description_started = False
                description_parts = []

                while i < len(doc.children):
                    current = doc.children[i]

                    # Stop at next ticket (level 2 heading)
                    if isinstance(current, Heading) and current.level == 2:
                        break

                    # Stop at thematic break (---)
                    if isinstance(current, ThematicBreak):
                        break

                    # Check for ### Description or ### Summary heading
                    if isinstance(current, Heading) and current.level == 3:
                        heading_text = extract_text_from_token(current).strip()
                        if heading_text in ('Description', 'Summary'):
                            description_started = True
                            i += 1
                            continue

                    # If description has started, collect all content
                    if description_started:
                        # Convert the token back to markdown for description
                        if isinstance(current, Paragraph):
                            text = extract_text_from_token(current)
                            description_parts.append(text)
                        elif isinstance(current, MList):
                            # Handle lists in description
                            for item in current.children:
                                item_text = extract_text_from_token(item)
                                description_parts.append(f"- {item_text}")
                        elif isinstance(current, Heading):
                            # Sub-headings in description
                            text = extract_text_from_token(current)
                            description_parts.append(f"{'#' * current.level} {text}")
                        i += 1
                        continue

                    # Parse metadata from paragraphs
                    if isinstance(current, Paragraph):
                        # Metadata paragraph has pattern: **Field:** value with line breaks
                        # We need to parse each line separately

                        # Extract lines from paragraph by processing Strong/RawText/LineBreak tokens
                        lines = []
                        current_line = []

                        for child in current.children:
                            if isinstance(child, LineBreak):
                                if current_line:
                                    lines.append(''.join(current_line))
                                    current_line = []
                            elif isinstance(child, Strong):
                                # Strong contains the field name (e.g., "Type:")
                                if child.children:
                                    text = extract_text_from_token(child)
                                    current_line.append(text)
                            elif isinstance(child, RawText):
                                current_line.append(child.content)

                        # Don't forget the last line
                        if current_line:
                            lines.append(''.join(current_line))

                        # Parse each line
                        for line in lines:
                            line = line.strip()
                            if ':' not in line:
                                continue

                            # Split on first colon to get field and value
                            field, _, value = line.partition(':')
                            field = field.strip()
                            value = value.strip()

                            if field == 'Type':
                                ticket['Issue Type'] = value
                            elif field == 'Parent':
                                ticket['Parent'] = value
                            elif field == 'Labels':
                                # Convert comma-separated to pipe-separated
                                ticket['Labels'] = '|'.join([l.strip() for l in value.split(',') if l.strip()])
                            elif field == 'Priority':
                                ticket['Priority'] = value
                            elif field == 'Story Points':
                                ticket['Story Points'] = value
                            elif field == 'Blocks':
                                if value and value.lower() != '(none)':
                                    # Convert comma-separated to pipe-separated
                                    ticket['Blocks'] = '|'.join([b.strip() for b in value.split(',') if b.strip()])
                            elif field == 'Blocked By':
                                if value and value.lower() != '(none)':
                                    # Convert comma-separated to pipe-separated
                                    ticket['Is Blocked By'] = '|'.join([b.strip() for b in value.split(',') if b.strip()])
                            elif field == 'Jira Key':
                                ticket['Jira Key'] = value

                    i += 1

                # Join description parts
                if description_parts:
                    ticket['Description'] = '\n\n'.join(description_parts).strip()

                tickets.append(ticket)
                continue

        i += 1

    return tickets


def markdown_to_adf(markdown_text: str) -> Dict:
    """
    Convert markdown text to Atlassian Document Format (ADF).

    Handles:
    - Headings (## text)
    - Task lists (- [ ] item) - consecutive items grouped together
    - Bullet lists (- item) - consecutive items grouped together
    - Bold text (**text**)
    - Inline code (`code`)
    - Regular paragraphs
    """
    content = []
    lines = markdown_text.split('\n')
    i = 0

    while i < len(lines):
        line = lines[i]

        # Skip empty lines
        if not line.strip():
            i += 1
            continue

        # Handle headings (## text)
        heading_match = re.match(r'^(#{2,6})\s+(.+)$', line)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2)
            content.append({
                "type": "heading",
                "attrs": {"level": level},
                "content": [{"type": "text", "text": text}]
            })
            i += 1
            continue

        # Handle consecutive task list items (- [ ] text or - [x] text)
        # Convert to bullet list since Jira doesn't support taskList in child issues under epics
        task_match = re.match(r'^-\s+\[([x ])\]\s+(.+)$', line)
        if task_match:
            # Collect all consecutive task items as bullet list items
            list_items = []
            while i < len(lines):
                task_match = re.match(r'^-\s+\[([x ])\]\s+(.+)$', lines[i])
                if not task_match:
                    break

                # checked = task_match.group(1).lower() == 'x'  # Not used since we can't render checkboxes
                text = task_match.group(2)
                text_content = parse_inline_formatting(text)

                list_items.append({
                    "type": "listItem",
                    "content": [{
                        "type": "paragraph",
                        "content": text_content
                    }]
                })
                i += 1

            # Add as bulletList (Jira doesn't support taskList in subtasks/child issues)
            content.append({
                "type": "bulletList",
                "content": list_items
            })
            continue

        # Handle consecutive bullet list items (- text, not task lists)
        bullet_match = re.match(r'^-\s+([^\[].*)$', line)  # Not starting with [
        if bullet_match:
            # Collect all consecutive bullet items
            list_items = []
            while i < len(lines):
                bullet_match = re.match(r'^-\s+([^\[].*)$', lines[i])
                if not bullet_match:
                    break

                text = bullet_match.group(1)
                text_content = parse_inline_formatting(text)

                list_items.append({
                    "type": "listItem",
                    "content": [{
                        "type": "paragraph",
                        "content": text_content
                    }]
                })
                i += 1

            # Add the bulletList with all collected items
            content.append({
                "type": "bulletList",
                "content": list_items
            })
            continue

        # Handle regular paragraphs (everything else)
        paragraph_lines = []
        while i < len(lines) and lines[i].strip() and not re.match(r'^(#{2,6}|-)\s+', lines[i]):
            paragraph_lines.append(lines[i])
            i += 1

        if paragraph_lines:
            paragraph_text = ' '.join(paragraph_lines)
            text_content = parse_inline_formatting(paragraph_text)

            content.append({
                "type": "paragraph",
                "content": text_content
            })

    return {
        "type": "doc",
        "version": 1,
        "content": content
    }


def parse_inline_formatting(text: str) -> List[Dict]:
    """Parse inline markdown formatting (bold, code) in text."""
    content = []
    current_pos = 0

    # Pattern matches: **bold**, `code`
    pattern = r'(\*\*(.+?)\*\*|`(.+?)`)'

    for match in re.finditer(pattern, text):
        # Add text before the match
        if match.start() > current_pos:
            plain_text = text[current_pos:match.start()]
            if plain_text:
                content.append({"type": "text", "text": plain_text})

        # Add formatted text
        if match.group(2):  # Bold text
            content.append({
                "type": "text",
                "text": match.group(2),
                "marks": [{"type": "strong"}]
            })
        elif match.group(3):  # Code text
            content.append({
                "type": "text",
                "text": match.group(3),
                "marks": [{"type": "code"}]
            })

        current_pos = match.end()

    # Add remaining text
    if current_pos < len(text):
        remaining_text = text[current_pos:]
        if remaining_text:
            content.append({"type": "text", "text": remaining_text})

    # If no content was added, return plain text
    if not content:
        content.append({"type": "text", "text": text})

    return content


def create_jira_ticket(row: Dict[str, str]) -> Optional[str]:
    """
    Create a single Jira ticket via REST API.

    Returns:
        Jira issue key (e.g., "PX-9453") if successful, None otherwise
    """
    if not JIRA_EMAIL or not JIRA_TOKEN:
        print(f"  ✗ Cannot create ticket: JIRA_EMAIL or JIRA_TOKEN not set")
        return None

    logical_key = row['Key']
    summary = row['Summary']
    description = row['Description']
    issue_type = row['Issue Type']
    parent = row.get('Parent', '').strip()
    labels_str = row.get('Labels', '').strip()
    priority = row.get('Priority', 'Medium').strip()
    story_points = row.get('Story Points', '').strip()

    # Build labels list
    labels = [l.strip() for l in labels_str.split('|') if l.strip()] if labels_str else []

    # Convert markdown description to ADF
    description_adf = markdown_to_adf(description)

    # Build fields object
    fields = {
        "project": {"key": parent.split('-')[0] if parent else DEFAULT_PROJECT_KEY},  # Extract project key from parent or use default
        "summary": summary,
        "description": description_adf,
        "issuetype": {"name": issue_type},
        "labels": labels,
        "priority": {"name": priority}
    }

    # Add parent if specified
    if parent:
        fields["parent"] = {"key": parent}

    # Add story points if specified
    if story_points:
        try:
            fields[STORY_POINTS_FIELD] = float(story_points)
        except ValueError:
            print(f"  ⚠ Warning: Invalid story points value '{story_points}', skipping")

    # Create ticket via requests
    url = f"{JIRA_BASE_URL}/rest/api/3/issue"
    headers = {"Content-Type": "application/json"}
    auth = HTTPBasicAuth(JIRA_EMAIL, JIRA_TOKEN)
    payload = {"fields": fields}

    try:
        response = requests.post(url, json=payload, headers=headers, auth=auth)

        if response.status_code == 201:
            response_json = response.json()
            jira_key = response_json.get('key')
            print(f"  ✓ Created {logical_key} → {jira_key}")
            return jira_key
        else:
            print(f"  ✗ Failed to create {logical_key}: HTTP {response.status_code}")
            if response.text:
                print(f"    Response: {response.text[:200]}")
            return None
    except requests.RequestException as e:
        print(f"  ✗ Request failed for {logical_key}: {str(e)}")
        return None
    except json.JSONDecodeError:
        print(f"  ✗ Failed to parse response for {logical_key}")
        return None


def update_markdown_with_jira_keys(markdown_file: str, mapping: Dict[str, str]):
    """Update markdown file with Jira Key metadata field."""
    with open(markdown_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update each ticket section with Jira Key
    lines = content.split('\n')
    updated_lines = []
    i = 0

    ticket_pattern = r'^## (M\d+-[A-Z]+-\d+(?:-[A-Z]+)?): (.+?)$'

    while i < len(lines):
        line = lines[i]
        match = re.match(ticket_pattern, line)

        if match:
            key = match.group(1)
            jira_key = mapping.get(key, '')

            # Add the heading
            updated_lines.append(line)
            i += 1

            # Check if Jira Key already exists
            jira_key_exists = False
            metadata_lines = []

            # Collect metadata lines
            while i < len(lines):
                current_line = lines[i]

                # Stop at description section or next ticket
                if current_line.strip().startswith('###') or re.match(ticket_pattern, current_line) or current_line.strip() == '---':
                    break

                if current_line.startswith('**Jira Key:**'):
                    jira_key_exists = True
                    if jira_key:
                        metadata_lines.append(f'**Jira Key:** {jira_key}')
                    else:
                        metadata_lines.append(current_line)
                else:
                    metadata_lines.append(current_line)

                i += 1

            # Add Jira Key if it doesn't exist and we have one
            if not jira_key_exists and jira_key:
                # Find the right place to insert (after other metadata)
                insert_index = 0
                for idx, meta_line in enumerate(metadata_lines):
                    if meta_line.strip().startswith('**Blocked By:**'):
                        insert_index = idx + 1
                        break
                    elif meta_line.strip().startswith('**Blocks:**'):
                        insert_index = idx + 1

                if insert_index == 0 and metadata_lines:
                    insert_index = len(metadata_lines)

                metadata_lines.insert(insert_index, f'**Jira Key:** {jira_key}')

            updated_lines.extend(metadata_lines)
        else:
            updated_lines.append(line)
            i += 1

    # Write updated markdown
    with open(markdown_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(updated_lines))

    print(f"✓ Updated markdown with Jira Keys")


def extract_dependencies(rows: List[Dict[str, str]], mapping: Dict[str, str]) -> List[Dict[str, str]]:
    """
    Extract dependency links from CSV rows.

    Returns:
        List of link dictionaries with blocker and blocked keys
    """
    links_to_create = []

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

    return list(unique_links.values())


def create_jira_link(link: Dict[str, str]) -> bool:
    """
    Create a single Jira issue link via REST API.

    Returns:
        True if successful, False otherwise
    """
    if not JIRA_EMAIL or not JIRA_TOKEN:
        print(f"  ✗ Cannot create link: JIRA_EMAIL or JIRA_TOKEN not set")
        return False

    url = f"{JIRA_BASE_URL}/rest/api/3/issueLink"
    headers = {"Content-Type": "application/json"}
    auth = HTTPBasicAuth(JIRA_EMAIL, JIRA_TOKEN)
    payload = {
        "type": {"name": "Blocks"},
        "inwardIssue": {"key": link['blocker_jira']},  # The BLOCKER
        "outwardIssue": {"key": link['blocked_jira']}   # The BLOCKED
    }

    try:
        response = requests.post(url, json=payload, headers=headers, auth=auth)

        if response.status_code == 201:
            print(f"  ✓ Created link: {link['blocker_logical']} ({link['blocker_jira']}) BLOCKS {link['blocked_logical']} ({link['blocked_jira']})")
            return True
        elif response.status_code in (400, 404):
            print(f"  ⚠ Skipped (ticket may not exist): {link['blocker_logical']} → {link['blocked_logical']} (HTTP {response.status_code})")
            return False
        else:
            print(f"  ✗ Failed: {link['blocker_logical']} → {link['blocked_logical']} (HTTP {response.status_code})")
            if response.text:
                print(f"    Response: {response.text[:200]}")
            return False
    except requests.RequestException as e:
        print(f"  ✗ Request failed for {link['blocker_logical']} → {link['blocked_logical']}: {str(e)}")
        return False


def main():
    """Main execution function."""
    if len(sys.argv) != 2:
        print("Usage: python create_jira_tickets_and_links.py <markdown_file>")
        sys.exit(1)

    markdown_file = sys.argv[1]

    print("=" * 80)
    print("Phase 1: Reading Markdown")
    print("=" * 80)
    verify_environment()
    tickets = read_markdown(markdown_file)

    print("\n" + "=" * 80)
    print("Phase 2: Creating Jira Tickets")
    print("=" * 80)

    mapping = {}  # logical Key → Jira Key
    success_count = 0
    error_count = 0

    for ticket in tickets:
        logical_key = ticket['Key']

        # Check if Jira Key already exists
        existing_jira_key = ticket.get('Jira Key', '').strip()
        if existing_jira_key:
            print(f"  ⚠ Skipping {logical_key} (already has Jira Key: {existing_jira_key})")
            mapping[logical_key] = existing_jira_key
            continue

        print(f"Creating {logical_key}: {ticket['Summary']}")
        jira_key = create_jira_ticket(ticket)

        if jira_key:
            mapping[logical_key] = jira_key
            success_count += 1
        else:
            error_count += 1

    print(f"\nTicket Creation Summary:")
    print(f"  Success: {success_count}")
    print(f"  Errors: {error_count}")
    print(f"  Total: {len(tickets)}")

    if mapping:
        print("\n" + "=" * 80)
        print("Updating Markdown with Jira Keys")
        print("=" * 80)
        update_markdown_with_jira_keys(markdown_file, mapping)

    print("\n" + "=" * 80)
    print("Phase 3: Creating Dependency Links")
    print("=" * 80)

    links = extract_dependencies(tickets, mapping)
    print(f"Found {len(links)} unique dependency links to create\n")

    link_success_count = 0
    link_skip_count = 0
    link_error_count = 0

    for link in links:
        success = create_jira_link(link)
        if success:
            link_success_count += 1
        else:
            link_skip_count += 1

    print(f"\nDependency Link Summary:")
    print(f"  Success: {link_success_count}")
    print(f"  Skipped: {link_skip_count}")
    print(f"  Errors: {link_error_count}")
    print(f"  Total: {len(links)}")

    print("\n" + "=" * 80)
    print("Complete!")
    print("=" * 80)


if __name__ == "__main__":
    main()
