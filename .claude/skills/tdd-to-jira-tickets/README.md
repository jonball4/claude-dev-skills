# TDD to Jira Tickets Skill - Setup Guide

## Overview
This skill automates the creation of Jira tickets and dependency links from TDD (Technical Design Document) CSV exports.

## Prerequisites
- Python 3.8 or higher
- pip (Python package manager)
- Jira account with API access
- Jira API token

## Installation

### 1. Install Python Dependencies

From the skill directory:
```bash
cd .claude/skills/tdd-to-jira-tickets
pip install -r requirements.txt
```

Or install globally:
```bash
pip install requests==2.32.3
```

### 2. Set Up Jira Credentials

The script requires two environment variables:

#### Option A: Export in your shell session
```bash
export JIRA_EMAIL="your.email@yourorg.com"
export JIRA_TOKEN="your_jira_api_token"
```

#### Option B: Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
```bash
# Add these lines to your shell profile
export JIRA_EMAIL="your.email@yourorg.com"
export JIRA_TOKEN="your_jira_api_token"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

#### Option C: Use a .env file (requires python-dotenv)
Create a `.env` file in the skill directory:
```
JIRA_EMAIL=your.email@yourorg.com
JIRA_TOKEN=your_jira_api_token
```

Install python-dotenv:
```bash
pip install python-dotenv
```

### 3. Get Your Jira API Token

1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Click "Create API token"
3. Give it a name (e.g., "Claude TDD Automation")
4. Copy the token (you won't be able to see it again)
5. Use this token as your `JIRA_TOKEN` environment variable

## Usage

### Automated Mode (Recommended)
Use the Claude Code skill which handles the entire workflow:
```bash
/tdd-to-jira-tickets path/to/your/tdd-export.csv
```

### Manual Mode
Run the Python script directly:
```bash
python create_jira_tickets_and_links.py path/to/your/tdd-export.csv
```

### What the Script Does
1. **Phase 1**: Reads the CSV file
2. **Phase 2**: Creates Jira tickets via REST API and updates CSV with Jira keys
3. **Phase 3**: Creates dependency links between tickets

### CSV Format Requirements
The CSV must have these columns:
- `Key` - Logical key for the ticket (e.g., M1-DB-1)
- `Summary` - Ticket title
- `Description` - Ticket description (supports markdown)
- `Issue Type` - Epic, Story, Task, Bug, etc.
- `Parent` - Parent Epic key (e.g., PX-9000)
- `Labels` - Pipe-separated labels (e.g., "settlement|milestone-1")
- `Priority` - Low, Medium, High, Highest
- `Story Points` - Numeric value
- `Blocks` - Pipe-separated logical keys this ticket blocks
- `Is Blocked By` - Pipe-separated logical keys that block this ticket

### Features
- ✅ Skips tickets that already have Jira keys (idempotent)
- ✅ Converts markdown to Atlassian Document Format (ADF)
- ✅ Updates CSV with created Jira keys
- ✅ Creates dependency links automatically
- ✅ Deduplicates links
- ✅ Comprehensive error handling

## Troubleshooting

### "JIRA_EMAIL environment variable is not set"
Make sure you've exported the environment variables in your current shell session.

### "HTTP 401 Unauthorized"
- Check that your JIRA_TOKEN is correct
- Verify your JIRA_EMAIL matches your Atlassian account
- Make sure your API token hasn't expired

### "HTTP 400 Bad Request"
- Verify the parent Epic key exists
- Check that the Issue Type is valid for your project
- Ensure Priority values match your Jira configuration

### "HTTP 404 Not Found"
- The parent Epic or linked issue doesn't exist
- Check the project key in the Parent column

## Development

### Running Tests
```bash
# Install test dependencies
pip install pytest

# Run tests (when available)
pytest
```

### Adding New Features
The main script is [create_jira_tickets_and_links.py](create_jira_tickets_and_links.py).

Key functions:
- `markdown_to_adf()` - Converts markdown to Atlassian Document Format
- `create_jira_ticket()` - Creates a single ticket via REST API
- `create_jira_link()` - Creates a dependency link via REST API

## Security Notes
- Never commit your JIRA_TOKEN to version control
- Use environment variables or secure credential storage
- API tokens should be rotated periodically
- Consider using Atlassian's IP allowlisting for additional security

## Support
For issues or questions:
1. Check the troubleshooting section above
2. Review Jira REST API docs: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
3. Check Claude Code skill documentation
